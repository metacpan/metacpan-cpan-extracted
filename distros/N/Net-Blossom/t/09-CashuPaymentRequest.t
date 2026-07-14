use strictures 2;

use Test::More;
use CBOR::Free ();
use Encode qw(encode);
use MIME::Base64 qw(encode_base64);

use Net::Blossom::_CashuPaymentRequest ();

my $CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
my @GENERATOR = (0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3);
my $BECH32M_CHECKSUM = 0x2bc830a3;

sub polymod {
    my (@values) = @_;
    my $checksum = 1;

    for my $value (@values) {
        my $top = $checksum >> 25;
        $checksum = (($checksum & 0x1ffffff) << 5) ^ $value;
        for my $i (0 .. 4) {
            $checksum ^= $GENERATOR[$i] if (($top >> $i) & 1);
        }
    }

    return $checksum;
}

sub hrp_expand {
    my ($hrp) = @_;
    my @chars = split //, $hrp;
    return ((map { ord($_) >> 5 } @chars), 0, (map { ord($_) & 31 } @chars));
}

sub words_from_bytes {
    my ($bytes) = @_;
    my ($accumulator, $bits) = (0, 0);
    my @words;

    for my $byte (unpack 'C*', $bytes) {
        $accumulator = (($accumulator << 8) | $byte) & 0xfff;
        $bits += 8;
        while ($bits >= 5) {
            $bits -= 5;
            push @words, ($accumulator >> $bits) & 31;
        }
    }
    push @words, ($accumulator << (5 - $bits)) & 31 if $bits;
    return @words;
}

sub cashu_b {
    my ($bytes, %opts) = @_;
    my $hrp = $opts{hrp} || 'creqb';
    my $constant = exists $opts{checksum} ? $opts{checksum} : $BECH32M_CHECKSUM;
    my @words = words_from_bytes($bytes);
    my $polymod = polymod(hrp_expand($hrp), @words, (0) x 6) ^ $constant;
    my @checksum = map { ($polymod >> (5 * (5 - $_))) & 31 } 0 .. 5;
    return $hrp . '1' . join '', map { substr($CHARSET, $_, 1) } @words, @checksum;
}

sub tlv {
    my ($type, $value) = @_;
    return chr($type) . pack('n', length($value)) . $value;
}

sub tag_tuple {
    my ($key, @values) = @_;
    return chr(length($key)) . $key
        . join('', map { chr(length($_)) . $_ } @values);
}

sub valid_tlv_request {
    return join '',
        tlv(0x02, pack('Q>', 1000)),
        tlv(0x03, "\0"),
        tlv(0x05, 'https://mint.example.com');
}

sub cashu_a {
    my ($request) = @_;
    my $bytes = CBOR::Free::encode($request, string_encode_mode => 'as_text');
    return cashu_a_bytes($bytes);
}

sub cashu_a_bytes {
    my ($bytes) = @_;
    my $encoded = encode_base64($bytes, '');
    $encoded =~ tr{+/}{-_};
    return 'creqA' . $encoded;
}

sub cbor_item {
    my ($value) = @_;
    return CBOR::Free::encode($value, string_encode_mode => 'as_text');
}

sub valid_cbor_request {
    return {
        a => 1000,
        u => 'sat',
        m => ['https://mint.example.com'],
    };
}

subtest 'NUT-26 validates the Bech32m envelope' => sub {
    my $valid = cashu_b(valid_tlv_request());
    ok(Net::Blossom::_CashuPaymentRequest::valid($valid), 'valid request');
    ok(Net::Blossom::_CashuPaymentRequest::valid(uc $valid), 'uppercase request');

    my $mixed = $valid;
    substr $mixed, 0, 1, 'C';
    ok(!Net::Blossom::_CashuPaymentRequest::valid($mixed), 'mixed case rejected');

    my $bad_checksum = $valid;
    substr $bad_checksum, -1, 1, substr($bad_checksum, -1) eq 'q' ? 'p' : 'q';
    ok(!Net::Blossom::_CashuPaymentRequest::valid($bad_checksum), 'bad checksum rejected');
    ok(!Net::Blossom::_CashuPaymentRequest::valid(
        cashu_b(valid_tlv_request(), checksum => 1)), 'Bech32 checksum rejected');
    ok(!Net::Blossom::_CashuPaymentRequest::valid(
        cashu_b(valid_tlv_request(), hrp => 'other')), 'wrong HRP rejected');
};

subtest 'NUT-26 validates required HTTP payment fields' => sub {
    my @cases = (
        ['missing amount', tlv(0x03, "\0") . tlv(0x05, 'https://mint.example.com')],
        ['zero amount', tlv(0x02, "\0" x 8) . tlv(0x03, "\0") . tlv(0x05, 'https://mint.example.com')],
        ['short amount', tlv(0x02, "\1") . tlv(0x03, "\0") . tlv(0x05, 'https://mint.example.com')],
        ['duplicate amount', valid_tlv_request() . tlv(0x02, pack('Q>', 1))],
        ['missing unit', tlv(0x02, pack('Q>', 1)) . tlv(0x05, 'https://mint.example.com')],
        ['empty unit', tlv(0x02, pack('Q>', 1)) . tlv(0x03, '') . tlv(0x05, 'https://mint.example.com')],
        ['invalid UTF-8 unit', tlv(0x02, pack('Q>', 1)) . tlv(0x03, "\xff") . tlv(0x05, 'https://mint.example.com')],
        ['duplicate unit', valid_tlv_request() . tlv(0x03, "\0")],
        ['missing mint', tlv(0x02, pack('Q>', 1)) . tlv(0x03, "\0")],
        ['invalid mint URL', tlv(0x02, pack('Q>', 1)) . tlv(0x03, "\0") . tlv(0x05, 'not a URL')],
        ['invalid UTF-8 mint', tlv(0x02, pack('Q>', 1)) . tlv(0x03, "\0") . tlv(0x05, "\xff")],
        ['truncated TLV header', valid_tlv_request() . "\x01\x00"],
        ['truncated TLV value', valid_tlv_request() . "\x01\x00\x02x"],
    );

    for my $case (@cases) {
        ok(!Net::Blossom::_CashuPaymentRequest::valid(cashu_b($case->[1])), "$case->[0] rejected");
    }

    ok(Net::Blossom::_CashuPaymentRequest::valid(cashu_b(
        valid_tlv_request() . tlv(0x05, 'https://second.example.com'))),
        'multiple mints accepted');
    ok(Net::Blossom::_CashuPaymentRequest::valid(cashu_b(
        valid_tlv_request() . tlv(0xff, 'future'))),
        'unknown tag ignored');
};

subtest 'NUT-26 validates typed optional fields' => sub {
    my @cases = (
        ['invalid UTF-8 id', tlv(0x01, "\xff")],
        ['duplicate id', tlv(0x01, 'one') . tlv(0x01, 'two')],
        ['invalid single-use size', tlv(0x04, '')],
        ['invalid single-use value', tlv(0x04, "\x02")],
        ['duplicate single-use', tlv(0x04, "\x01") . tlv(0x04, "\x00")],
        ['invalid UTF-8 description', tlv(0x06, "\xff")],
        ['duplicate description', tlv(0x06, 'one') . tlv(0x06, 'two')],
        ['malformed transport', tlv(0x07, tlv(0x01, "\x01"))],
        ['unknown transport kind', tlv(0x07,
            tlv(0x01, "\x02") . tlv(0x02, 'target'))],
        ['invalid UTF-8 transport target', tlv(0x07,
            tlv(0x01, "\x01") . tlv(0x02, "\xff"))],
        ['malformed transport tags', tlv(0x07,
            tlv(0x01, "\x01") . tlv(0x02, 'https://merchant.example.com/pay') . tlv(0x03, "\x01k"))],
        ['malformed nut10', tlv(0x08, tlv(0x01, "\x00"))],
        ['malformed nut10 tags', tlv(0x08,
            tlv(0x01, "\x00") . tlv(0x02, 'key') . tlv(0x03, "\x01k"))],
        ['duplicate nut10', tlv(0x08, '') . tlv(0x08, '')],
    );

    for my $case (@cases) {
        ok(!Net::Blossom::_CashuPaymentRequest::valid(cashu_b(
            valid_tlv_request() . $case->[1])), "$case->[0] rejected");
    }

    ok(Net::Blossom::_CashuPaymentRequest::valid(cashu_b(
        valid_tlv_request()
            . tlv(0x01, 'invoice-1')
            . tlv(0x04, "\x01")
            . tlv(0x06, encode('UTF-8', 'coffee'))
            . tlv(0x07,
                tlv(0x01, "\x01")
                    . tlv(0x02, 'https://merchant.example.com/pay')
                    . tlv(0x03, tag_tuple('h', 'value')))
            . tlv(0x08,
                tlv(0x01, "\x00")
                    . tlv(0x02, 'key')
                    . tlv(0x03, tag_tuple('sigflag', 'SIG_ALL'))))),
        'valid optional fields accepted');
    ok(Net::Blossom::_CashuPaymentRequest::valid(cashu_b(
        valid_tlv_request()
            . tlv(0x07, tlv(0x01, "\x00") . tlv(0x02, "x" x 32)))),
        'valid Nostr transport accepted');
};

subtest 'NUT-18 validates typed optional fields' => sub {
    my $valid = valid_cbor_request();
    $valid->{i} = 'invoice-1';
    $valid->{s} = CBOR::Free::true();
    $valid->{d} = 'coffee';
    $valid->{t} = [{ t => 'post', a => 'https://merchant.example.com/pay' }];
    ok(Net::Blossom::_CashuPaymentRequest::valid(cashu_a($valid)),
        'valid optional fields accepted');

    my @cases = (
        ['numeric id', i => 1],
        ['text single-use', s => 'true'],
        ['numeric description', d => 1],
        ['scalar transports', t => 'post'],
        ['malformed transport', t => [{ t => 'post' }]],
        ['malformed transport tags', t => [{ t => 'post', a => 'https://merchant.example.com/pay', g => [['n']] }]],
    );

    for my $case (@cases) {
        my ($name, $key, $value) = @$case;
        my $request = valid_cbor_request();
        $request->{$key} = $value;
        ok(!Net::Blossom::_CashuPaymentRequest::valid(cashu_a($request)), "$name rejected");
    }

    my $nut10 = valid_cbor_request();
    $nut10->{nut10} = {
        k => 'P2PK',
        d => 'key',
        t => [['sigflag', 'SIG_ALL']],
    };
    ok(Net::Blossom::_CashuPaymentRequest::valid(cashu_a($nut10)),
        'valid NUT-10 option accepted');

    my @nut10_cases = (
        ['non-map NUT-10 option', []],
        ['missing NUT-10 kind', { d => 'key' }],
        ['missing NUT-10 data', { k => 'P2PK' }],
        ['non-array NUT-10 tags', { k => 'P2PK', d => 'key', t => 'tag' }],
        ['malformed NUT-10 tag', { k => 'P2PK', d => 'key', t => [['sigflag']] }],
        ['numeric NUT-10 tag value', { k => 'P2PK', d => 'key', t => [['sigflag', 1]] }],
    );
    for my $case (@nut10_cases) {
        my $request = valid_cbor_request();
        $request->{nut10} = $case->[1];
        ok(!Net::Blossom::_CashuPaymentRequest::valid(cashu_a($request)), "$case->[0] rejected");
    }

    ok(!Net::Blossom::_CashuPaymentRequest::valid(cashu_a(
        CBOR::Free::tag(42, valid_cbor_request()))),
        'tagged CBOR request rejected');
};

subtest 'NUT-18 rejects duplicate CBOR map keys' => sub {
    my $bytes = join '',
        "\xa4",
        cbor_item('a'), cbor_item(1000),
        cbor_item('u'), cbor_item('sat'),
        cbor_item('m'), cbor_item(['https://mint.example.com']),
        cbor_item('a'), cbor_item(1);

    ok(!Net::Blossom::_CashuPaymentRequest::valid(cashu_a_bytes($bytes)),
        'duplicate amount rejected');
};

done_testing;
