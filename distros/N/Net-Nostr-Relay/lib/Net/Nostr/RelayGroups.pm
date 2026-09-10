package Net::Nostr::RelayGroups;

use strictures 2;
use Net::Nostr::_ConstructorArgs ();
use Net::Nostr::Group;
use Net::Nostr::Filter;
use Net::Nostr::Key;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Class::Tiny qw(_key _max_pins);

sub new {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my @unknown = grep { $_ ne 'key' && $_ ne 'max_pins' } keys %args;
    croak 'unknown argument(s): ' . join(', ', sort @unknown) if @unknown;
    croak 'key must be a private Net::Nostr::Key'
        unless blessed($args{key}) && $args{key}->isa('Net::Nostr::Key')
            && eval { length($args{key}->privkey_hex) == 64 };
    croak 'max_pins must be a non-negative integer'
        if exists($args{max_pins}) && (!defined($args{max_pins}) || ref($args{max_pins})
            || $args{max_pins} !~ /\A[0-9]+\z/);
    return bless {_key=>$args{key},_max_pins=>$args{max_pins}}, $class;
}

sub pubkey { $_[0]->_key->pubkey_hex }

sub _state {
    my ($self,$store,$id) = @_;
    my $meta = $store->find_addressable($self->pubkey,39000,$id) or return;
    my $admins = $store->find_addressable($self->pubkey,39001,$id);
    my $members = $store->find_addressable($self->pubkey,39002,$id);
    return {
        meta => Net::Nostr::Group->metadata_from_event($meta),
        admins => {map { $_->{pubkey} => $_->{roles} } @{
            $admins ? Net::Nostr::Group->admins_from_event($admins)->{admins} : []}},
        members => {map { $_ => 1 } @{
            $members ? Net::Nostr::Group->members_from_event($members)->{members} : []}},
    };
}

sub _group_id {
    my ($event,$name) = @_;
    my @tags = grep { $_->[0] eq $name } @{$event->tags};
    return unless @tags;
    croak "invalid: group $name tag must occur once with a non-empty id"
        unless @tags == 1 && @{$tags[0]} == 2 && length($tags[0][1]);
    return $tags[0][1];
}

sub can_read {
    my ($self,$event,$authenticated,$store) = @_;
    croak 'authenticated identities must be a hash reference' unless ref($authenticated) eq 'HASH';
    my $metadata = $event->kind >= 39000 && $event->kind <= 39005;
    my $id = _group_id($event, $metadata ? 'd' : 'h');
    return 1 unless defined $id;
    return 0 if $metadata && $event->pubkey ne $self->pubkey;
    my $state = $self->_state($store,$id) or return 0;
    return 1 unless $state->{meta}{$metadata ? 'hidden' : 'private'};
    return !!grep { $authenticated->{$_} } keys %{$state->{members}};
}

sub _membership_event {
    my ($self, $store, $cause, $id, $target, $remove, $roles) = @_;
    my $history = $store->query([Net::Nostr::Filter->new(kinds=>[9000,9001],
        '#h'=>[$id], '#p'=>[$target])]);
    my $timestamp = time;
    for my $previous ($cause, @$history) {
        $timestamp = $previous->created_at + 1 if $previous->created_at >= $timestamp;
    }
    my $method = $remove ? 'remove_user' : 'put_user';
    my $generated = Net::Nostr::Group->$method(pubkey=>$self->pubkey,group_id=>$id,
        target=>$target,created_at=>$timestamp,reason=>$cause->content,
        ($remove ? () : (roles=>$roles || [])));
    $self->_key->sign_event($generated);
    return $generated;
}

sub prepare {
    my ($self,$event,$store) = @_;
    croak 'event must be a Net::Nostr::Event'
        unless blessed($event) && $event->isa('Net::Nostr::Event');
    $event->validate;
    my $kind = $event->kind;
    croak 'restricted: group metadata is generated through moderation'
        if $kind >= 39000 && $kind <= 39005;
    my $id = _group_id($event,'h');
    my $moderation = $kind >= 9000 && $kind <= 9022;
    croak 'invalid: group action requires an h tag' if $moderation && !defined($id);
    return {events=>[],delete_ids=>[]} unless defined $id;
    croak 'invalid: late group publication' if $event->created_at < time - 3600;
    croak 'invalid: future group publication' if $event->created_at > time + 600;
    for my $tag (@{$event->tags}) {
        next unless $tag->[0] eq 'previous';
        for my $prefix (@$tag[1 .. $#$tag]) {
            croak 'invalid: previous reference must be eight lowercase hex characters'
                unless $prefix =~ /\A[0-9a-f]{8}\z/;
            my $history = $store->query([Net::Nostr::Filter->new]);
            croak 'invalid: previous reference is absent from this relay timeline'
                unless grep { substr($_->id,0,8) eq $prefix && $_->pubkey ne $event->pubkey } @$history;
        }
    }
    my (%states,%touch,%rosters,%pins,@extra,@delete);
    my $load = sub {
        my ($group_id) = @_;
        return $states{$group_id} if exists $states{$group_id};
        return $states{$group_id} = $self->_state($store,$group_id);
    };
    my $state = $load->($id);
    my $author = $event->pubkey;
    if ($kind == 9007) {
        croak 'duplicate: group already exists' if $state;
        $state = $states{$id} = {meta=>{group_id=>$id,restricted=>1},
            admins=>{$author=>['admin']},members=>{$author=>1}};
        $touch{$id} = $rosters{$id} = 1;
        $pins{$id} = [];
        push @extra, $self->_membership_event($store,$event,$id,$author,0,['admin']);
    } else {
        croak 'restricted: group does not exist' unless $state;
        croak 'restricted: group admin required'
            if $kind >= 9000 && $kind <= 9020 && !$state->{admins}{$author};
        if ($kind == 9002) {
            my @tags = map { [@$_] } grep { $_->[0] ne 'h' && $_->[0] ne 'previous' } @{$event->tags};
            my %allowed = map { $_=>1 } qw(name picture about banner parent child private public
                restricted unrestricted hidden visible closed open supported_kinds);
            croak 'restricted: unsupported group metadata field' if grep { !$allowed{$_->[0]} } @tags;
            my %flags;
            for my $tag (@tags) {
                next unless $tag->[0] =~ /\A(?:private|public|restricted|unrestricted|hidden|visible|closed|open)\z/;
                croak 'invalid: metadata flag must occur once without a value'
                    unless @$tag == 1 && !$flags{$tag->[0]}++;
            }
            for my $pair ([qw(private public)], [qw(closed open)], [qw(hidden visible)], [qw(restricted unrestricted)]) {
                croak 'invalid: conflicting metadata flags' if $flags{$pair->[0]} && $flags{$pair->[1]};
            }
            my $edited = Net::Nostr::Group->metadata_from_event(Net::Nostr::Event->new(
                pubkey=>$self->pubkey,kind=>39000,content=>'',tags=>[['d',$id],@tags]));
            my @old_children = @{$state->{meta}{children} || []};
            my @new_children = @{$edited->{children} || []};
            my %children = map { $_ => 1 } @old_children;
            croak 'invalid: child list must contain every current child exactly once'
                unless @old_children == @new_children && !grep { !$children{$_} } @new_children;
            my $parent = $edited->{parent};
            if (defined $parent) {
                my $parent_state = $load->($parent) or croak 'invalid: parent does not exist';
                croak 'restricted: author must also be an admin of the parent' unless $parent_state->{admins}{$author};
                my ($cursor,%seen) = ($parent);
                while (defined $cursor) {
                    croak 'invalid: parent would create a cycle' if $cursor eq $id || $seen{$cursor}++;
                    my $ancestor = $load->($cursor) or croak 'invalid: parent tree is incomplete';
                    $cursor = $ancestor->{meta}{parent};
                }
            }
            my $old_parent = $state->{meta}{parent};
            if (defined($old_parent) && (!defined($parent) || $old_parent ne $parent)) {
                my $previous = $load->($old_parent) or croak 'invalid: previous parent is missing';
                $previous->{meta}{children} = [grep { $_ ne $id } @{$previous->{meta}{children} || []}];
                $touch{$old_parent} = 1;
            }
            if (defined($parent) && (!defined($old_parent) || $parent ne $old_parent)) {
                push @{$load->($parent)->{meta}{children}}, $id;
                $touch{$parent} = 1;
            }
            delete @{$state->{meta}}{qw(parent children)};
            @{$state->{meta}}{keys %$edited} = values %$edited;
            my %opposite = (public=>'private', unrestricted=>'restricted', visible=>'hidden', open=>'closed');
            for my $tag (@tags) { delete $state->{meta}{$opposite{$tag->[0]}} if $opposite{$tag->[0]} }
            $touch{$id} = 1;
        } elsif ($kind == 9010) {
            my $list = Net::Nostr::Group->pins_from_event($event)->{pins};
            croak 'restricted: pin count exceeds max_pins'
                if defined($self->_max_pins) && @$list > $self->_max_pins;
            $pins{$id} = $list;
        } elsif ($kind == 9008) {
            my $parent = $state->{meta}{parent};
            if (defined $parent) {
                my $parent_state = $load->($parent) or croak 'invalid: parent is missing';
                $parent_state->{meta}{children} = [grep { $_ ne $id } @{$parent_state->{meta}{children} || []}];
                $touch{$parent} = 1;
            }
            for my $child (@{$state->{meta}{children} || []}) {
                my $child_state = $load->($child) or croak 'invalid: child is missing';
                delete $child_state->{meta}{parent};
                $touch{$child} = 1;
            }
            push @delete, map { $_->id } @{$store->query([
                Net::Nostr::Filter->new('#h'=>[$id]),
                Net::Nostr::Filter->new(authors=>[$self->pubkey], kinds=>[39000..39005], '#d'=>[$id]),
            ])};
        } elsif ($kind == 9000 || $kind == 9001 || $kind == 9021 || $kind == 9022) {
            my ($target,@roles);
            if ($kind == 9000 || $kind == 9001) {
                my @p = grep { $_->[0] eq 'p' } @{$event->tags};
                croak 'invalid: membership action needs one p tag'
                    unless @p == 1 && @{$p[0]} >= 2 && $p[0][1] =~ /\A[0-9a-f]{64}\z/;
                ($target,@roles) = @{$p[0]}[1 .. $#{$p[0]}];
                croak 'invalid: remove-user p tag must contain only its pubkey' if $kind == 9001 && @roles;
                croak 'invalid: membership roles must be non-empty' if grep { !length($_) } @roles;
            } else {
                $target = $author;
            }
            if ($kind == 9021) {
                croak 'duplicate: already a group member' if $state->{members}{$target};
                my @codes = grep { $_->[0] eq 'code' } @{$event->tags};
                croak 'invalid: join request permits one non-empty code'
                    if @codes > 1 || (@codes && (@{$codes[0]} != 2 || !length($codes[0][1])));
                if ($state->{meta}{closed}) {
                    my $invites = $store->query([Net::Nostr::Filter->new(kinds=>[9009], '#h'=>[$id])]);
                    croak 'restricted: closed group requires a valid invite'
                        unless @codes == 1 && grep {
                            my $inv = $_;
                            grep { $_->[0] eq 'code' && $_->[1] eq $codes[0][1] } @{$inv->tags}
                        } @$invites;
                }
            }
            if ($kind == 9001 || $kind == 9022) {
                delete $state->{members}{$target};
                delete $state->{admins}{$target};
            } else {
                $state->{members}{$target} = 1;
                if (grep { $_ eq 'admin' } @roles) { $state->{admins}{$target} = \@roles }
                else { delete $state->{admins}{$target} }
            }
            push @extra, $self->_membership_event($store,$event,$id,$target,
                $kind == 9001 || $kind == 9022, \@roles);
            $rosters{$id} = 1;
        } elsif ($kind == 9009) {
            my @code = grep { $_->[0] eq 'code' } @{$event->tags};
            croak 'invalid: invite requires one non-empty code' unless @code == 1 && @{$code[0]} == 2 && length($code[0][1]);
        } elsif ($kind == 9005) {
            my @refs = grep { $_->[0] eq 'e' } @{$event->tags};
            croak 'invalid: delete-event requires one event reference'
                unless @refs == 1 && @{$refs[0]} == 2 && $refs[0][1] =~ /\A[0-9a-f]{64}\z/;
            my $target = $store->get_by_id($refs[0][1]);
            croak 'restricted: deletion target must belong to this group'
                unless $target && (_group_id($target,'h') // '') eq $id;
            push @delete, $target->id;
        } elsif ($moderation) {
            croak 'restricted: unsupported moderation action';
        } else {
            croak 'restricted: group member required' if $state->{meta}{restricted} && !$state->{members}{$author};
            if (exists $state->{meta}{supported_kinds}) {
                croak 'restricted: unsupported group event kind'
                    unless grep { $_ == $kind } @{$state->{meta}{supported_kinds}};
            }
        }
    }
    my @events = @extra;
    my $build = sub {
        my $method = shift;
        my $number = shift;
        my $group_id = shift;
        my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
        my $previous = $store->find_addressable($self->pubkey,$number,$group_id);
        my $timestamp = time;
        $timestamp = $previous->created_at + 1 if $previous && $previous->created_at >= $timestamp;
        my $generated = Net::Nostr::Group->$method(pubkey=>$self->pubkey,group_id=>$group_id,
            created_at=>$timestamp,%args);
        $self->_key->sign_event($generated);
        push @events,$generated;
    };
    for my $group_id (sort keys %touch) {
        my %meta = %{$states{$group_id}{meta}};
        delete $meta{group_id};
        $build->('metadata',39000,$group_id,%meta);
    }
    for my $group_id (sort keys %rosters) {
        my $s = $states{$group_id};
        $build->('admins',39001,$group_id,members=>[map {{pubkey=>$_,roles=>$s->{admins}{$_}}} sort keys %{$s->{admins}}]);
        $build->('members',39002,$group_id,members=>[sort keys %{$s->{members}}]);
        $build->('roles',39003,$group_id,roles=>[{name=>'admin',description=>'Full group administration'}]);
    }
    $build->('pinned_events',39005,$_,pins=>$pins{$_}) for sort keys %pins;
    return {events=>\@events,delete_ids=>\@delete};
}

1;

__END__

=head1 NAME

Net::Nostr::RelayGroups - Optional NIP-29 group policy for Net::Nostr::Relay

=head1 SYNOPSIS

    use Net::Nostr::Relay;
    use Net::Nostr::RelayGroups;

    # $master is the relay's private Net::Nostr::Key; $url is its ws/wss URL.
    my $policy = Net::Nostr::RelayGroups->new(key => $master, max_pins => 2);
    my $relay = Net::Nostr::Relay->new(relay_url => $url, groups => $policy);

=head1 DESCRIPTION

Provides relay-scoped group state, moderation, ordered pins, and subgroups.
Pass an instance as the C<groups> option to L<Net::Nostr::Relay>. Group support
is disabled by default. When enabled, the relay advertises NIP-29 subgroups
and its signing public key through NIP-11.

Anyone may create an unused group with kind 9007, becoming its first member
and admin. New groups are public, open for joining, and restricted to members
for writes. Only the C<admin> role grants moderation privileges; arbitrary
other role labels grant none. Membership and administration never inherit
through parent links. Closed groups require a previously accepted invite code.
Invites are reusable. Creation and every accepted membership action generate
relay-signed kind 9000/9001 events, including the creator's initial admin role.
These canonical transitions have timestamps later than the triggering request
and previous membership transitions for that user in this group. This makes
rapid changes and successive membership actions distinguishable, even within one second;
generated timestamps may run ahead of wall-clock time. Original accepted
requests remain stored. Group metadata on the wire cannot bypass moderation.

Metadata edits preserve omitted display fields and flags; C<public>, C<open>,
C<visible>, and C<unrestricted> clear their opposing flags. Omitted C<parent>
detaches a group, and every edit must include all existing children in the
desired order. Reparenting requires administration of both groups, rejects
missing parents and cycles, and updates both sides. Deleting a group removes
its stored events and metadata, and makes its children roots. Pins replace
the entire ordered list; empty lists clear it.
Malformed or duplicate recognized metadata fields, contradictory flags,
invalid supported kinds, empty role labels, and malformed join codes are
rejected before storage changes. Kind 9001 permits only a public key in its
C<p> tag. C<supported_kinds> can be edited; an empty list disables ordinary
group publications while moderation remains available.

Private group history and live events, and hidden group metadata, are served
only to authenticated members. The Relay also applies this policy to COUNT
and negentropy. Reconciliation sessions are closed after group state changes
so a prior snapshot cannot bypass revoked membership; clients may reopen them.
Writes use the signed event author's membership. Timeline references must be
eight lowercase hex characters identifying another author's
event on this relay, including events outside the group. Zero references are
permitted; publication
more than one hour old or ten minutes in the future is rejected.

State is derived from the relay's signed metadata in the storage backend.
Use a persistent store that retains this metadata for durable groups. The
default in-memory store does not survive restarts. LiveKit token issuance,
automatic membership propagation, history import, and replica management are
outside this policy; AV metadata edits are rejected. Administrative local
storage injection is trusted and must maintain valid signed group state.

=head1 METHODS

=head2 new

Strict constructor accepting named arguments as either a flat list or a single hash
reference. Requires C<key>,
a private L<Net::Nostr::Key> used to sign state events. Optional C<max_pins>
is a non-negative integer; omission allows unlimited pins and zero allows
only empty lists. Unknown arguments and invalid values croak. The returned
policy is ready for use and has no mutable public configuration accessors.

=head2 pubkey

Returns the relay signing public key as lowercase hex.

=head2 prepare

Accepts an event and a L<Net::Nostr::RelayStore>-compatible backend. Verifies
the event ID and signature, then validates group structure, permissions,
and state transitions. Returns a plan with C<events> (signed metadata and
membership events) and C<delete_ids>. It does not mutate storage. Violations
croak with a Nostr error prefix. The Relay applies the complete plan only
after validation succeeds. This is a semantic policy operation; the input
must already be a structurally valid L<Net::Nostr::Event>.

=head2 can_read

Accepts an event, a hashref of authenticated public keys, and the backend.
Returns whether those identities may read the event under current group
state. Public groups do not require authentication. Unknown groups and
foreign group metadata are hidden. This checks authorization of an already
parsed event; it does not authenticate the supplied identity map.

=head1 SEE ALSO

L<NIP-29|https://github.com/nostr-protocol/nips/blob/master/29.md>,
L<NIP-42|https://github.com/nostr-protocol/nips/blob/master/42.md>,
L<Net::Nostr::Group>, L<Net::Nostr::Relay>, L<Net::Nostr::RelayStore>

=cut
