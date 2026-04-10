package Net::Nostr::Nutzap;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

use Class::Tiny qw(
    relays
    mints
    p2pk_pubkey
    proofs
    mint_url
    unit
    recipient
    event_id
    event_kind
    nutzap_ids
    sender_pubkey
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{relays}     //= [];
    $args{mints}      //= [];
    $args{proofs}     //= [];
    $args{nutzap_ids} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub info_event {
    my ($class, %args) = @_;

    my $pubkey      = $args{pubkey}      // croak "info_event requires 'pubkey'";
    my $relays      = $args{relays}      // croak "info_event requires 'relays'";
    my $mints       = $args{mints}       // croak "info_event requires 'mints'";
    my $p2pk_pubkey = $args{p2pk_pubkey} // croak "info_event requires 'p2pk_pubkey'";

    my @tags;
    for my $relay (@$relays) {
        push @tags, ['relay', $relay];
    }
    for my $mint (@$mints) {
        push @tags, ['mint', $mint->{url}, @{$mint->{units} // []}];
    }
    push @tags, ['pubkey', $p2pk_pubkey];

    delete @args{qw(relays mints p2pk_pubkey)};
    return Net::Nostr::Event->new(%args, kind => 10019, content => '', tags => \@tags);
}

sub nutzap {
    my ($class, %args) = @_;

    my $pubkey    = $args{pubkey}    // croak "nutzap requires 'pubkey'";
    my $recipient = $args{recipient} // croak "nutzap requires 'recipient'";
    my $proofs    = $args{proofs}    // croak "nutzap requires 'proofs'";
    my $mint_url  = $args{mint_url}  // croak "nutzap requires 'mint_url'";
    my $unit      = $args{unit}      // 'sat';
    my $content   = $args{content}   // '';

    croak "recipient must be 64-char lowercase hex" unless $recipient =~ $HEX64;

    my @tags;
    for my $proof (@$proofs) {
        push @tags, ['proof', $proof];
    }
    push @tags, ['unit', $unit];
    push @tags, ['u', $mint_url];

    if (defined $args{event_id}) {
        croak "event_id must be 64-char lowercase hex" unless $args{event_id} =~ $HEX64;
        my @e = ('e', $args{event_id});
        push @e, $args{relay_hint} if defined $args{relay_hint};
        push @tags, \@e;
    }
    if (defined $args{event_kind}) {
        push @tags, ['k', '' . $args{event_kind}];
    }

    push @tags, ['p', $recipient];

    delete @args{qw(recipient proofs mint_url unit content event_id event_kind relay_hint)};
    return Net::Nostr::Event->new(%args, kind => 9321, content => $content, tags => \@tags);
}

sub redemption {
    my ($class, %args) = @_;

    my $pubkey        = $args{pubkey}        // croak "redemption requires 'pubkey'";
    my $nutzap_ids    = $args{nutzap_ids}    // croak "redemption requires 'nutzap_ids'";
    my $sender_pubkey = $args{sender_pubkey} // croak "redemption requires 'sender_pubkey'";
    my $relay_hint    = $args{relay_hint}    // '';
    my $content       = $args{content}       // '';

    for my $id (@$nutzap_ids) {
        croak "nutzap_id must be 64-char lowercase hex" unless $id =~ $HEX64;
    }
    croak "sender_pubkey must be 64-char lowercase hex" unless $sender_pubkey =~ $HEX64;

    my @tags;
    for my $id (@$nutzap_ids) {
        push @tags, ['e', $id, $relay_hint, 'redeemed'];
    }
    push @tags, ['p', $sender_pubkey];

    delete @args{qw(nutzap_ids sender_pubkey relay_hint content)};
    return Net::Nostr::Event->new(%args, kind => 7376, content => $content, tags => \@tags);
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 10019) {
        return $class->_parse_info($event);
    } elsif ($kind == 9321) {
        return $class->_parse_nutzap($event);
    } elsif ($kind == 7376) {
        return $class->_parse_redemption($event);
    }
    return undef;
}

sub _parse_info {
    my ($class, $event) = @_;
    my (@relays, @mints, $p2pk_pubkey);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'relay') {
            push @relays, $tag->[1];
        } elsif ($name eq 'mint') {
            push @mints, { url => $tag->[1], units => [@{$tag}[2 .. $#$tag]] };
        } elsif ($name eq 'pubkey') {
            $p2pk_pubkey = $tag->[1];
        }
    }

    return $class->new(
        relays      => \@relays,
        mints       => \@mints,
        p2pk_pubkey => $p2pk_pubkey,
    );
}

sub _parse_nutzap {
    my ($class, $event) = @_;
    my (@proofs, $mint_url, $unit, $recipient, $event_id, $event_kind);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'proof') {
            push @proofs, $tag->[1];
        } elsif ($name eq 'u') {
            $mint_url = $tag->[1];
        } elsif ($name eq 'unit') {
            $unit = $tag->[1];
        } elsif ($name eq 'p') {
            $recipient //= $tag->[1];
        } elsif ($name eq 'e') {
            $event_id //= $tag->[1];
        } elsif ($name eq 'k') {
            $event_kind //= $tag->[1];
        }
    }

    return $class->new(
        proofs     => \@proofs,
        mint_url   => $mint_url,
        unit       => $unit,
        recipient  => $recipient,
        event_id   => $event_id,
        event_kind => $event_kind,
    );
}

sub _parse_redemption {
    my ($class, $event) = @_;
    my (@nutzap_ids, $sender_pubkey);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'e') {
            push @nutzap_ids, $tag->[1];
        } elsif ($name eq 'p') {
            $sender_pubkey //= $tag->[1];
        }
    }

    return $class->new(
        nutzap_ids    => \@nutzap_ids,
        sender_pubkey => $sender_pubkey,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 10019) {
        my ($has_relay, $has_mint, $has_pubkey);
        for my $tag (@{$event->tags}) {
            $has_relay = 1 if $tag->[0] eq 'relay';
            $has_mint  = 1 if $tag->[0] eq 'mint';
            $has_pubkey = 1 if $tag->[0] eq 'pubkey';
        }
        croak "kind 10019 MUST have at least one relay tag" unless $has_relay;
        croak "kind 10019 MUST have at least one mint tag" unless $has_mint;
        croak "kind 10019 MUST have a pubkey tag" unless $has_pubkey;
    } elsif ($kind == 9321) {
        my ($has_proof, $has_u, $has_p);
        for my $tag (@{$event->tags}) {
            $has_proof = 1 if $tag->[0] eq 'proof';
            $has_u     = 1 if $tag->[0] eq 'u';
            $has_p     = 1 if $tag->[0] eq 'p';
        }
        croak "kind 9321 MUST have at least one proof tag" unless $has_proof;
        croak "kind 9321 MUST have a u tag (mint URL)" unless $has_u;
        croak "kind 9321 MUST have a p tag (recipient)" unless $has_p;
    } elsif ($kind == 7376) {
        my $has_e;
        for my $tag (@{$event->tags}) {
            $has_e = 1 if $tag->[0] eq 'e';
        }
        croak "kind 7376 MUST have at least one e tag" unless $has_e;
    } else {
        croak "nutzap event MUST be kind 10019, 9321, or 7376";
    }

    return 1;
}

1;

__END__

=head1 NAME

Net::Nostr::Nutzap - NIP-61 nutzaps (Cashu ecash payments)

=head1 SYNOPSIS

    use Net::Nostr::Nutzap;

    my $pubkey      = 'aa' x 32;
    my $p2pk_pubkey = 'cc' x 32;

    # Publish nutzap info (kind 10019) - tells others how to send you ecash
    my $info = Net::Nostr::Nutzap->info_event(
        pubkey      => $pubkey,
        relays      => ['wss://relay1', 'wss://relay2'],
        mints       => [
            { url => 'https://mint1', units => ['usd', 'sat'] },
            { url => 'https://mint2', units => ['sat'] },
        ],
        p2pk_pubkey => $p2pk_pubkey,
    );

    # Send a nutzap (kind 9321)
    my $proof_json = '{"amount":1,"C":"02...","id":"000a","secret":"..."}';
    my $zap = Net::Nostr::Nutzap->nutzap(
        pubkey     => $pubkey,
        recipient  => 'bb' x 32,
        proofs     => [$proof_json],
        mint_url   => 'https://mint1',
        unit       => 'sat',
        event_id   => 'dd' x 32,
        event_kind => '1',
        content    => 'Great post!',
    );

    # Record redemption (kind 7376)
    my $nutzap_event_id = 'ee' x 32;
    my $redeem = Net::Nostr::Nutzap->redemption(
        pubkey        => $pubkey,
        nutzap_ids    => [$nutzap_event_id],
        sender_pubkey => 'bb' x 32,
        relay_hint    => 'wss://relay1',
        content       => $encrypted_content,  # NIP-44 encrypted
    );

    # Parse any nutzap-related event
    my $parsed = Net::Nostr::Nutzap->from_event($event);

    # Validate
    Net::Nostr::Nutzap->validate($event);

=head1 DESCRIPTION

Implements NIP-61 nutzaps -- peer-to-peer Cashu ecash payments over Nostr.
A nutzap is a P2PK-locked Cashu token where the payment itself is the
receipt.

Three event kinds are involved:

=over

=item B<kind 10019> - Nutzap informational event (replaceable). Lists
the user's trusted mints, relay preferences, and P2PK public key for
receiving nutzaps. The P2PK pubkey MUST NOT be the user's main Nostr
public key.

=item B<kind 9321> - Nutzap event. Published by the sender, containing
Cashu proofs P2PK-locked to the recipient's specified public key. Includes
the mint URL, unit, and optional event reference.

=item B<kind 7376> - Nutzap redemption history. Created when claiming
tokens, tagging the original nutzap event(s) with a C<redeemed> marker.

=back

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Nutzap->new(%fields);

Creates a new C<Net::Nostr::Nutzap> object. Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Nutzap->new(
        mint_url  => 'https://mint1',
        unit      => 'sat',
        recipient => $hex_pubkey,
        proofs    => [],
    );

Accepted fields: C<relays> (defaults to C<[]>), C<mints> (defaults to C<[]>),
C<p2pk_pubkey>, C<proofs> (defaults to C<[]>), C<mint_url>, C<unit>,
C<recipient>, C<event_id>, C<event_kind>, C<nutzap_ids> (defaults to C<[]>),
C<sender_pubkey>. Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 info_event

    my $event = Net::Nostr::Nutzap->info_event(
        pubkey      => $hex_pubkey,
        relays      => ['wss://relay1'],
        mints       => [{ url => 'https://mint1', units => ['sat'] }],
        p2pk_pubkey => $hex_p2pk_key,
    );

Creates a kind 10019 nutzap informational L<Net::Nostr::Event>.
C<pubkey>, C<relays>, C<mints>, and C<p2pk_pubkey> are required. Each
mint entry is a hashref with C<url> and an optional C<units> arrayref
of supported base units (e.g. C<sat>, C<usd>).

=head2 nutzap

    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey     => $hex_pubkey,        # required
        recipient  => $hex_pubkey,        # required (p tag)
        proofs     => [$proof_json, ...], # required (proof tags)
        mint_url   => 'https://mint',     # required (u tag)
        unit       => 'sat',              # optional, default 'sat'
        event_id   => $hex_event_id,      # optional (e tag)
        event_kind => '1',                # optional (k tag)
        relay_hint => 'wss://relay',      # optional
        content    => 'nice!',            # optional comment
    );

Creates a kind 9321 nutzap L<Net::Nostr::Event>. C<pubkey>, C<recipient>,
C<proofs>, and C<mint_url> are required. Multiple proofs create multiple
C<proof> tags.

=head2 redemption

    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $hex_pubkey,
        nutzap_ids    => [$event_id, ...],
        sender_pubkey => $hex_pubkey,
        relay_hint    => 'wss://relay',     # optional
        content       => $encrypted,        # optional (NIP-44 encrypted)
    );

Creates a kind 7376 redemption L<Net::Nostr::Event>. Multiple nutzap IDs
can be tagged in a single redemption. Each C<e> tag includes the
C<redeemed> marker.

The C<content> parameter accepts pre-encrypted NIP-44 data containing
the redemption details (direction, amount, unit, created token reference).
Defaults to empty string if not provided.

=head2 from_event

    my $info = Net::Nostr::Nutzap->from_event($event);

Parses a kind 10019, 9321, or 7376 event into a C<Net::Nostr::Nutzap>
object. Returns C<undef> for unrecognized kinds.

=head2 validate

    Net::Nostr::Nutzap->validate($event);

Validates a nutzap-related event. Croaks on invalid structure.

For kind 10019: requires at least one C<relay> tag, one C<mint> tag, and
a C<pubkey> tag.

For kind 9321: requires at least one C<proof> tag, a C<u> tag (mint URL),
and a C<p> tag (recipient).

For kind 7376: requires at least one C<e> tag.

=head1 ACCESSORS

Available on objects returned by L</from_event>. Which accessors contain
data depends on the event kind parsed.

=head2 relays

Arrayref of relay URLs (kind 10019).

=head2 mints

Arrayref of hashrefs with C<url> and C<units> keys (kind 10019).

=head2 p2pk_pubkey

The P2PK public key for receiving nutzaps (kind 10019).

=head2 proofs

Arrayref of proof JSON strings (kind 9321).

=head2 mint_url

The mint URL from the C<u> tag (kind 9321).

=head2 unit

The base unit (kind 9321), e.g. C<sat>, C<usd>.

=head2 recipient

The recipient's Nostr pubkey from the C<p> tag (kind 9321).

=head2 event_id

The nutzapped event ID from the C<e> tag (kind 9321), or C<undef>.

=head2 event_kind

The nutzapped event kind from the C<k> tag (kind 9321), or C<undef>.

=head2 nutzap_ids

Arrayref of redeemed nutzap event IDs (kind 7376).

=head2 sender_pubkey

The nutzap sender's pubkey from the C<p> tag (kind 7376).

=head1 SEE ALSO

L<NIP-61|https://github.com/nostr-protocol/nips/blob/master/61.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
