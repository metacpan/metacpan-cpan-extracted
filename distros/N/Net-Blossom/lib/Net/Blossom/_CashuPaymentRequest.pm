package Net::Blossom::_CashuPaymentRequest;

use strictures 2;

use B ();
use CBOR::Free::Decoder ();
use Encode qw(decode FB_CROAK);
use MIME::Base64 qw(decode_base64);
use Net::Blossom::_Bech32 ();
use Net::Blossom::_URL ();

my $BECH32M_CHECKSUM = 0x2bc830a3;

sub valid {
    my ($payload) = @_;
    return 0 unless defined $payload && !ref($payload) && length $payload;

    return _valid_cbor(substr($payload, 5))
        if substr($payload, 0, 5) =~ /\Acreqa\z/i;
    return _valid_tlv($payload)
        if substr($payload, 0, 6) =~ /\Acreqb1\z/i;
    return 0;
}

sub _valid_cbor {
    my ($encoded) = @_;
    my $bytes = _decode_base64url($encoded);
    return 0 unless defined $bytes && length $bytes;

    my (@warnings, $request);
    my $ok = eval {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $decoder = CBOR::Free::Decoder->new();
        $decoder->reject_duplicate_keys();
        $request = $decoder->decode($bytes);
        1;
    };
    return 0 unless $ok && !@warnings && ref($request) eq 'HASH';
    return 0 if grep { !_text($_) } keys %$request;
    return _valid_request($request);
}

sub _valid_tlv {
    my ($payload) = @_;
    my ($hrp, $words) = Net::Blossom::_Bech32::decode($payload, $BECH32M_CHECKSUM);
    return 0 unless defined $hrp && $hrp eq 'creqb';

    my $bytes = Net::Blossom::_Bech32::convert_5_to_8($words);
    return 0 unless defined $bytes;
    my $entries = _tlv_entries($bytes);
    return 0 unless defined $entries;

    my @amount = grep { $_->[0] == 0x02 } @$entries;
    return 0 unless @amount == 1 && length($amount[0][1]) == 8;
    return 0 unless grep { $_ ne "\0" } split //, $amount[0][1];

    my @unit = grep { $_->[0] == 0x03 } @$entries;
    return 0 unless @unit == 1;
    if ($unit[0][1] ne "\0") {
        my $unit = _utf8($unit[0][1]);
        return 0 unless defined $unit && length $unit;
    }

    my @mints = grep { $_->[0] == 0x05 } @$entries;
    return 0 unless @mints;
    for my $entry (@mints) {
        my $mint = _utf8($entry->[1]);
        return 0 unless defined $mint && Net::Blossom::_URL::http_base_url($mint);
    }

    my @id = grep { $_->[0] == 0x01 } @$entries;
    return 0 if @id > 1 || @id && !defined _utf8($id[0][1]);

    my @single_use = grep { $_->[0] == 0x04 } @$entries;
    return 0 if @single_use > 1;
    return 0 if @single_use
        && (length($single_use[0][1]) != 1 || ord($single_use[0][1]) > 1);

    my @description = grep { $_->[0] == 0x06 } @$entries;
    return 0 if @description > 1 || @description && !defined _utf8($description[0][1]);

    my @transport = grep { $_->[0] == 0x07 } @$entries;
    return 0 if grep { !_valid_tlv_transport($_->[1]) } @transport;

    my @nut10 = grep { $_->[0] == 0x08 } @$entries;
    return 0 if @nut10 > 1;
    return 0 if @nut10 && !_valid_tlv_nut10($nut10[0][1]);
    return 1;
}

sub _valid_request {
    my ($request) = @_;
    return 0 unless exists $request->{a} && _integer($request->{a}) && $request->{a} > 0;
    return 0 unless exists $request->{u} && _text($request->{u}) && length $request->{u};
    return 0 unless exists $request->{m} && ref($request->{m}) eq 'ARRAY' && @{$request->{m}};

    for my $mint (@{$request->{m}}) {
        return 0 unless _text($mint) && Net::Blossom::_URL::http_base_url($mint);
    }

    return 0 if exists $request->{i} && !_text($request->{i});
    return 0 if exists $request->{s} && !_boolean($request->{s});
    return 0 if exists $request->{d} && !_text($request->{d});

    if (exists $request->{t}) {
        return 0 unless ref($request->{t}) eq 'ARRAY';
        return 0 if grep { !_valid_cbor_transport($_) } @{$request->{t}};
    }

    return 0 if exists $request->{nut10} && !_valid_cbor_nut10($request->{nut10});
    return 1;
}

sub _valid_cbor_transport {
    my ($transport) = @_;
    return 0 unless ref($transport) eq 'HASH';
    return 0 if grep { !_text($_) } keys %$transport;
    return 0 unless exists $transport->{t} && _text($transport->{t});
    return 0 unless exists $transport->{a} && _text($transport->{a});
    return 1 unless exists $transport->{g};
    return 0 unless ref($transport->{g}) eq 'ARRAY';

    for my $tag (@{$transport->{g}}) {
        return 0 unless ref($tag) eq 'ARRAY' && @$tag >= 2;
        return 0 if grep { !_text($_) } @$tag;
    }

    return 1;
}

sub _valid_cbor_nut10 {
    my ($nut10) = @_;
    return 0 unless ref($nut10) eq 'HASH';
    return 0 if grep { !_text($_) } keys %$nut10;
    return 0 unless exists $nut10->{k} && _text($nut10->{k}) && length $nut10->{k};
    return 0 unless exists $nut10->{d} && _text($nut10->{d}) && length $nut10->{d};
    return 1 unless exists $nut10->{t};
    return 0 unless ref($nut10->{t}) eq 'ARRAY';

    for my $tag (@{$nut10->{t}}) {
        return 0 unless ref($tag) eq 'ARRAY' && @$tag == 2;
        return 0 unless _text($tag->[0]) && _text($tag->[1]);
    }

    return 1;
}

sub _valid_tlv_nut10 {
    my ($bytes) = @_;
    my $entries = _tlv_entries($bytes);
    return 0 unless defined $entries;

    my @kind = grep { $_->[0] == 0x01 } @$entries;
    my @data = grep { $_->[0] == 0x02 } @$entries;
    return 0 unless @kind == 1 && length($kind[0][1]) == 1;
    return 0 unless @data == 1 && defined _utf8($data[0][1]);
    return 0 if grep { $_->[0] == 0x03 && !_valid_tag_tuple($_->[1]) } @$entries;
    return 1;
}

sub _valid_tlv_transport {
    my ($bytes) = @_;
    my $entries = _tlv_entries($bytes);
    return 0 unless defined $entries;

    my @kind = grep { $_->[0] == 0x01 } @$entries;
    my @target = grep { $_->[0] == 0x02 } @$entries;
    return 0 unless @kind == 1 && length($kind[0][1]) == 1;
    return 0 unless @target == 1;
    return 0 if grep { $_->[0] == 0x03 && !_valid_tag_tuple($_->[1]) } @$entries;

    my $kind = ord $kind[0][1];
    return length($target[0][1]) == 32 if $kind == 0;
    return defined _utf8($target[0][1]) if $kind == 1;
    return 0;
}

sub _valid_tag_tuple {
    my ($bytes) = @_;
    return 0 unless length $bytes;

    my $position = 0;
    my $key_length = ord substr($bytes, $position++, 1);
    return 0 if $position + $key_length > length $bytes;
    return 0 unless defined _utf8(substr($bytes, $position, $key_length));
    $position += $key_length;

    my $values = 0;
    while ($position < length $bytes) {
        my $length = ord substr($bytes, $position++, 1);
        return 0 if $position + $length > length $bytes;
        return 0 unless defined _utf8(substr($bytes, $position, $length));
        $position += $length;
        $values++;
    }

    return $values > 0;
}

sub _tlv_entries {
    my ($bytes) = @_;
    my @entries;
    my $position = 0;

    while ($position < length $bytes) {
        return if length($bytes) - $position < 3;
        my $type = ord substr($bytes, $position, 1);
        my $length = unpack 'n', substr($bytes, $position + 1, 2);
        $position += 3;
        return if $position + $length > length $bytes;
        push @entries, [$type, substr($bytes, $position, $length)];
        $position += $length;
    }

    return \@entries;
}

sub _integer {
    my ($value) = @_;
    return 0 if ref($value);
    my $flags = B::svref_2object(\$value)->FLAGS;
    return ($flags & B::SVp_IOK()) && !($flags & (B::SVp_NOK() | B::SVp_POK()));
}

sub _boolean {
    my ($value) = @_;
    return ref($value) && eval { $value->isa('Types::Serialiser::Boolean') } ? 1 : 0;
}

sub _text {
    my ($value) = @_;
    return defined $value && !ref($value) && utf8::is_utf8($value);
}

sub _utf8 {
    my ($bytes) = @_;
    my $text = eval { decode('UTF-8', $bytes, FB_CROAK) };
    return if $@;
    return $text;
}

sub _decode_base64url {
    my ($encoded) = @_;
    return unless defined $encoded && !ref($encoded) && $encoded =~ /\A[A-Za-z0-9_-]+={0,2}\z/;

    $encoded =~ s/=+\z//;
    return if length($encoded) % 4 == 1;
    $encoded =~ tr{-_}{+/};
    $encoded .= '=' while length($encoded) % 4;
    return decode_base64($encoded);
}

1;
