package Net::Nostr::Repost;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

use Class::Tiny qw(
    event_id
    relay_url
    author_pubkey
    reposted_kind
    event_coordinate
    embedded_event
    quote_event_id
);

my $JSON = JSON->new->utf8;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub repost {
    my ($class, %args) = @_;

    my $event     = $args{event}     // croak "repost requires 'event'";
    my $pubkey    = $args{pubkey}    // croak "repost requires 'pubkey'";
    my $relay_url = $args{relay_url} // croak "repost requires 'relay_url'";

    my $event_id     = $event->id;
    my $author_pubkey = $event->pubkey;
    croak "event_id must be 64-char lowercase hex" unless $event_id =~ $HEX64;
    croak "author_pubkey must be 64-char lowercase hex" unless $author_pubkey =~ $HEX64;

    my $kind = $event->kind == 1 ? 6 : 16;

    # Content: stringified JSON of reposted event, or empty if overridden
    my $content;
    if (exists $args{content}) {
        $content = $args{content};
    } else {
        $content = $JSON->encode($event->to_hash);
    }

    my @tags;

    # MUST: e tag with relay URL
    push @tags, ['e', $event_id, $relay_url];

    # SHOULD: p tag with original author
    push @tags, ['p', $author_pubkey];

    # Generic repost extras (kind 16 only)
    if ($kind == 16) {
        # SHOULD: k tag with stringified kind
        push @tags, ['k', '' . $event->kind];

        # SHOULD: a tag for addressable events
        if ($event->is_addressable) {
            my $coord = $event->kind . ':' . $event->pubkey . ':' . $event->d_tag;
            push @tags, ['a', $coord];
        }
    }

    # MAY: q tag for quote reposts
    if ($args{quote}) {
        push @tags, ['q', $event_id, $relay_url, $author_pubkey];
    }

    delete @args{qw(event relay_url quote content)};
    return Net::Nostr::Event->new(%args, kind => $kind, content => $content, tags => \@tags);
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 6 || $event->kind == 16;

    my ($event_id, $relay_url, $author_pubkey, $reposted_kind, $event_coordinate, $quote_event_id);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'e' && !defined $event_id) {
            $event_id  = $tag->[1];
            $relay_url = $tag->[2] // '';
        } elsif ($name eq 'p' && !defined $author_pubkey) {
            $author_pubkey = $tag->[1];
        } elsif ($name eq 'k' && !defined $reposted_kind) {
            $reposted_kind = $tag->[1];
        } elsif ($name eq 'a' && !defined $event_coordinate) {
            $event_coordinate = $tag->[1];
        } elsif ($name eq 'q' && !defined $quote_event_id) {
            $quote_event_id = $tag->[1];
        }
    }

    # Parse embedded event from content
    my $embedded;
    if (defined $event->content && length $event->content) {
        my $hash = eval { JSON::decode_json($event->content) };
        if ($hash && ref $hash eq 'HASH') {
            $embedded = eval { Net::Nostr::Event->new(%$hash) };
        }
    }

    return $class->new(
        event_id         => $event_id,
        relay_url        => $relay_url,
        author_pubkey    => $author_pubkey,
        reposted_kind    => $reposted_kind,
        event_coordinate => $event_coordinate,
        embedded_event   => $embedded,
        quote_event_id   => $quote_event_id,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "repost MUST be kind 6 or 16" unless $event->kind == 6 || $event->kind == 16;

    my $has_e_with_relay = 0;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'e' && defined $tag->[1] && defined $tag->[2] && length $tag->[2]) {
            $has_e_with_relay = 1;
            last;
        }
    }

    # Check for e tag at all
    my $has_e = grep { $_->[0] eq 'e' } @{$event->tags};
    croak "repost MUST include an e tag" unless $has_e;
    croak "repost e tag MUST include a relay URL" unless $has_e_with_relay;

    return 1;
}

1;

__END__

=head1 NAME

Net::Nostr::Repost - NIP-18 reposts and generic reposts

=head1 SYNOPSIS

    use Net::Nostr::Repost;

    # Repost a kind 1 text note (creates kind 6)
    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $my_pubkey,
        relay_url => 'wss://relay.example.com',
    );

    # Repost any other event (creates kind 16)
    my $repost = Net::Nostr::Repost->repost(
        event     => $article,
        pubkey    => $my_pubkey,
        relay_url => 'wss://relay.example.com',
    );

    # Quote repost (adds q tag)
    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $my_pubkey,
        relay_url => 'wss://relay.example.com',
        quote     => 1,
    );

    # Parse repost structure from an event
    my $info = Net::Nostr::Repost->from_event($event);
    if ($info) {
        say "Reposted event: " . $info->event_id;
        say "From relay: " . $info->relay_url;
        if ($info->embedded_event) {
            say "Content: " . $info->embedded_event->content;
        }
    }

    # Validate a repost event
    Net::Nostr::Repost->validate($event);

=head1 DESCRIPTION

Implements NIP-18 reposts. A repost is a kind 6 event for sharing kind 1
text notes, or a kind 16 "generic repost" for sharing any other event kind.

The repost content is the stringified JSON of the reposted event (MAY be
empty). Reposts of L<NIP-70|https://github.com/nostr-protocol/nips/blob/master/70.md>-protected
events SHOULD always have an empty content. Tags include an C<e> tag with
the event ID and relay URL (MUST), a C<p> tag with the original author
(SHOULD), and for generic reposts a C<k> tag with the stringified kind
(SHOULD) and an C<a> tag with the event coordinate for addressable events
(SHOULD).

Quote reposts use a C<q> tag instead of being pulled into reply threads.
The C<q> tag format is
C<["q", "E<lt>event-idE<gt>", "E<lt>relay-urlE<gt>", "E<lt>pubkeyE<gt>"]>.

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Repost->new(%fields);

Creates a new C<Net::Nostr::Repost> object.  Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Repost->new(
        event_id    => 'aa' x 32,
        relay_url   => 'wss://relay.example.com',
    );

Accepted fields: C<event_id>, C<relay_url>, C<author_pubkey>,
C<reposted_kind>, C<event_coordinate>, C<embedded_event>,
C<quote_event_id>. Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 repost

    my $event = Net::Nostr::Repost->repost(
        event      => $original_event,    # Net::Nostr::Event to repost
        pubkey     => $hex_pubkey,        # reposter's hex pubkey
        relay_url  => 'wss://relay.example.com',
        content    => '',                 # optional, override content
        quote      => 1,                  # optional, add q tag
        created_at => time(),             # optional, passed to Event
    );

Creates a repost L<Net::Nostr::Event>. If the original event is kind 1,
creates a kind 6 repost. Otherwise creates a kind 16 generic repost with
a C<k> tag and (for addressable events) an C<a> tag.

The C<event> parameter is the L<Net::Nostr::Event> being reposted. The
C<pubkey> is the reposter's hex public key (the original author's pubkey
is taken from the event's C<pubkey> field for the C<p> tag).

The content defaults to the stringified JSON of the original event. Pass
C<content =E<gt> ''> to create a repost with empty content (e.g. for
L<NIP-70|https://github.com/nostr-protocol/nips/blob/master/70.md>-protected
events).

Pass C<quote =E<gt> 1> to add a C<q> tag for quote reposts.

Returns a L<Net::Nostr::Event> with the appropriate kind, tags, and content.

Croaks if C<event>, C<pubkey>, or C<relay_url> is missing.

=head2 from_event

    my $info = Net::Nostr::Repost->from_event($event);

Parses repost structure from a kind 6 or kind 16 L<Net::Nostr::Event>.
Returns a C<Net::Nostr::Repost> object with accessors, or C<undef> if
the event is not a repost kind.

    my $info = Net::Nostr::Repost->from_event($event);
    say $info->event_id;                         # reposted event id
    say $info->embedded_event->content if $info->embedded_event;

=head2 validate

    Net::Nostr::Repost->validate($event);

Validates that a L<Net::Nostr::Event> is a well-formed NIP-18 repost.
Croaks if:

=over

=item * Kind is not 6 or 16

=item * Missing C<e> tag

=item * C<e> tag missing relay URL

=back

    eval { Net::Nostr::Repost->validate($event) };
    warn "Invalid repost: $@" if $@;

=head1 ACCESSORS

These are available on objects returned by L</from_event>.

=head2 event_id

    my $id = $info->event_id;

The ID of the reposted event (from the C<e> tag).

=head2 relay_url

    my $url = $info->relay_url;

The relay URL where the reposted event can be fetched (from the C<e> tag).

=head2 author_pubkey

    my $pk = $info->author_pubkey;

The pubkey of the original event author (from the C<p> tag), or C<undef>.

=head2 reposted_kind

    my $kind = $info->reposted_kind;  # '30023'

The stringified kind of the reposted event (from the C<k> tag), or C<undef>.
Only present on kind 16 generic reposts.

=head2 event_coordinate

    my $coord = $info->event_coordinate;  # '30023:pubkey:d-tag'

The event coordinate (from the C<a> tag), or C<undef>. Only present when
reposting addressable events.

=head2 embedded_event

    my $event = $info->embedded_event;  # Net::Nostr::Event or undef

The reposted event parsed from the repost's content field. Returns C<undef>
if the content is empty or cannot be parsed as a valid event.

=head2 quote_event_id

    my $qid = $info->quote_event_id;  # event id or undef

The quoted event ID (from the C<q> tag), or C<undef>. Present only when
the repost is a quote repost.

=head1 SEE ALSO

L<NIP-18|https://github.com/nostr-protocol/nips/blob/master/18.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
