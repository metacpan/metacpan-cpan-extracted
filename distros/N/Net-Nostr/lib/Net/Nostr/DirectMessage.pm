package Net::Nostr::DirectMessage;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;
use Net::Nostr::GiftWrap;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub create {
    my ($class, %args) = @_;
    my $sender_pubkey = $args{sender_pubkey} // croak "sender_pubkey required";
    my $content       = $args{content}       // croak "content required";
    my $recipients    = $args{recipients}    // croak "recipients required";
    my $reply_to      = $args{reply_to};
    my $subject       = $args{subject};
    my $quotes        = $args{quotes};

    my @tags;
    for my $r (@$recipients) {
        my $pk = ref $r eq 'ARRAY' ? $r->[0] : $r;
        croak "recipient pubkey must be 64-char lowercase hex" unless $pk =~ $HEX64;
        if (ref $r eq 'ARRAY') {
            push @tags, ['p', @$r];
        } else {
            push @tags, ['p', $r];
        }
    }
    if (defined $reply_to) {
        my $eid = ref $reply_to eq 'ARRAY' ? $reply_to->[0] : $reply_to;
        croak "reply_to must be 64-char lowercase hex" unless $eid =~ $HEX64;
        if (ref $reply_to eq 'ARRAY') {
            push @tags, ['e', @$reply_to];
        } else {
            push @tags, ['e', $reply_to];
        }
    }
    push @tags, ['subject', $subject] if defined $subject;
    if ($quotes) {
        for my $q (@$quotes) {
            croak "quote event_id must be 64-char lowercase hex" unless $q->[0] =~ $HEX64;
            push @tags, ['q', @$q];
        }
    }

    return Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender_pubkey,
        kind    => 14,
        content => $content,
        tags    => \@tags,
    );
}

sub create_file {
    my ($class, %args) = @_;
    my $sender_pubkey        = $args{sender_pubkey}        // croak "sender_pubkey required";
    my $content              = $args{content}              // croak "content required";
    my $recipients           = $args{recipients}           // croak "recipients required";
    my $file_type            = $args{file_type}            // croak "file_type required";
    my $encryption_algorithm = $args{encryption_algorithm} // croak "encryption_algorithm required";
    my $decryption_key       = $args{decryption_key}       // croak "decryption_key required";
    my $decryption_nonce     = $args{decryption_nonce}     // croak "decryption_nonce required";
    my $x                    = $args{x}                    // croak "x required";

    my @tags;
    for my $r (@$recipients) {
        my $pk = ref $r eq 'ARRAY' ? $r->[0] : $r;
        croak "recipient pubkey must be 64-char lowercase hex" unless $pk =~ $HEX64;
        if (ref $r eq 'ARRAY') {
            push @tags, ['p', @$r];
        } else {
            push @tags, ['p', $r];
        }
    }
    if (defined $args{reply_to}) {
        my $eid = ref $args{reply_to} eq 'ARRAY' ? $args{reply_to}[0] : $args{reply_to};
        croak "reply_to must be 64-char lowercase hex" unless $eid =~ $HEX64;
        if (ref $args{reply_to} eq 'ARRAY') {
            push @tags, ['e', @{$args{reply_to}}];
        } else {
            push @tags, ['e', $args{reply_to}];
        }
    }
    push @tags, ['subject', $args{subject}] if defined $args{subject};
    push @tags, ['file-type', $file_type];
    push @tags, ['encryption-algorithm', $encryption_algorithm];
    push @tags, ['decryption-key', $decryption_key];
    push @tags, ['decryption-nonce', $decryption_nonce];
    push @tags, ['x', $x];
    push @tags, ['ox', $args{ox}] if defined $args{ox};
    push @tags, ['size', $args{size}] if defined $args{size};
    push @tags, ['dim', $args{dim}] if defined $args{dim};
    push @tags, ['blurhash', $args{blurhash}] if defined $args{blurhash};
    push @tags, ['thumb', $args{thumb}] if defined $args{thumb};
    if ($args{fallback}) {
        for my $fb (@{$args{fallback}}) {
            push @tags, ['fallback', $fb];
        }
    }

    return Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender_pubkey,
        kind    => 15,
        content => $content,
        tags    => \@tags,
    );
}

sub create_relay_list {
    my ($class, %args) = @_;
    my $pubkey = $args{pubkey} // croak "pubkey required";
    my $relays = $args{relays} // croak "relays required";

    my @tags = map { ['relay', $_] } @$relays;

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 10050,
        content => '',
        tags    => \@tags,
    );
}

sub wrap_for_recipients {
    my ($class, %args) = @_;
    my $rumor       = $args{rumor}      // croak "rumor required";
    my $sender_key  = $args{sender_key} // croak "sender_key required";
    my $expiration  = $args{expiration};
    my $skip_sender = $args{skip_sender};

    my @recipients = map { $_->[1] } grep { $_->[0] eq 'p' } @{$rumor->tags};

    my @wraps;
    for my $recipient_pubkey (@recipients) {
        push @wraps, Net::Nostr::GiftWrap->seal_and_wrap(
            rumor            => $rumor,
            sender_key       => $sender_key,
            recipient_pubkey => $recipient_pubkey,
            (defined $expiration ? (expiration => $expiration, seal_expiration => $expiration) : ()),
        );
    }

    unless ($skip_sender) {
        push @wraps, Net::Nostr::GiftWrap->seal_and_wrap(
            rumor            => $rumor,
            sender_key       => $sender_key,
            recipient_pubkey => $sender_key->pubkey_hex,
            (defined $expiration ? (expiration => $expiration, seal_expiration => $expiration) : ()),
        );
    }

    return @wraps;
}

sub receive {
    my ($class, %args) = @_;
    my $event         = $args{event}         // croak "event required";
    my $recipient_key = $args{recipient_key} // croak "recipient_key required";

    my ($rumor, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $event,
        recipient_key => $recipient_key,
    );

    croak "sender pubkey mismatch: seal pubkey does not match rumor pubkey"
        unless $sender_pubkey eq $rumor->pubkey;

    return $rumor;
}

sub chat_members {
    my ($class, $event) = @_;
    my @members = ($event->pubkey);
    for my $tag (@{$event->tags}) {
        push @members, $tag->[1] if $tag->[0] eq 'p';
    }
    return @members;
}

1;

__END__

=head1 NAME

Net::Nostr::DirectMessage - NIP-17 private direct messages

=head1 SYNOPSIS

    use Net::Nostr::DirectMessage;
    use Net::Nostr::Key;

    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    # Create a chat message (kind 14 rumor)
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender->pubkey_hex,
        content       => 'Hola, que tal?',
        recipients    => [$recipient->pubkey_hex],
        subject       => 'Party',
    );

    # Wrap for all recipients + sender
    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $sender,
    );
    # Publish each wrap to recipient's kind 10050 relays

    # Recipient unwraps
    my $received = Net::Nostr::DirectMessage->receive(
        event         => $wraps[0],
        recipient_key => $recipient,
    );
    say $received->content;  # "Hola, que tal?"

    # Create a DM relay list (kind 10050)
    my $relay_list = Net::Nostr::DirectMessage->create_relay_list(
        pubkey => $sender->pubkey_hex,
        relays => ['wss://inbox.nostr.wine', 'wss://myrelay.nostr1.com'],
    );

=head1 DESCRIPTION

Implements NIP-17 private direct messages using L<NIP-44|Net::Nostr::Encryption>
encryption and L<NIP-59|Net::Nostr::GiftWrap> gift wrapping.

Messages are created as unsigned kind 14 (chat) or kind 15 (file) events,
then sealed and gift-wrapped individually for each recipient and the sender.
The gift wrap layer is designed to hide participant identities, timestamps,
and message content from relays and third parties. However, metadata
protection depends on proper usage: relay access patterns, network-level
metadata, and the C<p> tag on the outer wrap (needed for routing) are
still visible to the relay.

Other event kinds (e.g. kind 7 reactions) MAY also be gift-wrapped and
sent to chat participants using the same seal-and-wrap mechanism.

The set of C<pubkey> + C<p> tags defines a chat room. An optional C<subject>
tag sets the conversation topic.

=head1 CLASS METHODS

=head2 create

    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $pubkey_hex,
        content       => 'Hello!',
        recipients    => [$recipient_pubkey],
        subject       => 'Optional topic',     # optional
        reply_to      => $parent_event_id,     # optional
        quotes        => [[$event_id, $relay, $pubkey]],  # optional
    );

Creates a kind 14 chat message as an unsigned rumor. C<content> MUST be
plain text. C<recipients> is an arrayref of pubkey hex strings or
C<[$pubkey, $relay_url]> pairs for relay hints.

C<reply_to> can be a plain event ID string or an arrayref
C<[$event_id, $relay_url]> for relay hints.

C<quotes> is an optional arrayref of C<[$event_id, $relay_url, $pubkey]>
triples for citing other events via C<q> tags.

    # Simple recipients
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $key->pubkey_hex,
        content       => 'Hello!',
        recipients    => [$bob_pubkey, $carol_pubkey],
    );

    # With relay hints
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $key->pubkey_hex,
        content       => 'Hello!',
        recipients    => [[$bob_pubkey, 'wss://relay.example.com']],
        reply_to      => [$parent_id, 'wss://relay.example.com'],
    );

    # Quoting another event
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $key->pubkey_hex,
        content       => 'check this out',
        recipients    => [$recipient_pubkey],
        quotes        => [[$cited_id, 'wss://relay.example.com', $cited_pubkey]],
    );

=head2 create_file

    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $pubkey_hex,
        content              => 'https://example.com/encrypted-file.bin',
        recipients           => [$recipient_pubkey],
        file_type            => 'image/jpeg',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => $key,
        decryption_nonce     => $nonce,
        x                    => $sha256_hex,
    );

Creates a kind 15 file message as an unsigned rumor. The C<content> is
the file URL. Required tags: C<file-type>, C<encryption-algorithm>,
C<decryption-key>, C<decryption-nonce>, C<x>.

Optional tags: C<ox> (SHA-256 of original file), C<size>, C<dim>,
C<blurhash>, C<thumb>, C<fallback> (arrayref of fallback URLs),
C<subject> (conversation topic).

C<recipients> and C<reply_to> accept relay hints in the same format
as L</create>. For file replies, use an arrayref with the "reply" marker:
C<[$event_id, $relay_url, 'reply']>.

    # With all optional tags
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $key->pubkey_hex,
        content              => 'https://example.com/encrypted-photo.bin',
        recipients           => [$recipient_pubkey],
        file_type            => 'image/jpeg',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => $key,
        decryption_nonce     => $nonce,
        x                    => $sha256_hex,
        ox                   => $original_sha256,
        size                 => '2048000',
        dim                  => '1920x1080',
        blurhash             => 'LEHV6nWB2yk8',
        thumb                => 'https://example.com/thumb.bin',
        fallback             => ['https://backup.example.com/photo.bin'],
        subject              => 'Vacation photos',
    );

=head2 wrap_for_recipients

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $key,
    );

Seals and gift-wraps the rumor individually for each recipient (from
C<p> tags) and for the sender. Returns a list of kind 1059 events.

Optional arguments: C<expiration> (add expiration tags for disappearing
messages), C<skip_sender> (omit the sender's copy).

    # With expiration (disappearing messages)
    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $key,
        expiration => time() + 3600,
    );

    # Skip the sender's self-copy
    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor       => $msg,
        sender_key  => $key,
        skip_sender => 1,
    );

=head2 receive

    my $rumor = Net::Nostr::DirectMessage->receive(
        event         => $gift_wrap,
        recipient_key => $key,
    );

    say $rumor->kind;     # 14
    say $rumor->content;  # "secret message"
    say $rumor->pubkey;   # sender's pubkey

Unwraps a kind 1059 gift wrap and returns the inner rumor (unsigned event).
The returned rumor preserves all tags including C<subject>.
Verifies that the seal's pubkey matches the rumor's pubkey (required by
NIP-17). Croaks with "sender pubkey mismatch" if the seal was created by
a different key than the rumor claims, which prevents impersonation attacks.

B<Trust boundary>: This method decrypts and parses the gift wrap structure
and verifies the seal/rumor pubkey consistency. It does B<not> verify the
gift wrap's Schnorr signature or event ID hash. If you need full
cryptographic verification of the outer event, call
C<< $relay->_validate_event >> or verify the signature separately before
calling C<receive>.

=head2 create_relay_list

    my $event = Net::Nostr::DirectMessage->create_relay_list(
        pubkey => $pubkey_hex,
        relays => ['wss://inbox.nostr.wine', 'wss://myrelay.nostr1.com'],
    );

Creates a kind 10050 replaceable event listing preferred DM relays.
Tags use the C<relay> tag name (not C<r>). Clients SHOULD keep lists
small (1-3 relays).

=head2 chat_members

    my @members = Net::Nostr::DirectMessage->chat_members($msg);
    # @members = ($alice_pubkey, $bob_pubkey)

Returns the list of pubkeys in the chat room defined by the event:
the event's C<pubkey> (the sender) followed by all C<p>-tagged pubkeys.
The same set of members (regardless of order) defines the same chat room.

=head1 SEE ALSO

L<NIP-17|https://github.com/nostr-protocol/nips/blob/master/17.md>,
L<Net::Nostr::GiftWrap>, L<Net::Nostr::Encryption>

=cut
