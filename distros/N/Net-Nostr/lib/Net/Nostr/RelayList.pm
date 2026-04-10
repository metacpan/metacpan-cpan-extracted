package Net::Nostr::RelayList;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(_relays);

sub new {
    my $class = shift;
    my %args = @_;
    croak "unknown argument(s): " . join(', ', sort keys %args) if %args;
    my $self = bless {}, $class;
    $self->_relays([]);
    return $self;
}

sub from_event {
    my ($class, $event) = @_;
    croak "event must be kind 10002" unless $event->kind == 10002;
    my $self = $class->new;
    for my $tag (@{$event->tags}) {
        next unless $tag->[0] eq 'r';
        push @{$self->_relays}, {
            url    => $tag->[1],
            marker => $tag->[2] // '',
        };
    }
    return $self;
}

sub add {
    my ($self, $url, %opts) = @_;
    croak "url required" unless defined $url;
    my $marker = $opts{marker} // '';
    croak "marker must be 'read', 'write', or omitted"
        unless $marker eq '' || $marker eq 'read' || $marker eq 'write';
    my $entry = { url => $url, marker => $marker };
    # replace existing entry in place
    for my $i (0 .. $#{$self->_relays}) {
        if ($self->_relays->[$i]{url} eq $url) {
            $self->_relays->[$i] = $entry;
            return $self;
        }
    }
    push @{$self->_relays}, $entry;
    return $self;
}

sub remove {
    my ($self, $url) = @_;
    $self->_relays([grep { $_->{url} ne $url } @{$self->_relays}]);
    return $self;
}

sub contains {
    my ($self, $url) = @_;
    for my $entry (@{$self->_relays}) {
        return 1 if $entry->{url} eq $url;
    }
    return 0;
}

sub count {
    my ($self) = @_;
    return scalar @{$self->_relays};
}

sub relays {
    my ($self) = @_;
    return @{$self->_relays};
}

sub write_relays {
    my ($self) = @_;
    return map { $_->{url} }
        grep { $_->{marker} eq '' || $_->{marker} eq 'write' }
        @{$self->_relays};
}

sub read_relays {
    my ($self) = @_;
    return map { $_->{url} }
        grep { $_->{marker} eq '' || $_->{marker} eq 'read' }
        @{$self->_relays};
}

sub to_tags {
    my ($self) = @_;
    return [map {
        $_->{marker} eq ''
            ? ['r', $_->{url}]
            : ['r', $_->{url}, $_->{marker}]
    } @{$self->_relays}];
}

sub to_event {
    my ($self, %args) = @_;
    return Net::Nostr::Event->new(
        %args,
        kind    => 10002,
        content => '',
        tags    => $self->to_tags,
    );
}

1;

__END__

=head1 NAME

Net::Nostr::RelayList - NIP-65 relay list metadata

=head1 SYNOPSIS

    use Net::Nostr::RelayList;

    # Build a relay list
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://alicerelay.example.com');
    $rl->add('wss://expensive-relay.example2.com', marker => 'write');
    $rl->add('wss://nostr-relay.example.com', marker => 'read');

    # Query relay categories
    my @write = $rl->write_relays;  # unmarked + write-marked
    my @read  = $rl->read_relays;   # unmarked + read-marked

    # Convert to a kind 10002 event for publishing
    my $event = $rl->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);
    $client->publish($event);

    # Parse from a received kind 10002 event
    my $rl = Net::Nostr::RelayList->from_event($event);
    for my $r ($rl->relays) {
        say "$r->{url} ($r->{marker})";
    }

=head1 DESCRIPTION

Implements NIP-65 relay list metadata. A relay list is a kind 10002
replaceable event containing C<r> tags, one per relay. Each tag carries
a relay URL and an optional C<read> or C<write> marker. If the marker is
omitted, the relay is used for both reading and writing.

Clients SHOULD use an author's B<write> relays when downloading events
B<from> that user, and B<read> relays when downloading events B<about>
that user (where the user was tagged). Clients SHOULD guide users to keep
lists small (2-4 relays per category).

=head1 CONSTRUCTOR

=head2 new

    my $rl = Net::Nostr::RelayList->new;

Creates an empty relay list. Croaks on unknown arguments.

=head2 from_event

    my $rl = Net::Nostr::RelayList->from_event($event);

Parses a kind 10002 event into a RelayList. Extracts all C<r> tags and
ignores other tag types. Croaks if the event is not kind 10002.

    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 10002, content => '',
        tags => [['r', 'wss://relay.example.com', 'write']],
    );
    my $rl = Net::Nostr::RelayList->from_event($event);
    say $rl->count;  # 1

=head1 METHODS

=head2 add

    $rl->add($url);
    $rl->add($url, marker => 'write');
    $rl->add($url, marker => 'read');

Adds a relay entry. C<marker> must be C<'read'>, C<'write'>, or omitted
(meaning both). If the URL already exists, the entry is updated in place.
Returns C<$self> for chaining.

    $rl->add('wss://relay1.com')
       ->add('wss://relay2.com', marker => 'write');

=head2 remove

    $rl->remove($url);

Removes the entry for the given URL. No-op if not present.
Returns C<$self> for chaining.

=head2 contains

    my $bool = $rl->contains($url);

Returns true if the given relay URL is in the list.

    $rl->add('wss://relay.com');
    say $rl->contains('wss://relay.com');   # 1
    say $rl->contains('wss://other.com');   # 0

=head2 count

    my $n = $rl->count;

Returns the total number of relays in the list.

=head2 relays

    my @relays = $rl->relays;

Returns the list of relay entries as hashrefs, each with keys
C<url> and C<marker>. Entries appear in the order they were added.

    for my $r ($rl->relays) {
        say "$r->{url}: $r->{marker}";
    }

=head2 write_relays

    my @urls = $rl->write_relays;

Returns the URLs of relays the user writes to: those with marker
C<'write'> or no marker (both). Use these when downloading events
B<from> the user.

    $rl->add('wss://both.example.com');
    $rl->add('wss://w.example.com', marker => 'write');
    $rl->add('wss://r.example.com', marker => 'read');
    my @write = $rl->write_relays;
    # ('wss://both.example.com', 'wss://w.example.com')

=head2 read_relays

    my @urls = $rl->read_relays;

Returns the URLs of relays the user reads from: those with marker
C<'read'> or no marker (both). Use these when downloading events
B<about> the user (where the user was tagged).

    $rl->add('wss://both.example.com');
    $rl->add('wss://w.example.com', marker => 'write');
    $rl->add('wss://r.example.com', marker => 'read');
    my @read = $rl->read_relays;
    # ('wss://both.example.com', 'wss://r.example.com')

=head2 to_tags

    my $tags = $rl->to_tags;
    # [['r', 'wss://relay.com'], ['r', 'wss://w.com', 'write'], ...]

Returns the relay list as an arrayref of tag arrays, suitable for
passing to L<Net::Nostr::Event/new>. The marker is omitted for
relays with no marker.

=head2 to_event

    my $event = $rl->to_event(pubkey => $pubkey_hex);
    my $event = $rl->to_event(pubkey => $pubkey_hex, created_at => time());

Creates a kind 10002 L<Net::Nostr::Event> from the relay list. All extra
arguments are passed through to C<< Net::Nostr::Event->new >>. The
C<kind>, C<content>, and C<tags> fields are set automatically.

    my $event = $rl->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);

=head1 SEE ALSO

L<NIP-65|https://github.com/nostr-protocol/nips/blob/master/65.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
