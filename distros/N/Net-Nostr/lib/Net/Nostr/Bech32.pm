package Net::Nostr::Bech32;

use strictures 2;

use Carp qw(croak);
use Exporter 'import';
use Bitcoin::Crypto::Bech32 qw(
    encode_bech32
    translate_5to8 translate_8to5
);

our @EXPORT_OK = qw(
    encode_npub  decode_npub
    encode_nsec  decode_nsec
    encode_note  decode_note
    encode_nprofile decode_nprofile
    encode_nevent   decode_nevent
    encode_naddr    decode_naddr
    decode_bech32_entity
    encode_nostr_uri decode_nostr_uri
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my $MAX_BECH32_LENGTH = 5000;

# Bech32 decode without BIP-173's 90-char limit (NIP-19 allows up to 5000)
# Reuses polymod/checksum logic from Bitcoin::Crypto::Bech32 internals.
{
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

    sub _nostr_decode_bech32 {
        my ($str) = @_;
        $str = lc $str if uc $str eq $str;
        croak "bech32 string exceeds 5000 character limit" if length($str) > $MAX_BECH32_LENGTH;
        croak "bech32 string contains mixed case" if lc($str) ne $str;

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

# TLV type constants
my $TLV_SPECIAL = 0;
my $TLV_RELAY   = 1;
my $TLV_AUTHOR  = 2;
my $TLV_KIND    = 3;

###############################################################################
# Bare keys and ids
###############################################################################

sub encode_npub {
    my ($hex) = @_;
    croak "pubkey must be 64-char lowercase hex" unless defined $hex && $hex =~ $HEX64;
    return _encode_bare('npub', $hex);
}

sub decode_npub {
    my ($bech32) = @_;
    return _decode_bare('npub', $bech32);
}

sub encode_nsec {
    my ($hex) = @_;
    croak "private key must be 64-char lowercase hex" unless defined $hex && $hex =~ $HEX64;
    return _encode_bare('nsec', $hex);
}

sub decode_nsec {
    my ($bech32) = @_;
    return _decode_bare('nsec', $bech32);
}

sub encode_note {
    my ($hex) = @_;
    croak "event id must be 64-char lowercase hex" unless defined $hex && $hex =~ $HEX64;
    return _encode_bare('note', $hex);
}

sub decode_note {
    my ($bech32) = @_;
    return _decode_bare('note', $bech32);
}

sub _encode_bare {
    my ($hrp, $hex) = @_;
    my $bytes = pack 'H*', $hex;
    my $data5 = translate_8to5($bytes);
    return encode_bech32($hrp, $data5, 'bech32');
}

sub _decode_bare {
    my ($expected_hrp, $bech32) = @_;
    my ($hrp, $data5) = _nostr_decode_bech32($bech32);
    croak "expected $expected_hrp prefix, got $hrp" unless $hrp eq $expected_hrp;
    my $bytes = translate_5to8($data5);
    croak "$expected_hrp payload must be exactly 32 bytes, got " . length($bytes)
        unless length($bytes) == 32;
    return unpack 'H*', $bytes;
}

###############################################################################
# TLV encoding/decoding helpers
###############################################################################

sub _encode_tlv {
    my ($hrp, @tlvs) = @_;
    my $payload = '';
    for my $tlv (@tlvs) {
        my ($type, $value) = @$tlv;
        $payload .= pack('CC', $type, length($value)) . $value;
    }
    my $data5 = translate_8to5($payload);
    my $encoded = encode_bech32($hrp, $data5, 'bech32');
    croak "bech32 string exceeds 5000 character limit"
        if length($encoded) > $MAX_BECH32_LENGTH;
    return $encoded;
}

sub _decode_tlv {
    my ($expected_hrp, $bech32) = @_;
    my ($hrp, $data5) = _nostr_decode_bech32($bech32);
    croak "expected $expected_hrp prefix, got $hrp" unless $hrp eq $expected_hrp;
    my $payload = translate_5to8($data5);
    my @tlvs;
    my $pos = 0;
    while ($pos < length($payload)) {
        croak "truncated TLV: missing length byte at offset $pos"
            unless $pos + 1 < length($payload);
        my $type = unpack('C', substr($payload, $pos, 1));
        my $len  = unpack('C', substr($payload, $pos + 1, 1));
        croak "truncated TLV: value extends beyond payload at offset $pos"
            unless $pos + 2 + $len <= length($payload);
        my $val  = substr($payload, $pos + 2, $len);
        push @tlvs, [$type, $val];
        $pos += 2 + $len;
    }
    return @tlvs;
}

###############################################################################
# nprofile
###############################################################################

sub encode_nprofile {
    my (%args) = @_;
    my $pubkey = $args{pubkey} // croak "nprofile requires 'pubkey'";
    croak "pubkey must be 64-char lowercase hex" unless $pubkey =~ $HEX64;
    my @tlvs;
    push @tlvs, [$TLV_SPECIAL, pack('H*', $pubkey)];
    for my $relay (@{$args{relays} // []}) {
        push @tlvs, [$TLV_RELAY, $relay];
    }
    return _encode_tlv('nprofile', @tlvs);
}

sub decode_nprofile {
    my ($bech32) = @_;
    my @tlvs = _decode_tlv('nprofile', $bech32);
    my %result = (relays => []);
    for my $tlv (@tlvs) {
        my ($type, $val) = @$tlv;
        if ($type == $TLV_SPECIAL) {
            croak "nprofile: pubkey (type 0) must be exactly 32 bytes, got " . length($val)
                unless length($val) == 32;
            $result{pubkey} = unpack 'H*', $val;
        } elsif ($type == $TLV_RELAY) {
            push @{$result{relays}}, $val;
        }
        # ignore unknown types per spec
    }
    croak "nprofile: missing required pubkey (type 0)" unless defined $result{pubkey};
    return \%result;
}

###############################################################################
# nevent
###############################################################################

sub encode_nevent {
    my (%args) = @_;
    my $id = $args{id} // croak "nevent requires 'id'";
    croak "id must be 64-char lowercase hex" unless $id =~ $HEX64;
    my @tlvs;
    push @tlvs, [$TLV_SPECIAL, pack('H*', $id)];
    for my $relay (@{$args{relays} // []}) {
        push @tlvs, [$TLV_RELAY, $relay];
    }
    if (defined $args{author}) {
        croak "author must be 64-char lowercase hex" unless $args{author} =~ $HEX64;
        push @tlvs, [$TLV_AUTHOR, pack('H*', $args{author})];
    }
    if (defined $args{kind}) {
        push @tlvs, [$TLV_KIND, pack('N', $args{kind})];
    }
    return _encode_tlv('nevent', @tlvs);
}

sub decode_nevent {
    my ($bech32) = @_;
    my @tlvs = _decode_tlv('nevent', $bech32);
    my %result = (relays => []);
    for my $tlv (@tlvs) {
        my ($type, $val) = @$tlv;
        if ($type == $TLV_SPECIAL) {
            croak "nevent: event id (type 0) must be exactly 32 bytes, got " . length($val)
                unless length($val) == 32;
            $result{id} = unpack 'H*', $val;
        } elsif ($type == $TLV_RELAY) {
            push @{$result{relays}}, $val;
        } elsif ($type == $TLV_AUTHOR) {
            croak "nevent: author (type 2) must be exactly 32 bytes, got " . length($val)
                unless length($val) == 32;
            $result{author} = unpack 'H*', $val;
        } elsif ($type == $TLV_KIND) {
            croak "nevent: kind (type 3) must be exactly 4 bytes, got " . length($val)
                unless length($val) == 4;
            $result{kind} = unpack 'N', $val;
        }
    }
    croak "nevent: missing required event id (type 0)" unless defined $result{id};
    return \%result;
}

###############################################################################
# naddr
###############################################################################

sub encode_naddr {
    my (%args) = @_;
    croak "naddr requires 'identifier'" unless defined $args{identifier};
    my $pubkey = $args{pubkey} // croak "naddr requires 'pubkey'";
    croak "pubkey must be 64-char lowercase hex" unless $pubkey =~ $HEX64;
    my $kind = $args{kind} // croak "naddr requires 'kind'";

    my @tlvs;
    push @tlvs, [$TLV_SPECIAL, $args{identifier}];
    for my $relay (@{$args{relays} // []}) {
        push @tlvs, [$TLV_RELAY, $relay];
    }
    push @tlvs, [$TLV_AUTHOR, pack('H*', $pubkey)];
    push @tlvs, [$TLV_KIND, pack('N', $kind)];
    return _encode_tlv('naddr', @tlvs);
}

sub decode_naddr {
    my ($bech32) = @_;
    my @tlvs = _decode_tlv('naddr', $bech32);
    my %result = (relays => []);
    for my $tlv (@tlvs) {
        my ($type, $val) = @$tlv;
        if ($type == $TLV_SPECIAL) {
            $result{identifier} = $val;
        } elsif ($type == $TLV_RELAY) {
            push @{$result{relays}}, $val;
        } elsif ($type == $TLV_AUTHOR) {
            croak "naddr: pubkey (type 2) must be exactly 32 bytes, got " . length($val)
                unless length($val) == 32;
            $result{pubkey} = unpack 'H*', $val;
        } elsif ($type == $TLV_KIND) {
            croak "naddr: kind (type 3) must be exactly 4 bytes, got " . length($val)
                unless length($val) == 4;
            $result{kind} = unpack 'N', $val;
        }
    }
    croak "naddr: missing required identifier (type 0)" unless defined $result{identifier};
    croak "naddr: missing required pubkey (type 2)" unless defined $result{pubkey};
    croak "naddr: missing required kind (type 3)" unless defined $result{kind};
    return \%result;
}

###############################################################################
# Generic decode
###############################################################################

my %BARE_TYPES  = map { $_ => 1 } qw(npub nsec note);
my %TLV_DECODERS = (
    nprofile => \&decode_nprofile,
    nevent   => \&decode_nevent,
    naddr    => \&decode_naddr,
);

sub decode_bech32_entity {
    my ($bech32) = @_;
    my ($hrp) = _nostr_decode_bech32($bech32);

    if ($BARE_TYPES{$hrp}) {
        my $hex = _decode_bare($hrp, $bech32);
        return { type => $hrp, data => $hex };
    }

    if (my $decoder = $TLV_DECODERS{$hrp}) {
        return { type => $hrp, data => $decoder->($bech32) };
    }

    croak "unknown bech32 entity prefix: $hrp";
}

###############################################################################
# NIP-21: nostr: URI scheme
###############################################################################

my %NOSTR_URI_TYPES = map { $_ => 1 } qw(npub note nprofile nevent naddr);

sub encode_nostr_uri {
    my ($bech32) = @_;
    croak "bech32 string required" unless defined $bech32 && length $bech32;
    my ($hrp) = _nostr_decode_bech32($bech32);
    croak "nsec must not be used in nostr: URIs" if $hrp eq 'nsec';
    croak "unsupported bech32 prefix for nostr: URI: $hrp"
        unless $NOSTR_URI_TYPES{$hrp};
    return "nostr:$bech32";
}

sub decode_nostr_uri {
    my ($uri) = @_;
    croak "nostr: URI required" unless defined $uri && length $uri;
    croak "nostr: URI must start with nostr:" unless $uri =~ /\Anostr:/i;
    my $bech32 = substr($uri, 6);
    my ($hrp) = _nostr_decode_bech32($bech32);
    croak "nsec must not be used in nostr: URIs" if $hrp eq 'nsec';
    return decode_bech32_entity($bech32);
}

1;

__END__

=head1 NAME

Net::Nostr::Bech32 - NIP-19 bech32-encoded entities

=head1 SYNOPSIS

    use Net::Nostr::Bech32 qw(
        encode_npub decode_npub
        encode_nsec decode_nsec
        encode_note decode_note
        encode_nprofile decode_nprofile
        encode_nevent   decode_nevent
        encode_naddr    decode_naddr
        decode_bech32_entity
        encode_nostr_uri decode_nostr_uri
    );

    # Bare keys and ids
    my $npub = encode_npub('7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e');
    # npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg

    my $hex = decode_npub($npub);
    # 7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e

    my $nsec = encode_nsec($privkey_hex);
    my $note = encode_note($event_id_hex);

    # TLV entities with metadata
    my $nprofile = encode_nprofile(
        pubkey => $hex_pubkey,
        relays => ['wss://relay1.com', 'wss://relay2.com'],
    );
    my $data = decode_nprofile($nprofile);
    # { pubkey => '...', relays => ['wss://relay1.com', 'wss://relay2.com'] }

    my $nevent = encode_nevent(
        id     => $event_id_hex,
        relays => ['wss://relay.com'],
        author => $pubkey_hex,
        kind   => 1,
    );
    my $data = decode_nevent($nevent);
    # { id => '...', relays => [...], author => '...', kind => 1 }

    my $naddr = encode_naddr(
        identifier => 'my-article',
        pubkey     => $hex_pubkey,
        kind       => 30023,
        relays     => ['wss://relay.com'],
    );
    my $data = decode_naddr($naddr);
    # { identifier => 'my-article', pubkey => '...', kind => 30023, relays => [...] }

    # Auto-detect and decode any NIP-19 entity
    my $result = decode_bech32_entity($any_bech32_string);
    say $result->{type};  # 'npub', 'nsec', 'note', 'nprofile', 'nevent', 'naddr'
    say $result->{data};  # hex string for bare types, hashref for TLV types

=head1 DESCRIPTION

Implements NIP-19 bech32-encoded entities for human-friendly display of
Nostr keys, event IDs, and shareable identifiers with metadata.

These encodings are for display and sharing only. They MUST NOT be used
in NIP-01 event fields or filters - use hex format there.

Uses bech32 (not bech32m) encoding per the NIP-19 specification.

=head1 FUNCTIONS

All functions are exportable. None are exported by default.

=head2 encode_npub

    my $npub = encode_npub($hex_pubkey);

Encodes a 64-char hex public key as an C<npub> bech32 string.

    my $npub = encode_npub('7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e');
    # npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg

=head2 decode_npub

    my $hex = decode_npub($npub);

Decodes an C<npub> bech32 string to a 64-char hex public key. Croaks if
the prefix is not C<npub>.

    my $hex = decode_npub('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg');
    # 7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e

=head2 encode_nsec

    my $nsec = encode_nsec($hex_privkey);

Encodes a 64-char hex private key as an C<nsec> bech32 string.

    my $nsec = encode_nsec('67dea2ed018072d675f5415ecfaed7d2597555e202d85b3d65ea4e58d2d92ffa');
    # nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5

=head2 decode_nsec

    my $hex = decode_nsec($nsec);

Decodes an C<nsec> bech32 string to a 64-char hex private key. Croaks if
the prefix is not C<nsec>.

=head2 encode_note

    my $note = encode_note($hex_event_id);

Encodes a 64-char hex event ID as a C<note> bech32 string.

    my $note = encode_note('a' x 64);

=head2 decode_note

    my $hex = decode_note($note);

Decodes a C<note> bech32 string to a 64-char hex event ID. Croaks if
the prefix is not C<note>.

=head2 encode_nprofile

    my $nprofile = encode_nprofile(pubkey => $hex, relays => \@relays);

Encodes a profile identifier with optional relay hints using TLV format.
C<pubkey> is required. C<relays> is optional.

    my $nprofile = encode_nprofile(
        pubkey => '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d',
        relays => ['wss://r.x.com', 'wss://djbas.sadkb.com'],
    );

=head2 decode_nprofile

    my $data = decode_nprofile($nprofile);
    # { pubkey => '...', relays => [...] }

Decodes an C<nprofile> bech32 string. Returns a hashref with C<pubkey>
and C<relays> (arrayref, possibly empty). Unknown TLV types are ignored.

=head2 encode_nevent

    my $nevent = encode_nevent(id => $hex, relays => \@r, author => $hex, kind => $int);

Encodes an event identifier with optional metadata. C<id> is required.
C<relays>, C<author>, and C<kind> are optional.

    my $nevent = encode_nevent(
        id     => $event_id,
        relays => ['wss://relay.com'],
        author => $pubkey_hex,
        kind   => 1,
    );

=head2 decode_nevent

    my $data = decode_nevent($nevent);
    # { id => '...', relays => [...], author => '...' or undef, kind => N or undef }

Decodes an C<nevent> bech32 string. Returns a hashref. C<author> and
C<kind> are C<undef> if not present in the encoding.

=head2 encode_naddr

    my $naddr = encode_naddr(
        identifier => $d_tag, pubkey => $hex, kind => $int, relays => \@r,
    );

Encodes an addressable event coordinate. C<identifier>, C<pubkey>, and
C<kind> are required. C<relays> is optional. Use empty string for
C<identifier> for normal replaceable events.

    my $naddr = encode_naddr(
        identifier => 'my-article',
        pubkey     => $pubkey_hex,
        kind       => 30023,
    );

=head2 decode_naddr

    my $data = decode_naddr($naddr);
    # { identifier => '...', pubkey => '...', kind => N, relays => [...] }

Decodes an C<naddr> bech32 string.

=head2 decode_bech32_entity

    my $result = decode_bech32_entity($bech32_string);
    say $result->{type};  # 'npub', 'nsec', 'note', 'nprofile', 'nevent', 'naddr'
    say $result->{data};  # hex string or hashref

Auto-detects the entity type from the bech32 prefix and decodes it.
For bare types (C<npub>, C<nsec>, C<note>), C<data> is a hex string.
For TLV types (C<nprofile>, C<nevent>, C<naddr>), C<data> is a hashref.

    my $r = decode_bech32_entity('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg');
    say $r->{type};  # 'npub'
    say $r->{data};  # '7e7e9c42...'

=head2 encode_nostr_uri

    my $uri = encode_nostr_uri($bech32_string);

Wraps a NIP-19 bech32 string with the C<nostr:> URI scheme (NIP-21).
Accepts C<npub>, C<note>, C<nprofile>, C<nevent>, and C<naddr>.
Croaks if the input is an C<nsec> (private keys must not appear in URIs)
or an unrecognized bech32 prefix.

    my $npub = encode_npub('7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e');
    my $uri = encode_nostr_uri($npub);
    # nostr:npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg

=head2 decode_nostr_uri

    my $result = decode_nostr_uri($nostr_uri);
    say $result->{type};  # 'npub', 'note', 'nprofile', 'nevent', 'naddr'
    say $result->{data};  # hex string or hashref

Strips the C<nostr:> prefix and decodes the NIP-19 bech32 entity.
The prefix match is case-insensitive. Returns the same structure as
C<decode_bech32_entity>. Croaks if the URI contains an C<nsec> or
is missing the C<nostr:> prefix.

    my $result = decode_nostr_uri('nostr:npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9');
    say $result->{type};  # 'npub'
    say $result->{data};  # '84dee6e676e5bb67b4ad4e042cf70cbd8681155db535942fcc6a0533858a7240'

=head1 SEE ALSO

L<NIP-19|https://github.com/nostr-protocol/nips/blob/master/19.md>,
L<NIP-21|https://github.com/nostr-protocol/nips/blob/master/21.md>,
L<Net::Nostr>, L<Net::Nostr::Key>, L<Bitcoin::Crypto::Bech32>

=cut
