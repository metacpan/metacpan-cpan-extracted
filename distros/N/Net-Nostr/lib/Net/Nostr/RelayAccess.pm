package Net::Nostr::RelayAccess;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    members
    member
    claim
);

my %KINDS = (
    13534 => 'membership_list',
    8000  => 'add_member',
    8001  => 'remove_member',
    28934 => 'join_request',
    28935 => 'invite',
    28936 => 'leave_request',
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{members} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub membership_list {
    my ($class, %args) = @_;

    my $members = delete $args{members} // [];

    my @tags = (['-']);
    push @tags, ['member', $_] for @$members;

    return Net::Nostr::Event->new(
        %args,
        kind    => 13534,
        content => '',
        tags    => \@tags,
    );
}

sub add_member {
    my ($class, %args) = @_;

    my $member = delete $args{member}
        // croak "add_member requires 'member'";

    return Net::Nostr::Event->new(
        %args,
        kind    => 8000,
        content => '',
        tags    => [['-'], ['p', $member]],
    );
}

sub remove_member {
    my ($class, %args) = @_;

    my $member = delete $args{member}
        // croak "remove_member requires 'member'";

    return Net::Nostr::Event->new(
        %args,
        kind    => 8001,
        content => '',
        tags    => [['-'], ['p', $member]],
    );
}

sub join_request {
    my ($class, %args) = @_;

    my $claim = delete $args{claim}
        // croak "join_request requires 'claim'";

    return Net::Nostr::Event->new(
        %args,
        kind    => 28934,
        content => '',
        tags    => [['-'], ['claim', $claim]],
    );
}

sub invite {
    my ($class, %args) = @_;

    my $claim = delete $args{claim}
        // croak "invite requires 'claim'";

    return Net::Nostr::Event->new(
        %args,
        kind    => 28935,
        content => '',
        tags    => [['-'], ['claim', $claim]],
    );
}

sub leave_request {
    my ($class, %args) = @_;

    return Net::Nostr::Event->new(
        %args,
        kind    => 28936,
        content => '',
        tags    => [['-']],
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    return undef unless exists $KINDS{$kind};

    my (%attrs, @members);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if    ($t eq 'member') { push @members, $tag->[1] }
        elsif ($t eq 'p')      { $attrs{member} = $tag->[1] }
        elsif ($t eq 'claim')  { $attrs{claim} = $tag->[1] }
    }

    $attrs{members} = \@members if $kind == 13534;

    return $class->new(%attrs);
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "relay access event MUST be kind 13534, 8000, 8001, 28934, 28935, or 28936"
        unless exists $KINDS{$kind};

    croak "relay access event MUST have a \"-\" protected tag"
        unless $event->is_protected;

    if ($kind == 8000 || $kind == 8001) {
        my $has_p;
        for my $tag (@{$event->tags}) {
            if ($tag->[0] eq 'p') { $has_p = 1; last }
        }
        croak "add/remove member event MUST have a 'p' tag"
            unless $has_p;
    }

    if ($kind == 28934 || $kind == 28935) {
        my $has_claim;
        for my $tag (@{$event->tags}) {
            if ($tag->[0] eq 'claim') { $has_claim = 1; last }
        }
        croak "join/invite event MUST have a 'claim' tag"
            unless $has_claim;
    }

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::RelayAccess - NIP-43 Relay Access Metadata and Requests

=head1 SYNOPSIS

    use Net::Nostr::RelayAccess;

    # Membership list (kind 13534)
    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $hex_pubkey,
        members => [$member_pk1, $member_pk2],
    );

    # Add member (kind 8000)
    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $hex_pubkey,
        member => $member_pk,
    );

    # Remove member (kind 8001)
    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $hex_pubkey,
        member => $member_pk,
    );

    # Join request (kind 28934)
    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $hex_pubkey,
        claim  => $invite_code,
    );

    # Invite response (kind 28935)
    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $hex_pubkey,
        claim  => $generated_code,
    );

    # Leave request (kind 28936)
    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $hex_pubkey,
    );

    # Parse any relay access event
    my $parsed = Net::Nostr::RelayAccess->from_event($event);

    # Validate
    Net::Nostr::RelayAccess->validate($event);

=head1 DESCRIPTION

Implements NIP-43 (Relay Access Metadata and Requests). Six event kinds
are used:

=over 4

=item * B<Membership List> (kind 13534) - A replaceable event
listing pubkeys that have access to a relay. MUST be signed by the
relay's NIP-11 C<self> pubkey. Contains C<member> tags with hex
pubkeys.

=item * B<Add Member> (kind 8000) - Published when a member is added
to a relay. Contains a C<p> tag with the member's hex pubkey.

=item * B<Remove Member> (kind 8001) - Published when a member is
removed from a relay. Contains a C<p> tag with the member's hex
pubkey.

=item * B<Join Request> (kind 28934) - An ephemeral event sent by a
user to request admission to a relay. MUST contain a C<claim> tag
with an invite code.

=item * B<Invite> (kind 28935) - An ephemeral event returned by a
relay with a claim string. Relays generate claims on the fly when
requested.

=item * B<Leave Request> (kind 28936) - An ephemeral event sent by a
user to revoke their own access.

=back

All six kinds MUST include a NIP-70 C<["-"]> protected tag.

=head1 CONSTRUCTOR

=head2 new

    my $ra = Net::Nostr::RelayAccess->new(
        members => [$member_pk],
    );

Creates a new C<Net::Nostr::RelayAccess> object. Croaks on unknown
arguments. C<members> defaults to C<[]>.

=head1 CLASS METHODS

=head2 membership_list

    my $event = Net::Nostr::RelayAccess->membership_list(
        pubkey  => $hex_pubkey,          # required
        members => [$member_pk, ...],    # optional, defaults to []
    );

Creates a kind 13534 membership list L<Net::Nostr::Event>. Automatically
includes the NIP-70 C<["-"]> protected tag. Each member pubkey is
added as a C<["member", $pubkey]> tag.

=head2 add_member

    my $event = Net::Nostr::RelayAccess->add_member(
        pubkey => $hex_pubkey,           # required
        member => $member_pk,            # required (p tag)
    );

Creates a kind 8000 add-member L<Net::Nostr::Event>. Automatically
includes the NIP-70 C<["-"]> protected tag.

=head2 remove_member

    my $event = Net::Nostr::RelayAccess->remove_member(
        pubkey => $hex_pubkey,           # required
        member => $member_pk,            # required (p tag)
    );

Creates a kind 8001 remove-member L<Net::Nostr::Event>. Automatically
includes the NIP-70 C<["-"]> protected tag.

=head2 join_request

    my $event = Net::Nostr::RelayAccess->join_request(
        pubkey => $hex_pubkey,           # required
        claim  => $invite_code,          # required (claim tag)
    );

Creates a kind 28934 join request L<Net::Nostr::Event>. Automatically
includes the NIP-70 C<["-"]> protected tag. The C<claim> tag contains
the invite code.

=head2 invite

    my $event = Net::Nostr::RelayAccess->invite(
        pubkey => $hex_pubkey,           # required
        claim  => $generated_code,       # required (claim tag)
    );

Creates a kind 28935 invite L<Net::Nostr::Event>. Automatically
includes the NIP-70 C<["-"]> protected tag. The C<claim> tag contains
the generated invite code.

=head2 leave_request

    my $event = Net::Nostr::RelayAccess->leave_request(
        pubkey => $hex_pubkey,           # required
    );

Creates a kind 28936 leave request L<Net::Nostr::Event>. Automatically
includes the NIP-70 C<["-"]> protected tag. No other tags are
required.

=head2 from_event

    my $ra = Net::Nostr::RelayAccess->from_event($event);

Parses a kind 13534, 8000, 8001, 28934, 28935, or 28936 event into a
C<Net::Nostr::RelayAccess> object. Returns C<undef> for unrecognized
kinds.

=head2 validate

    Net::Nostr::RelayAccess->validate($event);

Validates a NIP-43 event. Croaks if:

=over

=item * Kind is not 13534, 8000, 8001, 28934, 28935, or 28936

=item * Missing NIP-70 C<["-"]> protected tag

=item * Kind 8000/8001 missing C<p> tag

=item * Kind 28934/28935 missing C<claim> tag

=back

Returns 1 on success.

=head1 ACCESSORS

=head2 members

Arrayref of hex pubkeys from C<member> tags (membership list only).
Defaults to C<[]>.

=head2 member

Hex pubkey from C<p> tag (add/remove member only).

=head2 claim

Invite code string from C<claim> tag (join request/invite only).

=head1 SEE ALSO

L<NIP-43|https://github.com/nostr-protocol/nips/blob/master/43.md>,
L<NIP-70|https://github.com/nostr-protocol/nips/blob/master/70.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
