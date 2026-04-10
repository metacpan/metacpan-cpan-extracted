package Net::Nostr::Reaction;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

use Class::Tiny qw(
    event_id
    relay_url
    author_pubkey
    content
    reacted_kind
    event_coordinate
);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub react {
    my ($class, %args) = @_;

    my $event     = $args{event}     // croak "react requires 'event'";
    my $pubkey    = $args{pubkey}    // croak "react requires 'pubkey'";
    my $relay_url = $args{relay_url} // croak "react requires 'relay_url'";
    my $content   = exists $args{content} ? $args{content} : '+';

    my $eid = $event->id;
    croak "event_id must be 64-char lowercase hex" unless $eid =~ $HEX64;
    my $apk = $event->pubkey;
    croak "author_pubkey must be 64-char lowercase hex" unless $apk =~ $HEX64;

    my @tags;

    # MUST: e tag with relay and pubkey hints
    push @tags, ['e', $event->id, $relay_url, $event->pubkey];

    # SHOULD: p tag with relay hint
    push @tags, ['p', $event->pubkey, $relay_url];

    # MAY: k tag with stringified kind
    push @tags, ['k', '' . $event->kind];

    # SHOULD: a tag for addressable events with relay and pubkey hints
    if ($event->is_addressable) {
        my $coord = $event->kind . ':' . $event->pubkey . ':' . $event->d_tag;
        push @tags, ['a', $coord, $relay_url, $event->pubkey];
    }

    # MAY: emoji tag for custom emoji reactions (NIP-30)
    if ($args{emoji}) {
        push @tags, ['emoji', @{$args{emoji}}];
    }

    delete @args{qw(event relay_url content emoji)};
    return Net::Nostr::Event->new(%args, kind => 7, content => $content, tags => \@tags);
}

sub react_external {
    my ($class, %args) = @_;

    my $pubkey  = $args{pubkey}  // croak "react_external requires 'pubkey'";
    my $content = $args{content} // croak "react_external requires 'content'";
    my $tags    = $args{tags}    // croak "react_external requires 'tags'";

    delete @args{qw(tags content)};
    return Net::Nostr::Event->new(%args, kind => 17, content => $content, tags => $tags);
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 7 || $event->kind == 17;

    my ($event_id, $relay_url, $author_pubkey, $reacted_kind, $event_coordinate);

    # e and p: spec says target should be last if multiple exist
    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        my $name = $tag->[0];
        if ($name eq 'e') {
            $event_id      = $tag->[1];
            $relay_url     = @$tag > 2 ? ($tag->[2] // '') : '';
            $author_pubkey = $tag->[3] if @$tag > 3 && defined $tag->[3];
        } elsif ($name eq 'p') {
            $author_pubkey = $tag->[1];
        } elsif ($name eq 'k' && !defined $reacted_kind) {
            $reacted_kind = $tag->[1];
        } elsif ($name eq 'a' && !defined $event_coordinate) {
            $event_coordinate = $tag->[1];
        }
    }

    return $class->new(
        event_id         => $event_id,
        relay_url        => $relay_url,
        author_pubkey    => $author_pubkey,
        content          => $event->content,
        reacted_kind     => $reacted_kind,
        event_coordinate => $event_coordinate,
    );
}

sub is_like {
    my ($self) = @_;
    my $c = $self->content;
    return defined $c && ($c eq '+' || $c eq '');
}

sub is_dislike {
    my ($self) = @_;
    my $c = $self->content;
    return defined $c && $c eq '-';
}

sub validate {
    my ($class, $event) = @_;

    croak "reaction MUST be kind 7 or 17" unless $event->kind == 7 || $event->kind == 17;

    if ($event->kind == 7) {
        my $has_e = grep { $_->[0] eq 'e' } @{$event->tags};
        croak "kind 7 reaction MUST include an e tag" unless $has_e;
    } elsif ($event->kind == 17) {
        my $has_k = grep { $_->[0] eq 'k' } @{$event->tags};
        my $has_i = grep { $_->[0] eq 'i' } @{$event->tags};
        croak "kind 17 reaction MUST include k and i tags" unless $has_k && $has_i;
    }

    return 1;
}

1;

__END__

=head1 NAME

Net::Nostr::Reaction - NIP-25 reactions

=head1 SYNOPSIS

    use Net::Nostr::Reaction;

    # Like a note (default content is +)
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $my_pubkey,
        relay_url => 'wss://relay.example.com',
    );

    # Dislike
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $my_pubkey,
        relay_url => 'wss://relay.example.com',
        content   => '-',
    );

    # Emoji reaction
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $my_pubkey,
        relay_url => 'wss://relay.example.com',
        content   => "\x{1F44D}",
    );

    # Custom emoji reaction (NIP-30)
    my $reaction = Net::Nostr::Reaction->react(
        event     => $note,
        pubkey    => $my_pubkey,
        relay_url => 'wss://relay.example.com',
        content   => ':soapbox:',
        emoji     => ['soapbox', 'https://gleasonator.com/emoji/Gleasonator/soapbox.png'],
    );

    # React to external content (kind 17)
    my $reaction = Net::Nostr::Reaction->react_external(
        pubkey  => $my_pubkey,
        content => "\x{2B50}",
        tags    => [
            ['k', 'web'],
            ['i', 'https://example.com'],
        ],
    );

    # Parse reaction from an event
    my $info = Net::Nostr::Reaction->from_event($event);
    if ($info) {
        say $info->is_like ? "Liked" : $info->content;
    }

    # Validate a reaction event
    Net::Nostr::Reaction->validate($event);

=head1 DESCRIPTION

Implements NIP-25 reactions. A reaction is a kind 7 event used to react to
other nostr events. The content field indicates the reaction value:
C<+> or empty string for a "like", C<-> for a "dislike", or an emoji
(including L<NIP-30|https://github.com/nostr-protocol/nips/blob/master/30.md>
custom emoji) for an emoji reaction. Emoji reactions SHOULD NOT be
interpreted as likes or dislikes.

Tags include an C<e> tag with the reacted event's ID (MUST), a C<p> tag
with the author's pubkey (SHOULD), a C<k> tag with the stringified kind
(MAY), and for addressable events an C<a> tag with the event coordinate
(SHOULD). The C<e> and C<a> tags SHOULD include relay and pubkey hints.
The C<p> tag SHOULD include a relay hint. If multiple C<e> or C<p> tags
are present, the target event's ID and pubkey should be last.

External content reactions (websites, podcasts, etc.) use kind 17 with
L<NIP-73|https://github.com/nostr-protocol/nips/blob/master/73.md>
C<k> and C<i> tags instead of C<e> tags.

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Reaction->new(%fields);

Creates a new C<Net::Nostr::Reaction> object.  Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Reaction->new(
        event_id => 'aa' x 32,
        content  => '+',
    );

Accepted fields: C<event_id>, C<relay_url>, C<author_pubkey>,
C<content>, C<reacted_kind>, C<event_coordinate>.
Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 react

    my $event = Net::Nostr::Reaction->react(
        event      => $original_event,    # Net::Nostr::Event to react to
        pubkey     => $hex_pubkey,        # reactor's hex pubkey
        relay_url  => 'wss://relay.example.com',
        content    => '+',                # optional, default '+'
        emoji      => ['name', 'url'],    # optional, NIP-30 custom emoji
        created_at => time(),             # optional, passed to Event
    );

Creates a kind 7 reaction L<Net::Nostr::Event>. The C<event> parameter is
the L<Net::Nostr::Event> being reacted to. The C<pubkey> is the reactor's
hex public key.

The content defaults to C<+> (like). Pass C<-> for dislike, an emoji for
emoji reaction, or a C<:shortcode:> with the C<emoji> parameter for a
L<NIP-30|https://github.com/nostr-protocol/nips/blob/master/30.md> custom
emoji reaction.

Returns a L<Net::Nostr::Event> with kind 7 and the appropriate tags.

Croaks if C<event>, C<pubkey>, or C<relay_url> is missing.

=head2 react_external

    my $event = Net::Nostr::Reaction->react_external(
        pubkey  => $hex_pubkey,
        content => "\x{2B50}",
        tags    => [
            ['k', 'web'],
            ['i', 'https://example.com'],
        ],
    );

Creates a kind 17 external content reaction L<Net::Nostr::Event>. The
C<tags> must include L<NIP-73|https://github.com/nostr-protocol/nips/blob/master/73.md>
C<k> and C<i> tags to reference the external content.

Returns a L<Net::Nostr::Event> with kind 17.

Croaks if C<pubkey>, C<content>, or C<tags> is missing.

=head2 from_event

    my $info = Net::Nostr::Reaction->from_event($event);

Parses reaction structure from a kind 7 or kind 17 L<Net::Nostr::Event>.
Returns a C<Net::Nostr::Reaction> object with accessors, or C<undef> if
the event is not a reaction kind.

    my $info = Net::Nostr::Reaction->from_event($event);
    say $info->is_like ? "Liked" : $info->content;

=head2 validate

    Net::Nostr::Reaction->validate($event);

Validates that a L<Net::Nostr::Event> is a well-formed NIP-25 reaction.
Croaks if:

=over

=item * Kind is not 7 or 17

=item * Kind 7 missing C<e> tag

=item * Kind 17 missing C<k> or C<i> tags

=back

    eval { Net::Nostr::Reaction->validate($event) };
    warn "Invalid reaction: $@" if $@;

=head1 INSTANCE METHODS

=head2 is_like

    $info->is_like;  # true for '+' or ''

Returns true if the reaction content is C<+> or an empty string.

=head2 is_dislike

    $info->is_dislike;  # true for '-'

Returns true if the reaction content is C<->.

=head1 ACCESSORS

These are available on objects returned by L</from_event>.

=head2 event_id

    my $id = $info->event_id;

The ID of the reacted event (from the C<e> tag), or C<undef> for kind 17.

=head2 relay_url

    my $url = $info->relay_url;

The relay URL hint (from the C<e> tag), or C<undef>.

=head2 author_pubkey

    my $pk = $info->author_pubkey;

The pubkey of the reacted event's author (from the C<e> or C<p> tag), or
C<undef>.

=head2 content

    my $c = $info->content;  # '+', '-', emoji, or ':shortcode:'

The reaction content.

=head2 reacted_kind

    my $kind = $info->reacted_kind;  # '1' or 'web'

The stringified kind of the reacted event (from the C<k> tag), or C<undef>.

=head2 event_coordinate

    my $coord = $info->event_coordinate;  # '30023:pubkey:d-tag'

The event coordinate (from the C<a> tag), or C<undef>. Only present when
reacting to addressable events.

=head1 SEE ALSO

L<NIP-25|https://github.com/nostr-protocol/nips/blob/master/25.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
