package Net::Nostr::Thread;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    root_id
    root_relay
    root_pubkey
    reply_id
    reply_relay
    reply_pubkey
    mentions
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    if (defined $self->{root_id}) {
        croak "root_id must be 64-char lowercase hex" unless $self->{root_id} =~ $HEX64;
    }
    if (defined $self->{reply_id}) {
        croak "reply_id must be 64-char lowercase hex" unless $self->{reply_id} =~ $HEX64;
    }
    $self->mentions($self->mentions // []);
    return $self;
}

sub reply {
    my ($class, %args) = @_;
    my $to      = $args{to}      // croak "reply requires 'to' (event being replied to)";
    my $pubkey  = $args{pubkey}  // croak "reply requires 'pubkey'";
    my $content = $args{content} // croak "reply requires 'content'";

    croak "kind 1 replies must only reply to kind 1 events (see NIP-22)"
        unless $to->kind == 1;

    # Find root from parent's e tags
    my $root_id;
    my $root_pubkey;
    my $root_relay = '';
    my $parent_thread = $class->from_event($to);

    if ($parent_thread) {
        $root_id     = $parent_thread->root_id;
        $root_relay  = $parent_thread->root_relay // '';
        $root_pubkey = $parent_thread->root_pubkey // '';
    }

    my $relay_url = $args{relay_url} // '';
    my @tags;

    if ($root_id) {
        # Replying to a reply: root + reply markers, sorted root first
        push @tags, ['e', $root_id, $root_relay, 'root', $root_pubkey // ''];
        push @tags, ['e', $to->id, $relay_url, 'reply', $to->pubkey];
    } else {
        # Direct reply to root: single "root" marker
        push @tags, ['e', $to->id, $relay_url, 'root', $to->pubkey];
    }

    # Collect p tags: parent's p tags + parent's pubkey, deduped, excluding self
    my %seen;
    my @p_tags;
    my @p_candidates;

    push @p_candidates, $to->pubkey;
    for my $tag (@{$to->tags}) {
        next unless @$tag >= 2 && $tag->[0] eq 'p';
        push @p_candidates, $tag->[1];
    }

    for my $pk (@p_candidates) {
        next if $pk eq $pubkey;  # don't include self
        next if $seen{$pk}++;
        push @p_tags, ['p', $pk];
    }

    push @tags, @p_tags;

    # Build the event, passing through extra args
    delete @args{qw(to relay_url)};
    return Net::Nostr::Event->new(%args, kind => 1, tags => \@tags);
}

sub quote {
    my ($class, %args) = @_;
    my $event     = $args{event}   // croak "quote requires 'event'";
    my $pubkey    = $args{pubkey}  // croak "quote requires 'pubkey'";
    my $content   = $args{content} // croak "quote requires 'content'";
    my $relay_url = $args{relay_url} // '';

    my @tags;
    push @tags, ['q', $event->id, $relay_url, $event->pubkey];

    # Add author as p tag (unless quoting self)
    if ($event->pubkey ne $pubkey) {
        push @tags, ['p', $event->pubkey];
    }

    delete @args{qw(event relay_url)};
    return Net::Nostr::Event->new(%args, kind => 1, tags => \@tags);
}

sub from_event {
    my ($class, $event) = @_;

    my @e_tags = grep { @$_ >= 2 && $_->[0] eq 'e' } @{$event->tags};
    return undef unless @e_tags;

    # Check for marked tags
    my ($root_tag, $reply_tag);
    for my $tag (@e_tags) {
        if (@$tag > 3 && defined $tag->[3] && $tag->[3] eq 'root') {
            $root_tag = $tag;
        } elsif (@$tag > 3 && defined $tag->[3] && $tag->[3] eq 'reply') {
            $reply_tag = $tag;
        }
    }

    if ($root_tag) {
        # Marked e tags (preferred)
        return $class->new(
            root_id      => $root_tag->[1],
            root_relay   => $root_tag->[2] // '',
            root_pubkey  => (@$root_tag > 4 ? ($root_tag->[4] // '') : ''),
            ($reply_tag ? (
                reply_id     => $reply_tag->[1],
                reply_relay  => $reply_tag->[2] // '',
                reply_pubkey => (@$reply_tag > 4 ? ($reply_tag->[4] // '') : ''),
            ) : ()),
        );
    }

    # Deprecated positional e tags
    if (@e_tags == 1) {
        return $class->new(
            root_id    => $e_tags[0][1],
            root_relay => $e_tags[0][2] // '',
        );
    }

    if (@e_tags == 2) {
        return $class->new(
            root_id     => $e_tags[0][1],
            root_relay  => $e_tags[0][2] // '',
            reply_id    => $e_tags[1][1],
            reply_relay => $e_tags[1][2] // '',
        );
    }

    # Many positional: first=root, last=reply, middle=mentions
    return $class->new(
        root_id     => $e_tags[0][1],
        root_relay  => $e_tags[0][2] // '',
        reply_id    => $e_tags[-1][1],
        reply_relay => $e_tags[-1][2] // '',
        mentions    => [map { $_->[1] } @e_tags[1 .. $#e_tags - 1]],
    );
}

sub is_reply {
    my ($class, $event) = @_;
    return defined $class->from_event($event) ? 1 : 0;
}

1;

__END__

=head1 NAME

Net::Nostr::Thread - NIP-10 text note threading

=head1 SYNOPSIS

    use Net::Nostr::Thread;

    # Create a direct reply to a root post
    my $reply = Net::Nostr::Thread->reply(
        to      => $root_event,
        pubkey  => $my_pubkey,
        content => 'Great post!',
    );

    # Create a reply to a reply
    my $deep_reply = Net::Nostr::Thread->reply(
        to        => $reply_event,
        pubkey    => $my_pubkey,
        content   => 'I agree',
        relay_url => 'wss://relay.example.com/',
    );

    # Quote an event
    my $quote = Net::Nostr::Thread->quote(
        event   => $original,
        pubkey  => $my_pubkey,
        content => 'Look at this nostr:nevent1...',
    );

    # Parse thread info from an event
    my $thread = Net::Nostr::Thread->from_event($event);
    if ($thread) {
        say "Root: " . $thread->root_id;
        say "Reply to: " . $thread->reply_id if $thread->reply_id;
    }

    # Check if an event is a reply
    say "is reply" if Net::Nostr::Thread->is_reply($event);

=head1 DESCRIPTION

Implements NIP-10 text note threading for kind 1 events. Provides methods
to create properly tagged reply and quote events, and to parse thread
structure from existing events.

Uses marked C<e> tags (preferred) with C<root> and C<reply> markers.
Also parses deprecated positional C<e> tags for backward compatibility.

=head1 CONSTRUCTOR

=head2 new

    my $thread = Net::Nostr::Thread->new(%fields);

Creates a new C<Net::Nostr::Thread> object.  Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $thread = Net::Nostr::Thread->new(
        root_id    => 'aa' x 32,
        root_relay => 'wss://relay.example.com',
    );

Accepted fields: C<root_id>, C<root_relay>, C<root_pubkey>,
C<reply_id>, C<reply_relay>, C<reply_pubkey>, C<mentions> (defaults
to C<[]>).

C<root_id> and C<reply_id> are validated as 64-character lowercase hex
strings. Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 reply

    my $event = Net::Nostr::Thread->reply(
        to         => $parent_event,
        pubkey     => $hex_pubkey,
        content    => 'reply text',
        relay_url  => 'wss://relay.com/',   # optional, defaults to ''
        created_at => time(),               # optional, passed to Event
    );

Creates a kind 1 reply event with proper marked C<e> tags and C<p> tags.
A direct reply to a root post gets a single C<e> tag with marker C<root>.
A reply to a reply gets two C<e> tags: C<root> and C<reply>, sorted by
reply stack (root first).

The reply's C<p> tags include the parent author and all of the parent's
C<p> tags, deduplicated, excluding the replier's own pubkey.

Croaks if the parent event is not kind 1 (use NIP-22 for other kinds).

    # Direct reply to root
    my $reply = Net::Nostr::Thread->reply(
        to => $root, pubkey => $pk, content => 'hello',
    );
    # tags: [['e', $root_id, '', 'root', $root_pubkey], ['p', $root_pubkey]]

    # Reply to a reply
    my $deep = Net::Nostr::Thread->reply(
        to => $mid_reply, pubkey => $pk, content => 'hi',
    );
    # tags: [['e', $root_id, '', 'root', ...], ['e', $mid_id, '', 'reply', ...], ...]

=head2 quote

    my $event = Net::Nostr::Thread->quote(
        event     => $quoted_event,
        pubkey    => $hex_pubkey,
        content   => 'look at this nostr:nevent1...',
        relay_url => 'wss://relay.com/',   # optional
    );

Creates a kind 1 event with a C<q> tag referencing the quoted event.
The quoted event's author is added as a C<p> tag unless the quoter
is the same pubkey (no self-reference).

    my $qt = Net::Nostr::Thread->quote(
        event => $original, pubkey => $pk, content => 'wow',
    );
    # tags: [['q', $original_id, '', $original_pubkey], ['p', $original_pubkey]]

=head2 from_event

    my $thread = Net::Nostr::Thread->from_event($event);

Parses thread structure from an event's C<e> tags. Returns a
C<Net::Nostr::Thread> object, or C<undef> if the event has no C<e> tags.

Prefers marked C<e> tags (with C<root>/C<reply> markers). Falls back to
deprecated positional parsing for unmarked tags.

    my $thread = Net::Nostr::Thread->from_event($event);
    say $thread->root_id;
    say $thread->reply_id if $thread->reply_id;

=head2 is_reply

    my $bool = Net::Nostr::Thread->is_reply($event);

Returns true if the event has any C<e> tags indicating it is a thread reply.

    if (Net::Nostr::Thread->is_reply($event)) {
        my $thread = Net::Nostr::Thread->from_event($event);
        ...
    }

=head1 ACCESSORS

=head2 root_id

    my $id = $thread->root_id;

The event ID of the thread root.

=head2 root_relay

    my $relay = $thread->root_relay;

Relay URL hint for the root event, or empty string.

=head2 root_pubkey

    my $pk = $thread->root_pubkey;

Public key of the root event author, if available.

=head2 reply_id

    my $id = $thread->reply_id;

The event ID of the direct parent, or C<undef> for direct replies to root.

=head2 reply_relay

    my $relay = $thread->reply_relay;

Relay URL hint for the parent event, or empty string.

=head2 reply_pubkey

    my $pk = $thread->reply_pubkey;

Public key of the parent event author, if available.

=head2 mentions

    my $ids = $thread->mentions;  # arrayref

Event IDs from deprecated positional C<e> tags that are neither root nor
reply (the "middle" tags). Empty arrayref for marked tags.

=head1 SEE ALSO

L<NIP-10|https://github.com/nostr-protocol/nips/blob/master/10.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
