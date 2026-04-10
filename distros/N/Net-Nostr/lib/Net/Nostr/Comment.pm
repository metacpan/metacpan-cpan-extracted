package Net::Nostr::Comment;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

use Class::Tiny qw(
    root_tag_name
    root_value
    root_relay
    root_kind
    root_pubkey
    parent_tag_name
    parent_value
    parent_relay
    parent_kind
    parent_pubkey
);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub comment {
    my ($class, %args) = @_;

    my $pubkey  = $args{pubkey}  // croak "comment requires 'pubkey'";
    my $content = $args{content} // croak "comment requires 'content'";
    my $event   = $args{event};
    my $ident   = $args{identifier};

    croak "pubkey must be 64-char lowercase hex" unless $pubkey =~ $HEX64;

    croak "comment requires 'event' or 'identifier'" unless $event || defined $ident;

    my @tags;

    if ($event) {
        croak "comments MUST NOT be used to reply to kind 1 notes (see NIP-10)"
            if $event->kind == 1;

        my $relay = $args{relay_url} // '';
        my $kind_str = '' . $event->kind;

        if ($event->is_addressable) {
            my $coord = $event->kind . ':' . $event->pubkey . ':' . $event->d_tag;

            # Root scope
            push @tags, ['A', $coord, $relay];
            push @tags, ['K', $kind_str];
            push @tags, ['P', $event->pubkey, $relay];

            # Parent (same as root for top-level)
            push @tags, ['a', $coord, $relay];
            push @tags, ['e', $event->id, $relay];
            push @tags, ['k', $kind_str];
            push @tags, ['p', $event->pubkey, $relay];
        } else {
            # Regular or replaceable event -- use E/e tags
            push @tags, ['E', $event->id, $relay, $event->pubkey];
            push @tags, ['K', $kind_str];
            push @tags, ['P', $event->pubkey, $relay];

            push @tags, ['e', $event->id, $relay, $event->pubkey];
            push @tags, ['k', $kind_str];
            push @tags, ['p', $event->pubkey, $relay];
        }
    } else {
        # External identifier
        my $kind = $args{kind} // croak "comment on identifier requires 'kind'";
        my $hint = $args{hint};

        my @i_parts = ($ident);
        push @i_parts, $hint if defined $hint;

        push @tags, ['I', @i_parts];
        push @tags, ['K', $kind];

        push @tags, ['i', @i_parts];
        push @tags, ['k', $kind];
    }

    # MAY: q tags for quoting
    if ($args{quotes}) {
        for my $q (@{$args{quotes}}) {
            croak "quote id must be 64-char lowercase hex" unless defined $q->{id} && $q->{id} =~ $HEX64;
            croak "quote pubkey must be 64-char lowercase hex"
                if defined $q->{pubkey} && length($q->{pubkey}) && $q->{pubkey} !~ $HEX64;
            push @tags, ['q', $q->{id}, $q->{relay_url} // '', $q->{pubkey} // ''];
        }
    }

    # SHOULD: p tags for mentions
    if ($args{mentions}) {
        for my $pk (@{$args{mentions}}) {
            croak "mention pubkey must be 64-char lowercase hex" unless $pk =~ $HEX64;
            push @tags, ['p', $pk];
        }
    }

    delete @args{qw(event identifier kind relay_url hint quotes mentions)};
    return Net::Nostr::Event->new(%args, kind => 1111, tags => \@tags);
}

sub reply {
    my ($class, %args) = @_;

    my $to      = $args{to}      // croak "reply requires 'to'";
    my $pubkey  = $args{pubkey}  // croak "reply requires 'pubkey'";
    my $content = $args{content} // croak "reply requires 'content'";
    my $relay   = $args{relay_url} // '';

    croak "pubkey must be 64-char lowercase hex" unless $pubkey =~ $HEX64;

    # Extract root scope from parent's uppercase tags
    my @tags;
    for my $tag (@{$to->tags}) {
        my $name = $tag->[0];
        if ($name eq 'E' || $name eq 'A' || $name eq 'I' || $name eq 'K' || $name eq 'P') {
            push @tags, [@$tag];
        }
    }

    # Parent points to the comment event
    push @tags, ['e', $to->id, $relay, $to->pubkey];
    push @tags, ['k', '1111'];
    push @tags, ['p', $to->pubkey, $relay];

    # MAY: q tags
    if ($args{quotes}) {
        for my $q (@{$args{quotes}}) {
            croak "quote id must be 64-char lowercase hex" unless defined $q->{id} && $q->{id} =~ $HEX64;
            croak "quote pubkey must be 64-char lowercase hex"
                if defined $q->{pubkey} && length($q->{pubkey}) && $q->{pubkey} !~ $HEX64;
            push @tags, ['q', $q->{id}, $q->{relay_url} // '', $q->{pubkey} // ''];
        }
    }

    # SHOULD: mentions
    if ($args{mentions}) {
        for my $pk (@{$args{mentions}}) {
            croak "mention pubkey must be 64-char lowercase hex" unless $pk =~ $HEX64;
            push @tags, ['p', $pk];
        }
    }

    delete @args{qw(to relay_url quotes mentions)};
    return Net::Nostr::Event->new(%args, kind => 1111, tags => \@tags);
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 1111;

    my (%root, %parent, $root_kind, $parent_kind, $root_pubkey, $parent_pubkey);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'E' || $name eq 'A' || $name eq 'I') {
            %root = (tag_name => $name, value => $tag->[1], relay => $tag->[2] // '');
        } elsif ($name eq 'e' || $name eq 'a' || $name eq 'i') {
            %parent = (tag_name => $name, value => $tag->[1], relay => $tag->[2] // '');
        } elsif ($name eq 'K') {
            $root_kind = $tag->[1];
        } elsif ($name eq 'k') {
            $parent_kind = $tag->[1];
        } elsif ($name eq 'P') {
            $root_pubkey = $tag->[1];
        } elsif ($name eq 'p') {
            $parent_pubkey //= $tag->[1];
        }
    }

    return undef unless %root || %parent;

    return $class->new(
        root_tag_name   => $root{tag_name},
        root_value      => $root{value},
        root_relay      => $root{relay},
        root_kind       => $root_kind,
        root_pubkey     => $root_pubkey,
        parent_tag_name => $parent{tag_name},
        parent_value    => $parent{value},
        parent_relay    => $parent{relay},
        parent_kind     => $parent_kind,
        parent_pubkey   => $parent_pubkey,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "comment MUST be kind 1111" unless $event->kind == 1111;

    my ($has_root, $has_parent, $has_K, $has_k);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        $has_root   = 1 if $name eq 'E' || $name eq 'A' || $name eq 'I';
        $has_parent = 1 if $name eq 'e' || $name eq 'a' || $name eq 'i';
        $has_K      = 1 if $name eq 'K';
        $has_k      = 1 if $name eq 'k';
    }

    croak "comment MUST have a root scope tag (E, A, or I)" unless $has_root;
    croak "comment MUST have a parent scope tag (e, a, or i)" unless $has_parent;
    croak "comment MUST have a K tag (root kind)" unless $has_K;
    croak "comment MUST have a k tag (parent kind)" unless $has_k;

    return 1;
}

1;

__END__

=head1 NAME

Net::Nostr::Comment - NIP-22 comment threading

=head1 SYNOPSIS

    use Net::Nostr::Comment;

    # Comment on a nostr event (regular or addressable)
    my $comment = Net::Nostr::Comment->comment(
        event     => $blog_post,
        pubkey    => $my_pubkey,
        content   => 'Great blog post!',
        relay_url => 'wss://relay.example.com',
    );

    # Comment on an external identifier (URL, podcast, etc.)
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'https://abc.com/articles/1',
        kind       => 'web',
        pubkey     => $my_pubkey,
        content    => 'Nice article!',
    );

    # Reply to an existing comment
    my $reply = Net::Nostr::Comment->reply(
        to        => $parent_comment,
        pubkey    => $my_pubkey,
        content   => 'I agree!',
        relay_url => 'wss://relay.example.com',
    );

    # Parse comment structure from an event
    my $info = Net::Nostr::Comment->from_event($event);
    if ($info) {
        say "Root kind: " . $info->root_kind;
        say "Parent kind: " . $info->parent_kind;
    }

    # Validate a comment event
    Net::Nostr::Comment->validate($event);

=head1 DESCRIPTION

Implements NIP-22 comment threading for kind 1111 events. Comments are
plaintext threading notes scoped to a root event or external identifier.

Comments use uppercase tags (C<E>, C<A>, C<I>, C<K>, C<P>) for the root
scope and lowercase tags (C<e>, C<a>, C<i>, C<k>, C<p>) for the parent
item. For top-level comments, root and parent point to the same target.

Comments MUST NOT be used to reply to kind 1 notes; use
L<Net::Nostr::Thread> (NIP-10) instead.

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Comment->new(%fields);

Creates a new C<Net::Nostr::Comment> object. Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Comment->new(
        root_tag_name => 'E',
        root_kind     => '30023',
        root_value    => 'abc123',
        root_pubkey   => $hex_pubkey,
    );

Accepted fields: C<root_tag_name>, C<root_value>, C<root_relay>,
C<root_kind>, C<root_pubkey>, C<parent_tag_name>, C<parent_value>,
C<parent_relay>, C<parent_kind>, C<parent_pubkey>.
Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 comment

    my $event = Net::Nostr::Comment->comment(
        event      => $target_event,       # nostr event to comment on
        pubkey     => $hex_pubkey,
        content    => 'comment text',
        relay_url  => 'wss://relay.com/',  # optional, defaults to ''
        quotes     => [{id => $eid, relay_url => $r, pubkey => $pk}],  # optional
        mentions   => [$pubkey1],          # optional
        created_at => time(),              # optional, passed to Event
    );

    my $event = Net::Nostr::Comment->comment(
        identifier => 'https://example.com/article',
        kind       => 'web',
        pubkey     => $hex_pubkey,
        content    => 'comment text',
        hint       => 'https://...',       # optional hint for I/i tags
    );

Creates a kind 1111 comment event. Pass C<event> for nostr events or
C<identifier> and C<kind> for external identifiers (URLs, podcasts, etc.).

For addressable events (kinds 30000-39999), generates C<A>/C<a> tags with
the event coordinate and an additional C<e> tag referencing the event ID.
For regular events, generates C<E>/C<e> tags. Tags C<K>/C<k> are always
included with the target kind, and C<P>/C<p> tags include the author pubkey
for nostr events.

Croaks if the target is a kind 1 event (use L<Net::Nostr::Thread> instead).

    # Comment on a NIP-94 file event
    my $comment = Net::Nostr::Comment->comment(
        event   => $file_event,
        pubkey  => $my_pk,
        content => 'Great file!',
    );

    # Comment on a podcast episode
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'podcast:item:guid:d98d189b-...',
        kind       => 'podcast:item:guid',
        pubkey     => $my_pk,
        content    => 'Great episode!',
        hint       => 'https://fountain.fm/episode/...',
    );

=head2 reply

    my $event = Net::Nostr::Comment->reply(
        to         => $parent_comment,
        pubkey     => $hex_pubkey,
        content    => 'reply text',
        relay_url  => 'wss://relay.com/',  # optional
        quotes     => [...],               # optional
        mentions   => [...],               # optional
    );

Creates a kind 1111 reply to an existing comment. The root scope tags
(C<E>/C<A>/C<I>, C<K>, C<P>) are preserved from the parent comment's
uppercase tags. The parent tags point to the comment being replied to
with C<k> set to C<1111>.

    my $reply = Net::Nostr::Comment->reply(
        to      => $comment_event,
        pubkey  => $my_pk,
        content => 'I agree!',
    );

=head2 from_event

    my $info = Net::Nostr::Comment->from_event($event);

Parses comment structure from a kind 1111 event. Returns a
C<Net::Nostr::Comment> object with accessors for root and parent scope,
or C<undef> if the event is not kind 1111.

    my $info = Net::Nostr::Comment->from_event($event);
    say $info->root_kind;       # '30023'
    say $info->parent_kind;     # '1111' (if replying to a comment)
    say $info->root_pubkey;     # root event author, or undef

=head2 validate

    Net::Nostr::Comment->validate($event);

Validates that an event is a well-formed NIP-22 comment. Croaks if:

=over

=item * Kind is not 1111

=item * Missing root scope tag (C<E>, C<A>, or C<I>)

=item * Missing parent scope tag (C<e>, C<a>, or C<i>)

=item * Missing C<K> tag (root kind)

=item * Missing C<k> tag (parent kind)

=back

    eval { Net::Nostr::Comment->validate($event) };
    warn "Invalid comment: $@" if $@;

=head1 ACCESSORS

These are available on objects returned by L</from_event>.

=head2 root_tag_name

    my $name = $info->root_tag_name;  # 'E', 'A', or 'I'

The tag name used for the root scope.

=head2 root_value

    my $val = $info->root_value;

The root scope value (event ID, event coordinate, or external identifier).

=head2 root_relay

    my $relay = $info->root_relay;

Relay or web page hint for the root scope, or empty string.

=head2 root_kind

    my $kind = $info->root_kind;  # '30023', '1063', 'web', etc.

The C<K> tag value identifying the root item kind.

=head2 root_pubkey

    my $pk = $info->root_pubkey;  # or undef for external identifiers

The C<P> tag pubkey of the root event author, or C<undef> if not available
(e.g. for external identifiers).

=head2 parent_tag_name

    my $name = $info->parent_tag_name;  # 'e', 'a', or 'i'

The tag name used for the parent item.

=head2 parent_value

    my $val = $info->parent_value;

The parent item value.

=head2 parent_relay

    my $relay = $info->parent_relay;

Relay hint for the parent item, or empty string.

=head2 parent_kind

    my $kind = $info->parent_kind;  # '1111' for replies to comments

The C<k> tag value identifying the parent item kind.

=head2 parent_pubkey

    my $pk = $info->parent_pubkey;

The C<p> tag pubkey of the parent item author, or C<undef>.

=head1 SEE ALSO

L<NIP-22|https://github.com/nostr-protocol/nips/blob/master/22.md>,
L<Net::Nostr::Thread>, L<Net::Nostr>, L<Net::Nostr::Event>

=cut
