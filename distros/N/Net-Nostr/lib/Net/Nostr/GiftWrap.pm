package Net::Nostr::GiftWrap;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;
use Net::Nostr::Key;
use Net::Nostr::Encryption;

my $TWO_DAYS = 2 * 24 * 60 * 60;
my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub _random_timestamp {
    return int(time() - rand($TWO_DAYS));
}

sub _rumor_hash {
    my ($rumor) = @_;
    my %h;
    for my $field (qw(id pubkey created_at kind tags content)) {
        $h{$field} = $rumor->$field if defined $rumor->$field;
    }
    return \%h;
}

sub create_rumor {
    my ($class, %args) = @_;
    delete $args{sig};  # rumors are unsigned
    return Net::Nostr::Event->new(%args);
}

sub seal {
    my ($class, %args) = @_;
    my $rumor            = $args{rumor}            // croak "rumor required";
    my $sender_key       = $args{sender_key}       // croak "sender_key required";
    my $recipient_pubkey = $args{recipient_pubkey} // croak "recipient_pubkey required";
    croak "recipient_pubkey must be 64-char lowercase hex" unless $recipient_pubkey =~ $HEX64;
    my $created_at       = $args{created_at}       // _random_timestamp();
    my $expiration       = $args{expiration};

    my $rumor_json = JSON->new->utf8->canonical->encode(_rumor_hash($rumor));

    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $sender_key->privkey_hex, $recipient_pubkey,
    );
    my $encrypted = Net::Nostr::Encryption->encrypt($rumor_json, $conv_key);

    my @tags;
    push @tags, ['expiration', "$expiration"] if defined $expiration;

    return $sender_key->create_event(
        kind       => 13,
        content    => $encrypted,
        tags       => \@tags,
        created_at => $created_at,
    );
}

sub wrap {
    my ($class, %args) = @_;
    my $seal             = $args{seal}             // croak "seal required";
    my $recipient_pubkey = $args{recipient_pubkey} // croak "recipient_pubkey required";
    croak "recipient_pubkey must be 64-char lowercase hex" unless $recipient_pubkey =~ $HEX64;
    my $wrapper_key      = $args{wrapper_key}      // Net::Nostr::Key->new;
    my $created_at       = $args{created_at}       // _random_timestamp();
    my $expiration       = $args{expiration};

    my $seal_json = JSON->new->utf8->canonical->encode($seal->to_hash);

    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $wrapper_key->privkey_hex, $recipient_pubkey,
    );
    my $encrypted = Net::Nostr::Encryption->encrypt($seal_json, $conv_key);

    my @tags = (['p', $recipient_pubkey]);
    push @tags, ['expiration', "$expiration"] if defined $expiration;

    return $wrapper_key->create_event(
        kind       => 1059,
        content    => $encrypted,
        tags       => \@tags,
        created_at => $created_at,
    );
}

sub seal_and_wrap {
    my ($class, %args) = @_;
    my $rumor            = $args{rumor}            // croak "rumor required";
    my $sender_key       = $args{sender_key}       // croak "sender_key required";
    my $recipient_pubkey = $args{recipient_pubkey} // croak "recipient_pubkey required";

    my $seal = $class->seal(
        rumor            => $rumor,
        sender_key       => $sender_key,
        recipient_pubkey => $recipient_pubkey,
        (defined $args{seal_expiration} ? (expiration => $args{seal_expiration}) : ()),
    );

    return $class->wrap(
        seal             => $seal,
        recipient_pubkey => $recipient_pubkey,
        (defined $args{expiration} ? (expiration => $args{expiration}) : ()),
    );
}

sub unwrap {
    my ($class, %args) = @_;
    my $event         = $args{event}         // croak "event required";
    my $recipient_key = $args{recipient_key} // croak "recipient_key required";

    croak "event must be kind 1059" unless $event->kind == 1059;

    # Decrypt the seal
    my $conv_key1 = Net::Nostr::Encryption->get_conversation_key(
        $recipient_key->privkey_hex, $event->pubkey,
    );
    my $seal_json = Net::Nostr::Encryption->decrypt($event->content, $conv_key1);
    my $seal_data = JSON::decode_json($seal_json);

    croak "seal must be kind 13" unless $seal_data->{kind} == 13;

    # Decrypt the rumor
    my $conv_key2 = Net::Nostr::Encryption->get_conversation_key(
        $recipient_key->privkey_hex, $seal_data->{pubkey},
    );
    my $rumor_json = Net::Nostr::Encryption->decrypt($seal_data->{content}, $conv_key2);
    my $rumor_data = JSON::decode_json($rumor_json);

    my $rumor = Net::Nostr::Event->new(
        id         => $rumor_data->{id},
        pubkey     => $rumor_data->{pubkey},
        created_at => $rumor_data->{created_at},
        kind       => $rumor_data->{kind},
        tags       => $rumor_data->{tags} // [],
        content    => $rumor_data->{content},
    );

    return ($rumor, $seal_data->{pubkey});
}

1;

__END__

=head1 NAME

Net::Nostr::GiftWrap - NIP-59 gift wrap encryption

=head1 SYNOPSIS

    use Net::Nostr::GiftWrap;
    use Net::Nostr::Key;

    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    # Create an unsigned rumor
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender->pubkey_hex,
        kind    => 1,
        content => 'Are you going to the party tonight?',
        tags    => [],
    );

    # Seal and wrap in one step
    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    # Recipient unwraps
    my ($unwrapped, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap,
        recipient_key => $recipient,
    );
    say $unwrapped->content;  # "Are you going to the party tonight?"
    say $sender_pubkey;       # sender's pubkey (from seal)

=head1 DESCRIPTION

Implements NIP-59 gift wrapping, a protocol for encapsulating any Nostr
event to obscure metadata. Uses three layers:

=over 4

=item B<Rumor> - An unsigned event. Provides deniability if leaked.

=item B<Seal> (kind 13) - Encrypts the rumor with the sender's key. Identifies
the author without revealing content or recipient. Tags are always empty.

=item B<Gift wrap> (kind 1059) - Encrypts the seal with a random one-time key.
Includes a C<p> tag for routing to the recipient.

=back

Encryption uses L<NIP-44|Net::Nostr::Encryption>. Timestamps on seals and
gift wraps are randomized up to two days in the past to thwart time-analysis
attacks.

=head1 CLASS METHODS

=head2 create_rumor

    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $pubkey_hex,
        kind    => 14,
        content => 'Hello!',
        tags    => [['p', $recipient_pubkey]],
    );

Creates an unsigned event (rumor). Arguments are passed to
C<< Net::Nostr::Event->new >> and the signature is removed.

=head2 seal

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    say $seal->kind;                   # 13
    say $seal->pubkey eq $sender->pubkey_hex;  # 1 (signed by sender)
    say scalar @{$seal->tags};         # 0 (always empty)

Creates a kind 13 seal event. The rumor is JSON-encoded and encrypted
with NIP-44 using the sender's private key and recipient's public key.
The seal is signed by the sender. Tags are empty per the spec (except
when C<expiration> is explicitly requested, per NIP-17).

Optional arguments: C<created_at> (override random timestamp),
C<expiration> (add expiration tag for disappearing messages).

=head2 wrap

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    say $wrap->kind;    # 1059
    say $wrap->pubkey;  # random one-time-use pubkey (not the sender)

Creates a kind 1059 gift wrap event. The seal is JSON-encoded and encrypted
with NIP-44 using a random one-time key. A C<p> tag is added for the
recipient.

Optional arguments: C<wrapper_key> (override random key, for testing),
C<created_at> (override random timestamp), C<expiration> (add expiration
tag).

=head2 seal_and_wrap

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
    );

Convenience method that calls L</seal> then L</wrap>.

Optional arguments: C<expiration> (gift wrap expiration),
C<seal_expiration> (seal expiration).

Expiration example (disappearing messages):

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
        expiration       => time() + 86400,
        seal_expiration  => time() + 86400,
    );

=head2 unwrap

    my ($unwrapped, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $gift_wrap_event,
        recipient_key => $recipient,
    );

Decrypts a kind 1059 gift wrap event. Returns the rumor (unsigned event)
and the sender's public key (from the seal). The caller should verify
that C<$sender_pubkey> matches C<< $unwrapped->pubkey >> for authentication
(L<Net::Nostr::DirectMessage/receive> does this automatically).

Croaks if the event is not kind 1059 or the seal is not kind 13.

B<Trust boundary>: This method only decrypts and parses the layered
structure. It checks kind numbers but does B<not> verify the gift wrap
event's signature, event ID hash, or the seal event's signature. The
returned rumor is unsigned by design (for deniability). Callers receiving
gift wraps from untrusted sources should verify the outer event's
signature before calling C<unwrap>.

=head2 Multi-recipient wrapping

A single rumor can be wrapped individually for each recipient:

    for my $pubkey (@recipient_pubkeys) {
        my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
            rumor            => $rumor,
            sender_key       => $sender,
            recipient_pubkey => $pubkey,
        );
        # publish $wrap to $pubkey's relays
    }

The author can also retain an encrypted copy by wrapping to their own
pubkey:

    my $self_copy = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $sender->pubkey_hex,
    );

=head1 SEE ALSO

L<NIP-59|https://github.com/nostr-protocol/nips/blob/master/59.md>,
L<Net::Nostr::Encryption>, L<Net::Nostr::DirectMessage>

=cut
