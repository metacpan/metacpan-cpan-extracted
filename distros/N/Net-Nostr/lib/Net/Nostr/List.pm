package Net::Nostr::List;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;
use Net::Nostr::Encryption;

use Class::Tiny qw(kind identifier title image description _items _private_items);

my $JSON = JSON->new->utf8;

# Metadata tag names that are not list items
my %META_TAGS = map { $_ => 1 } qw(d title image description);

sub new {
    my ($class, %args) = @_;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    croak "new requires 'kind'" unless defined $args{kind};
    my $self = bless {}, $class;
    $self->kind($args{kind});
    $self->identifier($args{identifier} // '');
    $self->_items([]);
    $self->_private_items([]);
    return $self;
}

sub add {
    my ($self, @tag) = @_;
    croak "add requires at least one argument" unless @tag;
    push @{$self->_items}, \@tag;
    return $self;
}

sub add_private {
    my ($self, @tag) = @_;
    croak "add_private requires at least one argument" unless @tag;
    push @{$self->_private_items}, \@tag;
    return $self;
}

sub items {
    my ($self) = @_;
    return [@{$self->_items}];
}

sub private_items {
    my ($self) = @_;
    return [@{$self->_private_items}];
}

sub to_event {
    my ($self, %args) = @_;
    my $pubkey = $args{pubkey} // croak "to_event requires 'pubkey'";
    my $key = $args{key};

    my @tags;

    # For addressable events (sets), add d tag first
    if ($self->_is_set) {
        push @tags, ['d', $self->identifier];
        push @tags, ['title', $self->title] if defined $self->title;
        push @tags, ['image', $self->image] if defined $self->image;
        push @tags, ['description', $self->description] if defined $self->description;
    }

    # Add public items
    push @tags, @{$self->_items};

    # Encrypt private items
    my $content = '';
    if (@{$self->_private_items}) {
        croak "to_event requires 'key' when private items exist" unless $key;
        my $plaintext = $JSON->encode($self->_private_items);
        my $conv_key = Net::Nostr::Encryption->get_conversation_key(
            $key->privkey_hex, $key->pubkey_hex,
        );
        $content = Net::Nostr::Encryption->encrypt($plaintext, $conv_key);
    }

    delete @args{qw(key)};
    return Net::Nostr::Event->new(%args, kind => $self->kind, tags => \@tags, content => $content);
}

sub from_event {
    my ($class, $event, %args) = @_;
    my $key = $args{key};

    my $self = $class->new(kind => $event->kind);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'd') {
            $self->identifier($tag->[1] // '');
        } elsif ($name eq 'title') {
            $self->title($tag->[1]);
        } elsif ($name eq 'image') {
            $self->image($tag->[1]);
        } elsif ($name eq 'description') {
            $self->description($tag->[1]);
        } else {
            push @{$self->_items}, [@$tag];
        }
    }

    # Decrypt private items if key provided and content is non-empty
    if ($key && defined $event->content && length($event->content) > 0) {
        croak "NIP-04 encrypted content is not supported (deprecated); re-encrypt with NIP-44"
            if $event->content =~ /\?iv=/;
        my $conv_key = Net::Nostr::Encryption->get_conversation_key(
            $key->privkey_hex, $key->pubkey_hex,
        );
        my $plaintext = Net::Nostr::Encryption->decrypt($event->content, $conv_key);
        my $private = $JSON->decode($plaintext);
        $self->_private_items($private);
    }

    return $self;
}

sub _is_set {
    my ($self) = @_;
    my $k = $self->kind;
    return ($k >= 30000 && $k < 40000);
}

1;

__END__

=head1 NAME

Net::Nostr::List - NIP-51 lists and sets

=head1 SYNOPSIS

    use Net::Nostr::List;
    use Net::Nostr::Key;

    my $key = Net::Nostr::Key->new;

    # Create a mute list (kind 10000) with public and private items
    my $mute = Net::Nostr::List->new(kind => 10000);
    $mute->add('p', $spammer_pubkey);
    $mute->add('t', 'bitcoin');
    $mute->add('word', 'gm');
    $mute->add_private('p', $secret_mute_pubkey);

    my $event = $mute->to_event(pubkey => $key->pubkey_hex, key => $key);
    $key->sign_event($event);
    $client->publish($event);

    # Create a pinned notes list (kind 10001)
    my $pins = Net::Nostr::List->new(kind => 10001);
    $pins->add('e', $note_id_1);
    $pins->add('e', $note_id_2);
    my $event = $pins->to_event(pubkey => $key->pubkey_hex);

    # Create a bookmark set (kind 30003) with metadata
    my $bookmarks = Net::Nostr::List->new(kind => 30003, identifier => 'articles');
    $bookmarks->title('Saved Articles');
    $bookmarks->image('https://example.com/books.png');
    $bookmarks->description('Articles I want to read later');
    $bookmarks->add('a', "30023:$author:my-article");
    $bookmarks->add('e', $note_id);

    my $event = $bookmarks->to_event(pubkey => $key->pubkey_hex);

    # Create a relay set (kind 30002)
    my $relays = Net::Nostr::List->new(kind => 30002, identifier => 'fast');
    $relays->title('Fast Relays');
    $relays->add('relay', 'wss://relay1.com');
    $relays->add('relay', 'wss://relay2.com');

    # Parse a received list event (public items only)
    my $list = Net::Nostr::List->from_event($event);
    for my $item (@{$list->items}) {
        say join(', ', @$item);
    }

    # Parse with decryption of private items
    my $list = Net::Nostr::List->from_event($event, key => $key);
    for my $item (@{$list->private_items}) {
        say "private: " . join(', ', @$item);
    }

=head1 DESCRIPTION

Implements NIP-51 lists. Lists are events whose tags represent references
to things (pubkeys, events, relays, hashtags, etc.). Items can be
B<public> (in the event tags) or B<private> (encrypted in the event
content using NIP-44).

There are two categories of lists:

=over 4

=item B<Standard lists> (kinds 10000-19999)

Replaceable events. A user may only have one list of each kind. Examples:
mute list (10000), pinned notes (10001), bookmarks (10003).

=item B<Sets> (kinds 30000-39999)

Addressable events identified by a C<d> tag. Users can have multiple sets
of each kind. Sets can have optional C<title>, C<image>, and C<description>
tags. Examples: relay sets (30002), curation sets (30004).

=back

This module is deliberately generic: it accepts any kind and any tag types
without enforcing kind-specific rules. NIP-51 defines the list structure,
but individual NIPs (e.g. NIP-34 for git-related lists) assign meaning to
specific kind numbers and tag types. Validation of which tags are
appropriate for a given kind is left to the caller.

=head1 CONSTRUCTOR

=head2 new

    my $list = Net::Nostr::List->new(kind => 10000);
    my $set  = Net::Nostr::List->new(kind => 30002, identifier => 'my-relays');

Creates a new empty list. C<kind> is required. C<identifier> sets the
C<d> tag value for sets (defaults to empty string). Croaks on unknown
arguments.

=head2 from_event

    my $list = Net::Nostr::List->from_event($event);
    my $list = Net::Nostr::List->from_event($event, key => $key);

Parses a list from an existing event. Public items are extracted from
the event tags. If a L<Net::Nostr::Key> is provided, private items
are decrypted from the event content using NIP-44. Croaks if the
content uses deprecated NIP-04 encryption.

    my $list = Net::Nostr::List->from_event($mute_event, key => $my_key);
    say scalar @{$list->private_items};  # number of privately muted items

=head1 METHODS

=head2 add

    $list->add('p', $pubkey);
    $list->add('relay', 'wss://relay.com');
    $list->add('p', $pubkey, 'wss://hint.com', 'petname');

Appends a public item to the list. Arguments become a tag array.
Returns C<$self> for chaining. New items are appended to the end
of the list to preserve chronological order.

    $list->add('p', $pk1)->add('p', $pk2)->add('t', 'nostr');

=head2 add_private

    $list->add_private('p', $pubkey);
    $list->add_private('word', 'spam');

Appends a private item to the list. Private items are encrypted
in the event content when C<to_event> is called. Returns C<$self>
for chaining.

    $list->add_private('p', $secret1)->add_private('p', $secret2);

=head2 items

    my $items = $list->items;  # arrayref of arrayrefs

Returns a copy of the public items. Each item is an arrayref
matching the tag structure (e.g. C<['p', $pubkey]>).

    for my $item (@{$list->items}) {
        say "tag: $item->[0], value: $item->[1]";
    }

=head2 private_items

    my $items = $list->private_items;  # arrayref of arrayrefs

Returns a copy of the private items. Empty if no private items
exist or if the list was parsed without a decryption key.

    my $list = Net::Nostr::List->from_event($event, key => $key);
    for my $item (@{$list->private_items}) {
        say "private: $item->[0] = $item->[1]";
    }

=head2 kind

    my $kind = $list->kind;

Returns the event kind for this list.

=head2 identifier

    my $id = $list->identifier;
    $list->identifier('my-set');

Gets or sets the C<d> tag value for sets. Only meaningful for
addressable event kinds (30000-39999).

=head2 title

    my $title = $list->title;
    $list->title('My Collection');

Gets or sets the optional title for sets.

    my $set = Net::Nostr::List->new(kind => 30004, identifier => 'yaks');
    $set->title('Yaks');

=head2 image

    my $url = $list->image;
    $list->image('https://example.com/pic.png');

Gets or sets the optional image URL for sets.

=head2 description

    my $desc = $list->description;
    $list->description('A curated collection of yak-related content');

Gets or sets the optional description for sets.

=head2 to_event

    my $event = $list->to_event(pubkey => $hex_pubkey);
    my $event = $list->to_event(pubkey => $hex_pubkey, key => $key);

Creates a L<Net::Nostr::Event> from the list. Public items become
event tags. If private items exist, a L<Net::Nostr::Key> must be
provided to encrypt them into the event content using NIP-44.
Extra arguments are passed through to the Event constructor.

    my $event = $list->to_event(
        pubkey     => $key->pubkey_hex,
        key        => $key,
        created_at => time(),
    );
    $key->sign_event($event);

=head1 SEE ALSO

L<NIP-51|https://github.com/nostr-protocol/nips/blob/master/51.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Encryption>

=cut
