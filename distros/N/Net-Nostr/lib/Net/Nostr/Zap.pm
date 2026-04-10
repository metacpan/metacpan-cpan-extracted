package Net::Nostr::Zap;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;
use Bitcoin::Crypto::Bech32 qw(
    encode_bech32
    translate_5to8 translate_8to5
);
use Crypt::PK::ECC;
use Crypt::PK::ECC::Schnorr;
use Exporter 'import';

our @EXPORT_OK = qw(
    lud16_to_url
    encode_lnurl decode_lnurl
    bolt11_amount
    callback_url
    calculate_splits
);

use Class::Tiny qw(
    _type
    p e a k
    relays amount lnurl content
    bolt11 description sender preimage
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

###############################################################################
# Constructors
###############################################################################

sub new_request {
    my ($class, %args) = @_;
    croak "p is required for zap request" unless defined $args{p};
    croak "relays is required for zap request" unless $args{relays} && @{$args{relays}};
    $args{content} //= '';
    return bless { _type => 'request', %args }, $class;
}

sub new_receipt {
    my ($class, %args) = @_;
    croak "p is required for zap receipt" unless defined $args{p};
    croak "bolt11 is required for zap receipt" unless defined $args{bolt11};
    croak "description is required for zap receipt" unless defined $args{description};
    $args{content} //= '';
    return bless { _type => 'receipt', %args }, $class;
}

###############################################################################
# Parsing from events
###############################################################################

sub request_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 9734" unless $event->kind == 9734;

    my %args = (content => $event->content);
    my @relays;
    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        my $name = $tag->[0];
        if ($name eq 'p')      { $args{p}      = $tag->[1] }
        elsif ($name eq 'e')   { $args{e}      = $tag->[1] }
        elsif ($name eq 'a')   { $args{a}      = $tag->[1] }
        elsif ($name eq 'k')   { $args{k}      = $tag->[1] }
        elsif ($name eq 'amount') { $args{amount} = $tag->[1] }
        elsif ($name eq 'lnurl')  { $args{lnurl}  = $tag->[1] }
        elsif ($name eq 'relays') { @relays = @{$tag}[1 .. $#$tag] }
    }
    $args{relays} = \@relays;
    return bless { _type => 'request', %args }, $class;
}

sub receipt_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 9735" unless $event->kind == 9735;

    my %args = (content => $event->content);
    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        my $name = $tag->[0];
        if ($name eq 'p')           { $args{p}           = $tag->[1] }
        elsif ($name eq 'P')        { $args{sender}      = $tag->[1] }
        elsif ($name eq 'e')        { $args{e}           = $tag->[1] }
        elsif ($name eq 'a')        { $args{a}           = $tag->[1] }
        elsif ($name eq 'k')        { $args{k}           = $tag->[1] }
        elsif ($name eq 'bolt11')   { $args{bolt11}      = $tag->[1] }
        elsif ($name eq 'description') { $args{description} = $tag->[1] }
        elsif ($name eq 'preimage') { $args{preimage}    = $tag->[1] }
    }
    return bless { _type => 'receipt', %args }, $class;
}

###############################################################################
# to_event
###############################################################################

sub to_event {
    my ($self, %args) = @_;

    if ($self->_type eq 'request') {
        return $self->_request_to_event(%args);
    } else {
        return $self->_receipt_to_event(%args);
    }
}

sub _request_to_event {
    my ($self, %args) = @_;
    my @tags;
    push @tags, ['relays', @{$self->relays}];
    push @tags, ['amount', $self->amount]  if defined $self->amount;
    push @tags, ['lnurl',  $self->lnurl]   if defined $self->lnurl;
    push @tags, ['p', $self->p];
    push @tags, ['e', $self->e]            if defined $self->e;
    push @tags, ['a', $self->a]            if defined $self->a;
    push @tags, ['k', $self->k]            if defined $self->k;

    return Net::Nostr::Event->new(
        %args,
        kind    => 9734,
        content => $self->content // '',
        tags    => \@tags,
    );
}

sub _receipt_to_event {
    my ($self, %args) = @_;
    my @tags;
    push @tags, ['p', $self->p];
    push @tags, ['P', $self->sender]       if defined $self->sender;
    push @tags, ['e', $self->e]            if defined $self->e;
    push @tags, ['a', $self->a]            if defined $self->a;
    push @tags, ['k', $self->k]            if defined $self->k;
    push @tags, ['bolt11', $self->bolt11];
    push @tags, ['description', $self->description];
    push @tags, ['preimage', $self->preimage] if defined $self->preimage;

    return Net::Nostr::Event->new(
        %args,
        kind    => 9735,
        content => '',
        tags    => \@tags,
    );
}

###############################################################################
# zap_request - extract embedded request from receipt description
###############################################################################

sub zap_request {
    my ($self) = @_;
    croak "zap_request() only available on receipts" unless $self->_type eq 'receipt';
    my $data = JSON->new->utf8->decode($self->description);
    return Net::Nostr::Event->new(
        id         => $data->{id},
        pubkey     => $data->{pubkey},
        created_at => $data->{created_at},
        kind       => $data->{kind},
        tags       => $data->{tags},
        content    => $data->{content},
        sig        => $data->{sig},
    );
}

###############################################################################
# Validation
###############################################################################

sub validate_request {
    my ($class, $event, %opts) = @_;
    croak "event must be kind 9734" unless $event->kind == 9734;

    # Rule 1: valid signature
    _verify_sig($event);

    # Rule 2: must have tags
    croak "zap request must have tags" unless @{$event->tags};

    my (@p_tags, @e_tags, @P_tags, @a_tags, @relays_tags, @amount_tags);
    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if    ($name eq 'p')      { push @p_tags, $tag }
        elsif ($name eq 'e')      { push @e_tags, $tag }
        elsif ($name eq 'P')      { push @P_tags, $tag }
        elsif ($name eq 'a')      { push @a_tags, $tag }
        elsif ($name eq 'relays') { push @relays_tags, $tag }
        elsif ($name eq 'amount') { push @amount_tags, $tag }
    }

    # Rule 3: exactly one p tag
    croak "zap request must have exactly one p tag" unless @p_tags == 1;

    # Rule 4: 0 or 1 e tags
    croak "zap request must have 0 or 1 e tags" unless @e_tags <= 1;

    # Rule 5: SHOULD have relays tag
    warn "zap request missing relays tag\n" unless @relays_tags;

    # Rule 6: amount tag must match amount query param
    if (@amount_tags && defined $opts{amount}) {
        croak "amount tag does not match amount parameter"
            unless $amount_tags[0][1] eq "$opts{amount}";
    }

    # Rule 7: a tag must be valid event coordinate
    for my $a_tag (@a_tags) {
        _validate_event_coordinate($a_tag->[1]);
    }

    # Rule 8: 0 or 1 P tags; if present, must equal receipt pubkey
    croak "zap request must have 0 or 1 P tags" unless @P_tags <= 1;
    if (@P_tags && defined $opts{receipt_pubkey}) {
        croak "P tag must equal zap receipt pubkey"
            unless $P_tags[0][1] eq $opts{receipt_pubkey};
    }

    return 1;
}

sub validate_receipt {
    my ($class, $event, %opts) = @_;
    croak "event must be kind 9735" unless $event->kind == 9735;

    my ($p_tag, $bolt11_tag, $desc_tag);
    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if    ($name eq 'p')           { $p_tag = $tag }
        elsif ($name eq 'bolt11')      { $bolt11_tag = $tag }
        elsif ($name eq 'description') { $desc_tag = $tag }
    }

    croak "zap receipt must have p tag" unless $p_tag;
    croak "zap receipt must have bolt11 tag" unless $bolt11_tag;
    croak "zap receipt must have description tag" unless $desc_tag;

    # Appendix F rule 1: pubkey must equal nostrPubkey
    if (defined $opts{nostr_pubkey}) {
        croak "zap receipt pubkey does not match nostrPubkey"
            unless $event->pubkey eq $opts{nostr_pubkey};
    }

    # Appendix F rule 2: invoiceAmount must equal zap request amount
    my $desc_data = eval { JSON->new->utf8->decode($desc_tag->[1]) };
    if ($desc_data && $desc_data->{tags}) {
        my $req_amount;
        for my $tag (@{$desc_data->{tags}}) {
            if ($tag->[0] eq 'amount') {
                $req_amount = $tag->[1];
                last;
            }
        }
        if (defined $req_amount) {
            my $invoice_amount = bolt11_amount($bolt11_tag->[1]);
            if (defined $invoice_amount) {
                croak "bolt11 invoice amount ($invoice_amount) does not match zap request amount ($req_amount)"
                    unless "$invoice_amount" eq "$req_amount";
            }
        }

        # Appendix F rule 3 (SHOULD): lnurl in request should equal recipient's lnurl
        if (defined $opts{lnurl}) {
            my $req_lnurl;
            for my $tag (@{$desc_data->{tags}}) {
                if ($tag->[0] eq 'lnurl') {
                    $req_lnurl = $tag->[1];
                    last;
                }
            }
            if (defined $req_lnurl) {
                warn "zap request lnurl does not match recipient lnurl\n"
                    unless $req_lnurl eq $opts{lnurl};
            }
        }
    }

    return 1;
}

sub _verify_sig {
    my ($event) = @_;
    croak "zap request has no signature" unless $event->sig;
    my $sig_raw = eval { pack 'H*', $event->sig };
    croak "invalid signature format" unless $sig_raw && length($sig_raw) == 64;

    my $pubkey_raw = pack 'H*', $event->pubkey;
    # Reconstruct the x-only pubkey in SEC1 compressed format for verification
    my $pk = Crypt::PK::ECC->new;
    $pk->import_key_raw("\x02" . $pubkey_raw, 'secp256k1');
    my $verifier = Crypt::PK::ECC::Schnorr->new(\$pk->export_key_der('public'));
    croak "invalid zap request signature"
        unless $verifier->verify_message($event->id, $sig_raw);
}

sub _validate_event_coordinate {
    my ($coord) = @_;
    # Format: <kind>:<pubkey>:<d-tag>
    my @parts = split /:/, $coord, 3;
    croak "invalid event coordinate: must be kind:pubkey:d-tag"
        unless @parts >= 2;
    croak "invalid event coordinate: kind must be integer"
        unless $parts[0] =~ /^\d+$/;
    croak "invalid event coordinate: pubkey must be 64-char lowercase hex"
        unless $parts[1] =~ $HEX64;
}

###############################################################################
# Utility functions
###############################################################################

sub lud16_to_url {
    my ($address) = @_;
    croak "invalid lightning address" unless defined $address && $address =~ /^([^@]+)@([^@]+)$/;
    my ($user, $domain) = (lc $1, lc $2);
    return "https://$domain/.well-known/lnurlp/$user";
}

{
    # Reuse Nostr bech32 decode logic for lnurl (same polymod)
    my @ALPHABET = qw(
        q p z r y 9 x 8  g f 2 t v d w 0
        s 3 j n 5 4 k h  c e 6 m u a 7 l
    );
    my %ALPHABET_MAP = map { $ALPHABET[$_] => $_ } 0 .. $#ALPHABET;
    my $CHARS = join '', @ALPHABET;

    sub _polymod {
        my ($values) = @_;
        my @C = (0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3);
        my $chk = 1;
        for my $val (@$values) {
            my $b = ($chk >> 25);
            $chk = ($chk & 0x1ffffff) << 5 ^ $val;
            for (0 .. 4) { $chk ^= (($b >> $_) & 1) ? $C[$_] : 0 }
        }
        return $chk;
    }

    sub _hrp_expand {
        my @hrp = split //, shift;
        return [map({ ord($_) >> 5 } @hrp), 0, map({ ord($_) & 31 } @hrp)];
    }

    sub _lnurl_decode_bech32 {
        my ($str) = @_;
        $str = lc $str if uc $str eq $str;
        croak "invalid bech32 string" if lc($str) ne $str;

        my @parts = split /1/, $str;
        croak "bech32 separator missing" if @parts < 2;
        my $data_part = pop @parts;
        my $hrp = join '1', @parts;

        croak "invalid bech32 data characters" if $data_part !~ /\A[$CHARS]+\z/;
        croak "bech32 data part too short" if length($data_part) < 6;

        my @data_values = map { $ALPHABET_MAP{$_} } split //, $data_part;
        my $check_values = [@{_hrp_expand($hrp)}, @data_values];
        croak "invalid bech32 checksum" unless _polymod($check_values) == 1;

        my @payload = @data_values[0 .. $#data_values - 6];
        return ($hrp, \@payload);
    }
}

sub encode_lnurl {
    my ($url) = @_;
    croak "url is required" unless defined $url;
    my $bytes = $url;  # URL is treated as raw bytes
    my $data5 = translate_8to5($bytes);
    return encode_bech32('lnurl', $data5, 'bech32');
}

sub decode_lnurl {
    my ($bech32) = @_;
    croak "expected lnurl prefix" unless defined $bech32 && lc($bech32) =~ /^lnurl1/;
    my ($hrp, $data5) = _lnurl_decode_bech32($bech32);
    croak "expected lnurl prefix, got $hrp" unless $hrp eq 'lnurl';
    my $bytes = translate_5to8($data5);
    return $bytes;
}

sub bolt11_amount {
    my ($invoice) = @_;
    croak "invalid bolt11 invoice" unless defined $invoice && $invoice =~ /^ln/i;

    # The bech32 separator is the LAST '1' in the string
    my $last_1 = rindex($invoice, '1');
    croak "invalid bolt11 invoice" if $last_1 < 0;
    my $hrp = lc substr($invoice, 0, $last_1);

    # HRP format: ln + network + [amount + multiplier]
    # Network: bcrt, bc, tb, etc.
    my $rest = $hrp;
    $rest =~ s/^ln//;
    $rest =~ s/^bcrt// or $rest =~ s/^[a-z]{2}//;

    return undef if $rest eq '';

    # Parse amount and multiplier
    my ($num, $mult) = $rest =~ /^(\d+)([munp]?)$/;
    return undef unless defined $num;

    # 1 BTC = 100_000_000_000 millisats
    my %multipliers = (
        ''  => 100_000_000_000,  # BTC
        'm' => 100_000_000,      # milli (10^-3 BTC)
        'u' => 100_000,          # micro (10^-6 BTC)
        'n' => 100,              # nano  (10^-9 BTC)
        'p' => 0.1,              # pico  (10^-12 BTC)
    );

    my $msats = $num * $multipliers{$mult};
    return int($msats);
}

sub _uri_escape {
    my ($str) = @_;
    $str =~ s/([^A-Za-z0-9\-_.~])/sprintf("%%%02X", ord($1))/ge;
    return $str;
}

sub callback_url {
    my ($base_url, %params) = @_;

    my @parts;
    if (defined $params{amount}) {
        push @parts, "amount=$params{amount}";
    }
    if (defined $params{nostr}) {
        my $event = $params{nostr};
        my $json = JSON->new->utf8->canonical->encode($event->to_hash);
        push @parts, "nostr=" . _uri_escape($json);
    }
    if (defined $params{lnurl}) {
        push @parts, "lnurl=$params{lnurl}";
    }

    my $sep = $base_url =~ /\?/ ? '&' : '?';
    return $base_url . $sep . join('&', @parts);
}

sub calculate_splits {
    my (@tags) = @_;
    return () unless @tags;

    # Check if any tag has a weight (4th element)
    my $has_any_weight = grep { defined $_->[3] } @tags;

    my @splits;
    my $total_weight = 0;

    if (!$has_any_weight) {
        # No weights at all: equal split
        my $pct = 100.0 / scalar @tags;
        for my $tag (@tags) {
            push @splits, {
                pubkey     => $tag->[1],
                relay      => $tag->[2],
                percentage => $pct,
            };
        }
        return @splits;
    }

    # Partial or full weights
    for my $tag (@tags) {
        my $weight = defined $tag->[3] ? $tag->[3] + 0 : 0;
        $total_weight += $weight;
    }

    for my $tag (@tags) {
        my $weight = defined $tag->[3] ? $tag->[3] + 0 : 0;
        my $pct = $total_weight > 0 ? ($weight / $total_weight) * 100.0 : 0;
        push @splits, {
            pubkey     => $tag->[1],
            relay      => $tag->[2],
            percentage => $pct,
        };
    }

    return @splits;
}

1;

__END__

=head1 NAME

Net::Nostr::Zap - NIP-57 Lightning Zaps

=head1 SYNOPSIS

    use Net::Nostr::Zap qw(
        lud16_to_url encode_lnurl decode_lnurl
        bolt11_amount callback_url calculate_splits
    );
    use Net::Nostr::Key;

    my $key = Net::Nostr::Key->new;

    # Create a zap request (kind 9734)
    my $zap_req = Net::Nostr::Zap->new_request(
        p      => $recipient_pubkey,
        relays => ['wss://relay.example.com'],
        amount => '21000',
        lnurl  => encode_lnurl('https://example.com/.well-known/lnurlp/alice'),
        e      => $event_id,
        k      => '1',
    );
    my $event = $zap_req->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);

    # Send zap request to recipient's LNURL callback
    my $url = callback_url('https://lnurl.example.com/callback',
        amount => 21000,
        nostr  => $event,
        lnurl  => $zap_req->lnurl,
    );

    # Parse a received zap request
    my $req = Net::Nostr::Zap->request_from_event($event);
    say $req->p;        # recipient pubkey
    say $req->amount;   # '21000'

    # Create a zap receipt (kind 9735)
    my $zap_receipt = Net::Nostr::Zap->new_receipt(
        p           => $recipient_pubkey,
        bolt11      => $bolt11_invoice,
        description => $zap_request_json,
        sender      => $sender_pubkey,
        e           => $event_id,
        preimage    => $preimage_hex,
    );
    my $receipt_event = $zap_receipt->to_event(pubkey => $server_pubkey);

    # Parse a received zap receipt
    my $receipt = Net::Nostr::Zap->receipt_from_event($receipt_event);
    say $receipt->bolt11;
    my $embedded_req = $receipt->zap_request;  # Net::Nostr::Event

    # Validate a zap request (Appendix D)
    Net::Nostr::Zap->validate_request($event);
    Net::Nostr::Zap->validate_request($event, amount => 21000);

    # Validate a zap receipt (Appendix F)
    Net::Nostr::Zap->validate_receipt($receipt_event,
        nostr_pubkey => $expected_pubkey,
    );

    # Convert lightning address to LNURL pay endpoint URL
    my $pay_url = lud16_to_url('alice@example.com');
    # https://example.com/.well-known/lnurlp/alice

    # Parse bolt11 invoice amount in millisats
    my $msats = bolt11_amount('lnbc10u1p3unwfu...');  # 1_000_000

    # Calculate zap splits from zap tags (Appendix G)
    my @splits = calculate_splits(@zap_tags);
    for my $split (@splits) {
        say "$split->{pubkey}: $split->{percentage}%";
    }

=head1 DESCRIPTION

Implements NIP-57 Lightning Zaps, which defines two event types for recording
lightning payments between Nostr users:

=over 4

=item * B<Zap request> (kind 9734) - Created by the sender and sent to the
recipient's LNURL pay callback URL (not published to relays).

=item * B<Zap receipt> (kind 9735) - Created by the recipient's lightning
wallet when the invoice is paid, and published to relays.

=back

=head1 CONSTRUCTORS

=head2 new_request

    my $zap = Net::Nostr::Zap->new_request(
        p       => $recipient_pubkey,   # required
        relays  => \@relay_urls,        # required
        amount  => '21000',             # millisats, recommended
        lnurl   => 'lnurl1...',        # recommended
        e       => $event_id,           # optional, if zapping an event
        a       => '30023:pk:slug',     # optional, for addressable events
        k       => '1',                 # optional, target event kind
        content => 'Great post!',       # optional message
    );

Creates a zap request. C<p> (recipient pubkey) and C<relays> are required.

=head2 new_receipt

    my $zap = Net::Nostr::Zap->new_receipt(
        p           => $recipient_pubkey,    # required
        bolt11      => $invoice,             # required
        description => $zap_request_json,    # required
        sender      => $sender_pubkey,       # optional (P tag)
        e           => $event_id,            # optional
        a           => '30023:pk:slug',      # optional
        k           => '1',                  # optional
        preimage    => $preimage_hex,        # optional
    );

Creates a zap receipt. C<p>, C<bolt11>, and C<description> are required. The
C<description> must be the JSON-encoded zap request event.

=head2 request_from_event

    my $zap = Net::Nostr::Zap->request_from_event($event);

Parses a kind 9734 event into a Zap object. Croaks if the event is not
kind 9734.

    my $zap = Net::Nostr::Zap->request_from_event($event);
    say $zap->p;       # recipient pubkey
    say $zap->amount;  # millisats or undef

=head2 receipt_from_event

    my $zap = Net::Nostr::Zap->receipt_from_event($event);

Parses a kind 9735 event into a Zap object. Croaks if the event is not
kind 9735.

    my $zap = Net::Nostr::Zap->receipt_from_event($receipt_event);
    say $zap->bolt11;       # bolt11 invoice
    say $zap->description;  # JSON zap request

=head1 METHODS

=head2 to_event

    my $event = $zap->to_event(pubkey => $hex_pubkey);
    my $event = $zap->to_event(pubkey => $hex, created_at => time());

Creates a L<Net::Nostr::Event> from the zap object. Extra arguments are
passed through to the Event constructor.

For zap requests, creates a kind 9734 event. For zap receipts, creates a
kind 9735 event with empty content.

    my $event = $zap_req->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);

=head2 zap_request

    my $event = $zap_receipt->zap_request;

Parses the C<description> tag of a zap receipt back into a
L<Net::Nostr::Event> object representing the original zap request.
Only available on receipt objects.

    my $receipt = Net::Nostr::Zap->receipt_from_event($event);
    my $req = $receipt->zap_request;
    say $req->pubkey;  # the sender's pubkey

=head2 p

    my $pubkey = $zap->p;

Returns the recipient's pubkey (from the C<p> tag).

=head2 relays

    my $relays = $zap->relays;  # arrayref

Returns the relay URLs (zap request only).

=head2 amount

    my $msats = $zap->amount;  # '21000' or undef

Returns the amount in millisats (zap request only). This is a string.

=head2 lnurl

    my $lnurl = $zap->lnurl;  # 'lnurl1...' or undef

Returns the bech32-encoded LNURL (zap request only).

=head2 e

    my $event_id = $zap->e;  # hex or undef

Returns the zapped event ID.

=head2 a

    my $coord = $zap->a;  # 'kind:pubkey:d-tag' or undef

Returns the addressable event coordinate.

=head2 k

    my $kind = $zap->k;  # '1' or undef

Returns the stringified kind of the target event.

=head2 content

    my $msg = $zap->content;

Returns the zap message (zap request) or empty string (zap receipt).

=head2 bolt11

    my $invoice = $zap->bolt11;

Returns the bolt11 invoice (zap receipt only).

=head2 description

    my $json = $zap->description;

Returns the JSON-encoded zap request (zap receipt only).

=head2 sender

    my $pubkey = $zap->sender;  # hex or undef

Returns the sender's pubkey from the C<P> tag (zap receipt only).

=head2 preimage

    my $preimage = $zap->preimage;  # hex or undef

Returns the payment preimage (zap receipt only).

=head1 CLASS METHODS

=head2 validate_request

    Net::Nostr::Zap->validate_request($event);
    Net::Nostr::Zap->validate_request($event, amount => 21000);
    Net::Nostr::Zap->validate_request($event, receipt_pubkey => $pubkey);

Validates a zap request event per Appendix D of NIP-57. Croaks on
validation failure. Checks:

=over 4

=item 1. Valid Schnorr signature

=item 2. Must have tags

=item 3. Exactly one C<p> tag

=item 4. Zero or one C<e> tags

=item 5. Should have C<relays> tag (warns if missing)

=item 6. C<amount> tag must match C<amount> parameter if both present

=item 7. C<a> tag must be a valid event coordinate

=item 8. Zero or one C<P> tags; if present and C<receipt_pubkey> is given,
the C<P> tag value must equal C<receipt_pubkey>

=back

    my $key = Net::Nostr::Key->new;
    my $event = $zap_req->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);
    Net::Nostr::Zap->validate_request($event, amount => 21000);

=head2 validate_receipt

    Net::Nostr::Zap->validate_receipt($event,
        nostr_pubkey => $expected,
        lnurl        => $recipient_lnurl,
    );

Validates a zap receipt event per Appendix F of NIP-57. Croaks on
validation failure. Checks:

=over 4

=item * Receipt pubkey must match C<nostr_pubkey> (the recipient's LNURL
server pubkey)

=item * Must have C<p>, C<bolt11>, and C<description> tags

=item * Invoice amount must match the zap request's C<amount> tag if present

=item * If C<lnurl> is provided and the zap request contains an C<lnurl>
tag, warns if they do not match (SHOULD per spec)

=back

    Net::Nostr::Zap->validate_receipt($receipt_event,
        nostr_pubkey => $server_pubkey,
        lnurl        => $recipient_lnurl,
    );

=head1 FUNCTIONS

All functions are exportable. None are exported by default.

=head2 lud16_to_url

    my $url = lud16_to_url('alice@example.com');
    # https://example.com/.well-known/lnurlp/alice

Converts a lightning address (LUD-16 format) to its LNURL pay endpoint URL.

    my $url = lud16_to_url('bob@pay.domain.org');
    # https://pay.domain.org/.well-known/lnurlp/bob

=head2 encode_lnurl

    my $lnurl = encode_lnurl('https://example.com/.well-known/lnurlp/alice');
    # lnurl1dp68gurn8ghj7...

Encodes a URL as a bech32 string with the C<lnurl> prefix.

=head2 decode_lnurl

    my $url = decode_lnurl('lnurl1dp68gurn8ghj7...');
    # https://example.com/.well-known/lnurlp/alice

Decodes a bech32-encoded LNURL back to a URL string. Croaks if the prefix
is not C<lnurl>.

=head2 bolt11_amount

    my $msats = bolt11_amount('lnbc10u1p3unwfu...');  # 1_000_000

Extracts the amount in millisats from a bolt11 lightning invoice. Returns
C<undef> if the invoice has no amount. Croaks if the string is not a valid
bolt11 invoice.

Amount multiplier suffixes:

    m = milli (10^-3 BTC) = 100,000,000 millisats per unit
    u = micro (10^-6 BTC) = 100,000 millisats per unit
    n = nano  (10^-9 BTC) = 100 millisats per unit
    p = pico  (10^-12 BTC) = 0.1 millisats per unit

    bolt11_amount('lnbc20m1...')   # 2_000_000_000
    bolt11_amount('lnbc2500u1...') # 250_000_000
    bolt11_amount('lnbc10u1...')   # 1_000_000

=head2 callback_url

    my $url = callback_url($base_callback,
        amount => 21000,
        nostr  => $zap_request_event,
        lnurl  => 'lnurl1...',
    );

Constructs the HTTP GET URL for sending a zap request to the recipient's
LNURL callback endpoint (Appendix B). The C<nostr> parameter should be a
L<Net::Nostr::Event> object which will be JSON-encoded and URI-escaped.

    my $url = callback_url('https://lnurl.example.com/callback',
        amount => 21000,
        nostr  => $signed_event,
        lnurl  => $lnurl,
    );
    # https://lnurl.example.com/callback?amount=21000&nostr=%7B...%7D&lnurl=lnurl1...

=head2 calculate_splits

    my @splits = calculate_splits(@zap_tags);

Calculates zap split percentages from C<zap> tags on an event (Appendix G).
Each tag should be an arrayref: C<['zap', $pubkey, $relay, $weight]>.

Returns a list of hashrefs with C<pubkey>, C<relay>, and C<percentage> keys.

If no tags have weights, the split is equal among all recipients. If some
tags have weights and others don't, the weightless tags get 0%.

    # From spec example: 25%, 25%, 50%
    my @splits = calculate_splits(
        ['zap', $pk1, $relay1, '1'],
        ['zap', $pk2, $relay2, '1'],
        ['zap', $pk3, $relay3, '2'],
    );
    say $splits[0]{percentage};  # 25
    say $splits[2]{percentage};  # 50

=head1 SEE ALSO

L<NIP-57|https://github.com/nostr-protocol/nips/blob/master/57.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Key>

=cut
