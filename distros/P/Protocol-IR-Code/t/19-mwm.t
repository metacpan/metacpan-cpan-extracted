#!/usr/bin/env perl
use strict;
use warnings;
# 48-bit hex literals exceed the 32-bit range that triggers Perl's
# "portable" warning; MWM frames go well beyond, so the tests compare hex
# strings and Math::BigInt values instead of integer literals.
no warnings 'portable';
use Test::More;
use Math::BigInt;
use File::Basename qw(dirname);
use File::Spec;
use JSON::PP;
use Protocol::IR::Converter;
use Protocol::IR::Code;
use Protocol::IR::Proto::MWM;

# MWM (Disney "Made With Magic" / Glow With The Show) protocol: 2400 bps
# serial over 38 kHz, 3-18 byte frames (24-144 bits) with no header, each
# byte a 417 us start mark + 8 LSB-first data bits (space = 1) + a 417 us
# stop space. The frame length is implied by the message body: command frames
# carry a 4-bit payload length in the high nibble of byte 0 (0x9x/0xFx), and
# show commands open with 0x55 0xAA. Tasmota's "Data" field is the display
# form (the transmitted bytes as-is), so no byte-order translation applies.
# Frames can exceed the native integer range, so MWM data is a Math::BigInt.

my $converter = Protocol::IR::Converter->new();

sub assert_mwm {
    my ($code, $hex, $bits, $label) = @_;
    isa_ok($code, 'Protocol::IR::Code', $label);
    is($code->protocol, 'MWM', "$label protocol");
    is($code->bits, $bits, "$label bits");
    is($code->data->as_hex, '0x' . lc($hex), "$label data value");
}

# --- decode_raw sizes the frame from the value width -----------------------
my $p = 'Protocol::IR::Proto::MWM';

assert_mwm($p->decode_raw('0x550808'), '550808', 24, 'decode_raw 24-bit show command');
assert_mwm($p->decode_raw('0x96190B09088418014D'), '96190B09088418014D', 72, 'decode_raw 72-bit frame');
assert_mwm($p->decode_raw('0x9C260CD5636B58EE4803D13C070685'), '9C260CD5636B58EE4803D13C070685', 120, 'decode_raw 120-bit frame');

# A bare 2-byte value still builds a 3-byte (24-bit) frame.
assert_mwm($p->decode_raw('0x5508'), '5508', 24, 'decode_raw pads to 3-byte minimum');

# 144-bit maximum frame.
my $max_hex = 'FF' x 18;
assert_mwm($p->decode_raw('0x' . $max_hex), $max_hex, 144, 'decode_raw 144-bit maximum frame');

# Numeric input and the params path feed the same decoder.
assert_mwm($converter->import_code('MWM', 0x550808), '550808', 24, 'numeric MWM import');
assert_mwm($converter->import_code('MWM', { data => '0x550808' }), '550808', 24, 'params MWM import');
eval { $p->decode_params() };
like($@, qr/MWM requires a data value/, 'decode_params without data dies');
eval { $p->decode_raw('-1') };
like($@, qr/non-negative/, 'negative MWM data dies');

# --- MWM values round-trip through Pronto -----------------------------------
my @pronto_cases = (
    ['550808', 24],
    ['F00000', 24],
    ['96190B09088418014D', 72],
    ['900F00000000000000', 72],
    ['961800000000000000', 72],
    ['98FDD23500F2010220668B', 88],
    ['9C260CD5636B58EE4803D13C070685', 120],
    [$max_hex, 144],
);
for my $case (@pronto_cases) {
    my ($hex, $bits) = @$case;
    my $orig  = $converter->import_code('MWM', '0x' . $hex);
    my $pronto = $converter->export_code($orig, 'Pronto');
    like($pronto, qr/^0000 006D /, "0x$hex carries the 38 kHz frequency word");
    is($orig->data->as_hex, '0x' . lc($hex), "0x$hex data survives Pronto export");
    my $back = $converter->import_format('Pronto', $pronto);
    assert_mwm($back, $hex, $bits, "0x$hex Pronto roundtrip");
}

# The strict payload-length check rejects a truncated 0x9x frame: 64 bits of
# 0x96 demand a 72-bit frame.
my @short_pairs = @{ convert_pronto_to_pairs($converter->export_code(
    $converter->import_code('MWM', '0x' . '96' x 8), 'Pronto')) };
is(Protocol::IR::Proto::MWM->decode_timing(\@short_pairs), undef,
    'truncated 64-bit 0x96 frame is rejected');

# --- MWM timing decode recovers every validated Tasmota capture --------------
my $fixture = File::Spec->rel2abs(File::Spec->catfile(
    dirname(__FILE__), 'data', 'mwm-tasmota-captures.log'));
ok(-e $fixture, 't/data/mwm-tasmota-captures.log present');
open my $fh, '<', $fixture or die "Cannot open $fixture: $!\n";
my ($structured, $matched) = (0, 0);
my $recovered = 0;
while (my $line = <$fh>) {
    next unless $line =~ /"Protocol":"MWM"/;
    my ($json) = $line =~ /RESULT (\{.*\})/;
    my $rec;
    eval { $rec = decode_json($json)->{IrReceived}; 1 } or next;
    $structured++;
    my $via = eval { $converter->import_format('Tasmota', $rec->{RawData})->[0] };
    my $want = $rec->{Data};
    $want =~ s/^0x//i;
    if ($via && $via->protocol eq 'MWM' && $via->bits == $rec->{Bits}
        && lc($via->data->as_hex) eq '0x' . lc($want)) {
        $matched++;
    } elsif ($via && $via->protocol eq 'MWM') {
        # The 0x96 record at Bits:64 (8 bytes) is a footerless capture whose
        # header demands 72 bits. The decoder now back-fills the merged
        # trailing space bits and completes it to a CRC-valid 0x96 frame, so
        # it no longer matches the log's 8-byte (conservatively-truncated)
        # Data value.
        $recovered++;
        is($via->bits, 72, 'truncated 0x96 capture recovers to 72 bits');
        is(lc($via->data->as_hex), '0x96190d2d1622301138',
            'truncated 0x96 capture recovers a CRC-valid frame');
    } else {
        is($via->protocol, 'UNKNOWN', 'rejected frame stays UNKNOWN');
    }
}
is($structured, 38, 'the capture log carries 38 MWM records');
is($matched, 37, '37 of 38 decode to the log-asserted value');
is($recovered, 1, 'the footerless 0x96 capture recovers to a CRC-valid frame');

# --- Tasmota structured MWM records import by name ---------------------------
my $dump = 'IRrecv: Protocol = MWM, Bits = 24, Data = 0x550808, Repeat = 0';
my $code = $converter->import_format('Tasmota', $dump)->[0];
assert_mwm($code, '550808', 24, 'structured MWM record imports');
is($code->alias, '0x550808', 'structured MWM aliases to its Data hex');

my $wide_dump = 'IRrecv: Protocol = MWM, Bits = 120, Data = 0x9C260CD5636B58EE4803D13C070685';
my $wide_code = $converter->import_format('Tasmota', $wide_dump)->[0];
assert_mwm($wide_code, '9C260CD5636B58EE4803D13C070685', 120, 'wide structured MWM record imports');
is($wide_code->alias, '0x9C260CD5636B58EE4803D13C070685', 'wide Data hex is not truncated');

# --- unbundle: a whole A+B+A' bundle splits into its three frames -------------
my $bundle = '0x96190B09088418014D9C260CD5636B58EE4803D13C07068596190B09088418014D';
my @parts = @{ $p->unbundle($bundle) };
is(scalar(@parts), 3, 'unbundle splits the A+B+A\' bundle into three frames');
assert_mwm($parts[0], '96190B09088418014D', 72, 'unbundle frame 1 is command A');
assert_mwm($parts[1], '9C260CD5636B58EE4803D13C070685', 120, 'unbundle frame 2 is status B');
assert_mwm($parts[2], '96190B09088418014D', 72, 'unbundle frame 3 is the A\' repeat');
assert_mwm($p->decode_raw($bundle), '96190B09088418014D', 72,
    'decode_raw of a bundle returns the first frame');

# A lone length-declared frame is not a bundle: one width-derived code.
my @lone = @{ $p->unbundle('0x96190B09088418014D') };
is(scalar(@lone), 1, 'a lone 0x9x frame unbundles to a single code');
assert_mwm($lone[0], '96190B09088418014D', 72, 'lone frame stays width-derived');

# A 2-byte value pads to the 24-bit minimum in the lone fallback.
my @tiny = @{ $p->unbundle('0x5508') };
assert_mwm($tiny[0], '5508', 24, '2-byte value unbundles to a 24-bit code');

# A walk that cannot land exactly falls back to the whole-value frame.
my @mixed = @{ $p->unbundle('0x5508089C260CD5') };
is(scalar(@mixed), 1, 'a non-landing walk unbundles to a single code');
assert_mwm($mixed[0], '5508089C260CD5', 56, 'mixed value falls back to its own width');

# --- to_irsend shows the full wide Data hex ----------------------------------
is_deeply(
    $wide_code->to_irsend(),
    { Protocol => 'MWM', Bits => 120, Data => '0x9C260CD5636B58EE4803D13C070685' },
    'to_irsend carries the untruncated wide Data hex',
);

# --- decode_timing reads the compressed encoder output back ------------------
my $back_pairs = convert_pronto_to_pairs($converter->export_code(
    $converter->import_code('MWM', '0x550808'), 'Pronto'));
assert_mwm(Protocol::IR::Proto::MWM->decode_timing($back_pairs), '550808', 24,
    'decode_timing roundtrips the encoder output');

# --- footerless capture recovers the truncated CRC byte via checksum ---------
# Transmit 91 0E 0F 1E (golden yellow) received by 179E4E as a RawData that
# omits the inter-command footer: the CRC byte's final stop space merges
# invisibly into the gap, leaving a 39-tick (39-bit) signal. The burst pairs
# below are exactly those 17 runs.
my @footerless_pairs = map {
    my @r = @$_;
    [@r]
} (
    [465, 370], [1230, 445], [825, 850], [830, 1270], [1730, 365],
    [420, 1670], [1730, 365], [855, 1655], [1255, 0],
);
assert_mwm(Protocol::IR::Proto::MWM->decode_timing(\@footerless_pairs),
    '910E0F1E', 32, 'footerless capture recovers the CRC byte');

sub convert_pronto_to_pairs {
    my ($pronto) = @_;
    my @t = split /\s+/, $pronto;
    my $period = 1000000.0 / int(1000000.0 / (hex($t[1]) * 0.241246));
    my $pairs  = hex($t[2]) + hex($t[3]);
    my @bp;
    for (my $i = 0; $i < $pairs; $i++) {
        my $idx = 4 + ($i * 2);
        push @bp, [hex($t[$idx]) * $period, hex($t[$idx + 1]) * $period];
    }
    return \@bp;
}

done_testing;
