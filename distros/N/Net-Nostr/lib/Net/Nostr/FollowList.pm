package Net::Nostr::FollowList;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

use Class::Tiny qw(_follows);

sub new {
    my $class = shift;
    my %args = @_;
    croak "unknown argument(s): " . join(', ', sort keys %args) if %args;
    my $self = bless {}, $class;
    $self->_follows([]);
    return $self;
}

sub from_event {
    my ($class, $event) = @_;
    croak "event must be kind 3" unless $event->kind == 3;
    my $self = $class->new;
    for my $tag (@{$event->tags}) {
        next unless $tag->[0] eq 'p';
        push @{$self->_follows}, {
            pubkey  => $tag->[1],
            relay   => $tag->[2] // '',
            petname => $tag->[3] // '',
        };
    }
    return $self;
}

sub add {
    my ($self, $pubkey, %opts) = @_;
    croak "pubkey must be 64-char lowercase hex"
        unless defined $pubkey && $pubkey =~ $HEX64;
    my $entry = {
        pubkey  => $pubkey,
        relay   => $opts{relay}   // '',
        petname => $opts{petname} // '',
    };
    # replace existing entry in place
    for my $i (0 .. $#{$self->_follows}) {
        if ($self->_follows->[$i]{pubkey} eq $pubkey) {
            $self->_follows->[$i] = $entry;
            return $self;
        }
    }
    push @{$self->_follows}, $entry;
    return $self;
}

sub remove {
    my ($self, $pubkey) = @_;
    $self->_follows([grep { $_->{pubkey} ne $pubkey } @{$self->_follows}]);
    return $self;
}

sub contains {
    my ($self, $pubkey) = @_;
    for my $entry (@{$self->_follows}) {
        return 1 if $entry->{pubkey} eq $pubkey;
    }
    return 0;
}

sub count {
    my ($self) = @_;
    return scalar @{$self->_follows};
}

sub follows {
    my ($self) = @_;
    return @{$self->_follows};
}

sub to_tags {
    my ($self) = @_;
    return [map { ['p', $_->{pubkey}, $_->{relay}, $_->{petname}] } @{$self->_follows}];
}

sub to_event {
    my ($self, %args) = @_;
    return Net::Nostr::Event->new(
        %args,
        kind    => 3,
        content => '',
        tags    => $self->to_tags,
    );
}

1;

__END__

=head1 NAME

Net::Nostr::FollowList - NIP-02 follow list management

=head1 SYNOPSIS

    use Net::Nostr::FollowList;

    # Build a follow list
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://relay.example.com/', petname => 'alice');
    $fl->add('b' x 64, petname => 'bob');
    $fl->add('c' x 64);

    # Query
    say $fl->count;                  # 3
    say $fl->contains('a' x 64);    # 1

    # Remove
    $fl->remove('b' x 64);

    # Convert to a kind 3 event for publishing
    my $event = $fl->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);
    $client->publish($event);

    # Parse from a received kind 3 event
    my $fl = Net::Nostr::FollowList->from_event($event);
    for my $f ($fl->follows) {
        say "$f->{petname}: $f->{pubkey} ($f->{relay})";
    }

=head1 DESCRIPTION

Implements NIP-02 follow lists. A follow list is a kind 3 replaceable event
containing C<p> tags, one per followed profile. Each tag carries the
profile's pubkey, an optional relay URL, and an optional petname.

New follows are appended to the end of the list per NIP-02 convention.
Re-adding an existing pubkey updates the entry in place.

=head1 CONSTRUCTOR

=head2 new

    my $fl = Net::Nostr::FollowList->new;

Creates an empty follow list. Croaks on unknown arguments.

=head2 from_event

    my $fl = Net::Nostr::FollowList->from_event($event);

Parses a kind 3 event into a FollowList. Extracts all C<p> tags and
ignores other tag types. Croaks if the event is not kind 3.

    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 3, content => '',
        tags => [['p', 'b' x 64, 'wss://relay.com/', 'bob']],
    );
    my $fl = Net::Nostr::FollowList->from_event($event);
    say $fl->count;  # 1

=head1 METHODS

=head2 add

    $fl->add($pubkey);
    $fl->add($pubkey, relay => 'wss://relay.com/', petname => 'alice');

Adds a follow entry. C<$pubkey> must be 64-character lowercase hex.
C<relay> and C<petname> default to empty string. If the pubkey already
exists, the entry is updated in place. Returns C<$self> for chaining.

    $fl->add('a' x 64, relay => 'wss://r.com/')
       ->add('b' x 64, petname => 'bob');

=head2 remove

    $fl->remove($pubkey);

Removes the entry for the given pubkey. No-op if not present.
Returns C<$self> for chaining.

=head2 contains

    my $bool = $fl->contains($pubkey);

Returns true if the given pubkey is in the follow list.

    $fl->add('a' x 64);
    say $fl->contains('a' x 64);  # 1
    say $fl->contains('b' x 64);  # 0

=head2 count

    my $n = $fl->count;

Returns the number of follows in the list.

=head2 follows

    my @follows = $fl->follows;

Returns the list of follow entries as hashrefs, each with keys
C<pubkey>, C<relay>, and C<petname>. Entries appear in the order
they were added.

    for my $f ($fl->follows) {
        say "$f->{petname}: $f->{pubkey}";
    }

=head2 to_tags

    my $tags = $fl->to_tags;
    # [['p', 'aa...', 'wss://r.com/', 'alice'], ...]

Returns the follow list as an arrayref of tag arrays, suitable for
passing to L<Net::Nostr::Event/new>.

=head2 to_event

    my $event = $fl->to_event(pubkey => $pubkey_hex);
    my $event = $fl->to_event(pubkey => $pubkey_hex, created_at => time());

Creates a kind 3 L<Net::Nostr::Event> from the follow list. All extra
arguments are passed through to C<< Net::Nostr::Event->new >>. The
C<kind>, C<content>, and C<tags> fields are set automatically.

    my $event = $fl->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);

=head1 SEE ALSO

L<NIP-02|https://github.com/nostr-protocol/nips/blob/master/02.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Key>

=cut
