package Net::Nostr::GroupDiscovery;

use strictures 2;
use Net::Nostr::_ConstructorArgs ();
use Net::Nostr::_URI qw(validate_relay_url);
use Net::Nostr::Group;
use Net::Nostr::List;
use Net::Nostr::Filter;
use Net::Nostr::Key;
use AnyEvent;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);
use Class::Tiny qw(_config _admins _timer _checking _events _candidates _admin_event _timeout);

sub _pubkeys {
    my ($name,$values) = @_;
    croak "$name must be an array of public keys" unless ref($values) eq 'ARRAY';
    my %unique;
    for my $key (@$values) {
        croak "$name must contain 64-char lowercase hex public keys"
            unless defined($key) && !ref($key) && $key =~ /\A[0-9a-f]{64}\z/;
        $unique{$key}=1;
    }
    return [sort keys %unique];
}

sub new {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);
    my %known = map { $_=>1 } qw(group_id relay relay_pubkey admins trusted_friends lookup on_candidate on_error interval timeout);
    my @unknown = grep { !$known{$_} } keys %args;
    croak 'unknown argument(s): '.join(', ',sort @unknown) if @unknown;
    croak 'group_id must be a non-empty string' unless Net::Nostr::Group->validate_group_id($args{group_id});
    validate_relay_url($args{relay},label=>'relay');
    _pubkeys('relay_pubkey',[$args{relay_pubkey}]);
    my $admins = _pubkeys('admins',$args{admins});
    $args{trusted_friends} = [] unless exists $args{trusted_friends};
    $args{trusted_friends} = _pubkeys('trusted_friends',$args{trusted_friends});
    croak 'admins or trusted_friends must supply at least one discovery author'
        unless @$admins || @{$args{trusted_friends}};
    for my $name (qw(lookup on_candidate on_error)) {
        next if $name eq 'on_error' && !exists $args{$name};
        croak "$name must be a code reference" unless ref($args{$name}) eq 'CODE';
    }
    $args{interval}=300 unless exists $args{interval};
    $args{timeout}=10 unless exists $args{timeout};
    for my $name (qw(interval timeout)) {
        croak "$name must be positive seconds"
            unless defined($args{$name}) && !ref($args{$name})
                && $args{$name} =~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/ && $args{$name}>0;
    }
    delete $args{admins};
    return bless {_config=>\%args,_admins=>$admins,_events=>{},_candidates=>{}},$class;
}

sub relay { $_[0]->_config->{relay} }
sub admins { [@{$_[0]->_admins}] }

sub cache_admins {
    my ($self,$event) = @_;
    croak 'admin event must be a Net::Nostr::Event' unless blessed($event) && $event->isa('Net::Nostr::Event');
    $event->validate;
    croak 'admin event author must be the current relay key' unless $event->pubkey eq $self->_config->{relay_pubkey};
    my @group_tags = grep { @$_ && $_->[0] eq 'd' } @{$event->tags};
    croak 'admin event requires exactly one group tag'
        unless @group_tags == 1 && @{$group_tags[0]} == 2;
    my %seen;
    for my $tag (@{$event->tags}) {
        next unless @$tag && $tag->[0] eq 'p';
        croak 'admin must have a unique public key and at least one role'
            unless @$tag >= 3 && !$seen{$tag->[1]}++;
        croak 'admin role must be non-empty' if grep { !length($_) } @$tag[2 .. $#$tag];
    }
    my $parsed = Net::Nostr::Group->admins_from_event($event);
    croak 'admin event must describe this group' unless ($parsed->{group_id} // '') eq $self->_config->{group_id};
    my $keys = _pubkeys('admins',[map { $_->{pubkey} } @{$parsed->{admins}}]);
    my $old = $self->_admin_event;
    return 0 if $old && !_newer($event,$old);
    $self->_admins($keys);
    $self->_admin_event($event);
    return 1;
}

sub _newer {
    my ($a,$b)=@_;
    return $a->created_at > $b->created_at || ($a->created_at == $b->created_at && $a->id lt $b->id);
}

sub _entry_id {
    my ($value,$literal)=@_;
    croak 'group entry must contain a non-empty group id' unless Net::Nostr::Group->validate_group_id($value);
    return $value if defined($literal) && $value eq $literal;
    return $value unless $value =~ /\Anaddr1/i;
    my $reference = eval { Net::Nostr::Group->parse_id($value) };
    return $reference ? $reference->{group_id} : $value;
}

sub _announcements {
    my ($self,$events,$trusted) = @_;
    croak 'lookup must return an array of events' unless ref($events) eq 'ARRAY';
    my %latest = %{$self->_events};
    for my $event (@$events) {
        croak 'lookup entry must be a Net::Nostr::Event' unless blessed($event) && $event->isa('Net::Nostr::Event');
        next unless $trusted->{$event->pubkey};
        $event->validate;
        croak 'lookup event must be kind 10009' unless $event->kind == 10009;
        for my $tag (@{$event->tags}) {
            next unless @$tag && $tag->[0] eq 'group';
            croak 'group entry requires an id and relay hint' unless @$tag >= 3;
            _entry_id($tag->[1],$self->_config->{group_id});
            validate_relay_url($tag->[2],label=>'group relay');
        }
        my $old=$latest{$event->pubkey};
        $latest{$event->pubkey}=$event if !$old || _newer($event,$old);
    }
    my %candidates;
    for my $author (sort keys %latest) {
        next unless $trusted->{$author};
        for my $tag (@{$latest{$author}->tags}) {
            next unless @$tag && $tag->[0] eq 'group';
            next unless _entry_id($tag->[1],$self->_config->{group_id}) eq $self->_config->{group_id};
            next if $tag->[2] eq $self->relay;
            push @{$candidates{$tag->[2]}},$author;
        }
    }
    $self->_events(\%latest);
    my $previous=$self->_candidates;
    $self->_candidates(\%candidates);
    for my $relay (sort keys %candidates) {
        next if exists $previous->{$relay};
        $self->_notify('on_candidate',{group_id=>$self->_config->{group_id},relay=>$relay,
            advertised_by=>[@{$candidates{$relay}}]});
    }
}

sub _notify {
    my ($self,$name,$value)=@_;
    my $callback=$self->_config->{$name};
    if ($callback) { eval { $callback->($value); 1 } or warn "group discovery callback failed: $@" }
    elsif ($name eq 'on_error') { warn "group discovery failed: $value" }
}

sub check {
    my ($self)=@_;
    return 0 if $self->_checking;
    my %trusted=map { $_=>1 } (@{$self->_admins},@{$self->_config->{trusted_friends}});
    unless (%trusted) {
        $self->_notify('on_error','no cached discovery authors');
        return 0;
    }
    my $filter=Net::Nostr::Filter->new(kinds=>[10009],authors=>[sort keys %trusted]);
    $self->_checking(1);
    weaken(my $weak=$self);
    my $done=0;
    my $complete=sub {
        return if $done++;
        my $self=$weak or return;
        my ($events,$error)=@_;
        $self->_checking(0);
        $self->_timeout(undef);
        if (!defined $error) {
            my %current = map { $_=>1 } (@{$self->_admins},@{$self->_config->{trusted_friends}});
            eval { $self->_announcements($events,\%current); 1 } or $error=$@;
        }
        $self->_notify('on_error',$error) if defined $error;
    };
    $self->_timeout(AnyEvent->timer(after=>$self->_config->{timeout},cb=>sub { $complete->(undef,'lookup timed out') }));
    eval { $self->_config->{lookup}->($filter,$complete); 1 } or $complete->(undef,$@);
    return 1;
}

sub primary_unreachable { $_[0]->check }

sub start {
    my ($self)=@_;
    return if $self->_timer;
    weaken(my $weak=$self);
    $self->_timer(AnyEvent->timer(after=>$self->_config->{interval},interval=>$self->_config->{interval},
        cb=>sub { my $self=$weak or return; $self->check }));
    $self->check;
}

sub stop { $_[0]->_timer(undef) }

sub migration_event {
    my $self=shift;
    my %args=Net::Nostr::_ConstructorArgs::normalize(@_);
    my @unknown=grep { $_ ne 'relay' && $_ ne 'event' && $_ ne 'key' } keys %args;
    croak 'unknown argument(s): '.join(', ',sort @unknown) if @unknown;
    validate_relay_url($args{relay},label=>'migration relay');
    my ($event,$key)=@args{qw(event key)};
    croak 'event must be a kind 10009 Net::Nostr::Event'
        unless blessed($event) && $event->isa('Net::Nostr::Event') && $event->kind == 10009;
    croak 'key must own the list author' unless blessed($key) && $key->isa('Net::Nostr::Key') && $event->pubkey eq $key->pubkey_hex;
    $event->validate;
    my $old=Net::Nostr::List->from_event($event,key=>$key);
    my $new=Net::Nostr::List->new(kind=>10009);
    my ($matched,$has_relay)=(0,0);
    for my $pair ([$old->items,'add'],[$old->private_items,'add_private']) {
        my ($items,$method)=@$pair;
        for my $tag (@$items) {
            my @copy=@$tag;
            if ($copy[0] eq 'group') {
                croak 'group entry requires an id and relay hint' unless @copy>=3;
                my $id=_entry_id($copy[1],$self->_config->{group_id});
                validate_relay_url($copy[2],label=>'group relay');
                if ($id eq $self->_config->{group_id} && $copy[2] eq $self->relay) {
                    @copy[1,2]=($id,$args{relay});
                    $matched=1;
                }
            }
            $has_relay=1 if $copy[0] eq 'r' && defined($copy[1]) && $copy[1] eq $args{relay};
            $new->$method(@copy);
        }
    }
    $new->add('group',$self->_config->{group_id},$args{relay}) unless $matched;
    $new->add('r',$args{relay}) unless $has_relay;
    my $timestamp=time;
    $timestamp=$event->created_at+1 if $event->created_at >= $timestamp;
    my $result=$new->to_event(pubkey=>$key->pubkey_hex,key=>$key,created_at=>$timestamp);
    $key->sign_event($result);
    return $result;
}

1;

__END__

=head1 NAME

Net::Nostr::GroupDiscovery - NIP-29 migration and fork discovery

=head1 SYNOPSIS

    use Net::Nostr::GroupDiscovery;

    # $discovery_client is a dedicated, already connected Net::Nostr::Client.
    # Restore $relay_pubkey and $admin_pubkey from the trusted local cache.
    my @candidates;
    my $lookup_number = 0;
    my $watch = Net::Nostr::GroupDiscovery->new(
        group_id => 'pizza', relay => 'wss://old.example',
        relay_pubkey => $relay_pubkey, admins => [$admin_pubkey],
        lookup => sub {
            my ($filter, $complete) = @_;
            my $sub_id = 'group-discovery-' . ++$lookup_number;
            my @events;
            $discovery_client->on(event => sub {
                push @events, $_[1] if $_[0] eq $sub_id;
            });
            $discovery_client->on(eose => sub {
                return unless $_[0] eq $sub_id;
                $discovery_client->close($sub_id);
                $complete->(\@events, undef);
            });
            $discovery_client->subscribe($sub_id, $filter);
        },
        on_candidate => sub { push @candidates, $_[0] },
    );
    $watch->primary_unreachable;

=head1 DESCRIPTION

Coordinates lookup of kind 10009 group lists using cached administrator keys
and trusted friends. Reports alternate relay hints without switching relays
or publishing a list. Identical group IDs on different relays are separate
instances and may represent intentional forks.

The application supplies a C<lookup> transport callback, typically querying
its already connected discovery relays with L<Net::Nostr::Client>. It receives
a L<Net::Nostr::Filter> and a completion callback. Gather matching stored
events through EOSE from those relays, then invoke completion once as
C<$complete-E<gt>(\@events, undef)> or C<$complete-E<gt>(undef, $error)>.
Use relays independent of the group's primary relay so lookup works offline.
Returned events are authenticated again before they influence discovery.
The SYNOPSIS is a minimal single-author, single-relay lookup. A production
transport must account for relay caps, pagination hints, authentication,
C<CLOSED> replies, and disconnects before treating a batch as complete. Each
lookup needs a fresh subscription ID so late messages cannot complete a later
request. The watcher's timeout permits retries but does not close transport
subscriptions; the application must clean those up.

Call C<primary_unreachable> when the primary connection fails or becomes
unreachable: NIP-29 requires a lookup in that situation. Call C<start> to
enable recommended periodic checks. Persist the C<admins> snapshot in the
application's local storage, and refresh it with C<cache_admins> while the
primary relay is available. This helper does not monitor network reachability
or persist the cache on disk itself.

Show C<on_candidate> results to the user and offer to fetch the group's
metadata and history from the candidate relay. A hint is not proof that a
relay hosts the desired community: inspect its own signed metadata and
administrators. Only after the user chooses a migration should the application
build and publish C<migration_event>, switch its primary connection, and
construct a new watcher with that relay's key and admin cache. Live history
replication remains an application responsibility.

=head1 METHODS

=head2 new

Strict constructor accepting named arguments as either a flat list or a single hash
reference. Required arguments are
C<group_id>, C<relay> (strict ws/wss URL), C<relay_pubkey> (64 lowercase hex),
C<admins> (array of public keys), C<lookup> and C<on_candidate> (callbacks).
Optional C<trusted_friends> defaults to an empty array. At least one admin or
friend is required. Arrays are validated, deduplicated, sorted, and copied.
C<interval> defaults to 300 positive seconds; C<timeout> defaults to 10.
Optional C<on_error> receives lookup errors; otherwise they produce warnings.
Invalid values and unknown options croak. Construction starts no network work.

=head2 relay

Returns the configured primary relay URL.

=head2 admins

Returns a defensive array copy of cached administrator public keys.

=head2 cache_admins

Authenticates a kind 39001 event from the configured relay key and requires
this group's ID. Validates every administrator key, exactly one group tag,
unique administrator entries, and non-empty role labels. Discovery completions
use the current cache, so a removed admin cannot redirect a lookup already
in progress. Replaces the cache only with a newer event (lower event ID wins
timestamp ties). Returns one on
replacement or zero for an older or duplicate event. Malformed, forged, or
wrong-relay metadata croaks. Persist the returned C<admins> snapshot locally.

=head2 check

Starts a lookup using the cached admins and trusted friends. Returns one if
started, or zero if a lookup is already in progress or no authors remain.
Accepts only valid signed kind 10009 events from those authors. Validates group
IDs and relay hints, retains the newest event per author, and calls
C<on_candidate> for newly observed alternate relays. The callback receives
C<group_id>, C<relay>, and an C<advertised_by> array of public keys in a hashref.
Unknown authors are ignored. Malformed lookup batches are rejected without
changing discovery state. Repeated completion calls are ignored. Timeout or
lookup exceptions reach C<on_error>; later checks may retry.
Group IDs are arbitrary non-empty strings. Valid kind-39000 naddr references
are also resolved, but strings merely starting with C<naddr1> remain valid
raw IDs. An exact match to the configured raw group ID takes precedence.

=head2 primary_unreachable

Immediately calls C<check>, even when periodic checking has not been started.
An already pending lookup also satisfies this request without overlapping it.

=head2 start

Checks immediately and installs an AnyEvent timer using C<interval>. Repeated
calls do not create additional timers. The application's event loop must run.

=head2 stop

Cancels periodic checks. An already pending lookup may still complete.

=head2 migration_event

Strict builder taking C<relay>, C<event> (the user's signed kind 10009 list),
and C<key> (its private author key). Validates and authenticates the list,
updates references to this group on the configured primary relay, and retains
other groups and same-ID forks. Updates both public and encrypted private
items, adds the new relay hint, and returns a newly signed event with a newer
timestamp. Existing relay hints are retained because other groups may use
them. A migrated naddr reference becomes a raw group ID, avoiding reuse of
the old relay's signing key. If no existing entry matches, adds a public entry.
Does not publish, mutate the input list, or change the watcher's relay.

=head1 SEE ALSO

L<NIP-29|https://github.com/nostr-protocol/nips/blob/master/29.md>,
L<NIP-51|https://github.com/nostr-protocol/nips/blob/master/51.md>,
L<Net::Nostr::Client>, L<Net::Nostr::Group>, L<Net::Nostr::List>

=cut
