#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestData qw(pronto_to_pairs);
use Protocol::IR::Converter;
use Protocol::IR::Proto::NEC2;
use Protocol::IR::Proto::NECX1;
use Protocol::IR::Proto::NECX2;
use Protocol::IR::Proto::SAMSUNG;

# The NEC family as defined by the MakeHex IRP files IRDB builds on
# (protocols/nec1.irp, nec2.irp, NECx1.irp, NECx2.irp in MakeHex):
#
#   NEC1  header 16,-8 (9000/4500 us),  S = ~D, repeat is a short
#         header+gap frame
#   NEC2  identical single-frame timing to NEC1; only the repeat differs
#         (it re-transmits the entire 32-bit frame)
#   NECx1 header 8,-8 (4500/4500 us),    S = D (a real second address
#         byte, not an inversion), repeat is a short frame
#   NECx2 identical single-frame timing to NECx1; whole-frame repeat
#
# All four share the 32-bit D:S:F:~F layout, each byte LSB-first on the
# wire, and the same 562.5 us mark / 562.5 us (0) / 1687.5 us (1) bit
# times. The data value always packs as
#   data = (address << 24) | (subaddress << 16) | (command << 8) | ~command
# matching the MakeHex wire output (verified against a built MakeHex for
# the Samsung NECx2 POWER row below).

my $converter = Protocol::IR::Converter->new();

# --- NEC2: same framing as NEC1, only the repeat differs -------------------
my $n2 = Protocol::IR::Proto::NEC2->decode_params(
    address => 26, subdevice => 232, command => 5);
is($n2->protocol,   'NEC2',     'NEC2 protocol name');
is($n2->bits,       32,         'NEC2 bits');
is($n2->address,    26,         'NEC2 address');
is($n2->subaddress, 232,        'NEC2 explicit subaddress kept');
is($n2->command,    5,          'NEC2 command');
is($n2->data,       0x1AE805FA, 'NEC2 packs D:S:F:~F');

# NEC2 inherits NEC1's "Default S=~D": an omitted/-1 subaddress becomes
# the one's complement of the address and is normalized to -1.
my $n2d = Protocol::IR::Proto::NEC2->decode_params(address => 26, command => 5);
is($n2d->subaddress, -1,        'NEC2 omitted subaddress inferred as ~address');
is($n2d->data,       0x1AE505FA, 'NEC2 inferred subaddress packs ~address');

my $n2raw = Protocol::IR::Proto::NEC2->decode_raw('0x1AE805FA');
is($n2raw->address,    26,  'NEC2 raw decode address');
is($n2raw->subaddress, 232, 'NEC2 raw decode subaddress');
is($n2raw->command,    5,   'NEC2 raw decode command');

# Single-frame timing is identical to NEC1: full 9000/4500 header.
my $n2_pronto = $converter->export_code($n2, 'Pronto');
like($n2_pronto, qr/^0000 006D/, 'NEC2 Pronto carries 38 kHz word');
my @n2_pairs = @{ pronto_to_pairs($n2_pronto) };
is(scalar(@n2_pairs), 34, 'NEC2 Pronto has header + 32 bits + stop');
is($n2_pairs[0][0] >= 8700 && $n2_pairs[0][0] <= 9300, 1, 'NEC2 full header mark');
is($n2_pairs[0][1] >= 4300 && $n2_pairs[0][1] <= 4700, 1, 'NEC2 full header space');

my $n2_back = Protocol::IR::Proto::NEC2->decode_timing(\@n2_pairs);
is($n2_back->protocol, 'NEC2', 'NEC2 timing decode keeps protocol');
is($n2_back->data,     0x1AE805FA, 'NEC2 timing roundtrip preserves data');

# --- NECx1: half header, 16-bit address with S kept as a real byte --------
my $nx1 = Protocol::IR::Proto::NECX1->decode_params(
    device => 162, subdevice => 162, command => 1);
is($nx1->protocol,   'NECX1',    'NECX1 protocol name');
is($nx1->address,    162,        'NECX1 address');
is($nx1->subaddress, 162,        'NECX1 subaddress kept (not ~address)');
is($nx1->command,    1,          'NECX1 command');
is($nx1->data,       0xA2A201FE, 'NECX1 packs D:S:F:~F');

# "Default S=D": an omitted subaddress is copied from the address.
my $nx1d = Protocol::IR::Proto::NECX1->decode_params(device => 7, command => 2);
is($nx1d->subaddress, 7,        'NECX1 omitted subaddress defaults to address');
is($nx1d->data,       0x070702FD, 'NECX1 default-subaddress data');

# The distinguishing behavior: for NECx the second byte is part of the
# 16-bit address, so even a subaddress equal to ~address is kept rather
# than normalized to -1 (NEC would report -1 here).
my $nx1a = Protocol::IR::Proto::NECX1->decode_params(
    address => 0x10, subdevice => 0xEF, command => 0);
is($nx1a->subaddress, 0xEF, 'NECX1 keeps explicit ~address subaddress');
is($nx1a->data,       0x10EF00FF, 'NECX1 packs the full 16-bit address');
is($nx1a->subaddress, 0xEF, 'NECX1 subaddress is not normalized to -1');

my $nx1raw = Protocol::IR::Proto::NECX1->decode_raw('0x070702FD');
is($nx1raw->address,    7,  'NECX1 raw decode address');
is($nx1raw->subaddress, 7,  'NECX1 raw decode subaddress');
is($nx1raw->command,    2,  'NECX1 raw decode command');

# Half header: 4500/4500.
my $nx1_pronto = $converter->export_code($nx1, 'Pronto');
like($nx1_pronto, qr/^0000 006D/, 'NECX1 Pronto carries 38 kHz word');
my @nx1_pairs = @{ pronto_to_pairs($nx1_pronto) };
is(scalar(@nx1_pairs), 34, 'NECX1 Pronto has header + 32 bits + stop');
is($nx1_pairs[0][0] >= 4300 && $nx1_pairs[0][0] <= 4700, 1, 'NECX1 half header mark');
is($nx1_pairs[0][1] >= 4300 && $nx1_pairs[0][1] <= 4700, 1, 'NECX1 half header space');

my $nx1_back = Protocol::IR::Proto::NECX1->decode_timing(\@nx1_pairs);
is($nx1_back->protocol, 'NECX1', 'NECX1 timing decode keeps protocol');
is($nx1_back->data,     0xA2A201FE, 'NECX1 timing roundtrip preserves data');

# A NECx frame whose subaddress differs from its address must not be
# mislabeled SAMSUNG: Samsung repeats the address byte and follows the
# command byte with its one's complement, and its strict decoder rejects
# any 4500/4500 frame whose bytes lack that structure (IRremoteESP8266
# reports the same capture as UNKNOWN). The NECX1 decoder then names it.
my $nx1x = Protocol::IR::Proto::NECX1->decode_params(
    address => 0x10, subdevice => 0xEF, command => 0);
my @nx1x_pairs = @{ pronto_to_pairs($converter->export_code($nx1x, 'Pronto')) };
is(Protocol::IR::Proto::SAMSUNG->decode_timing(\@nx1x_pairs), undef,
    'SAMSUNG strict decoder rejects a NECx frame with a real subaddress');
my $nx1x_back = $converter->import_format('Pronto',
    $converter->export_code($nx1x, 'Pronto'));
is($nx1x_back->protocol,  'NECX1', 'NECx frame keeps its NECX1 identity on a timing decode');
is($nx1x_back->address,   0x10,    'NECx address survives the timing roundtrip');
is($nx1x_back->subaddress, 0xEF,  'NECx subaddress survives the timing roundtrip');
is($nx1x_back->command,   0,      'NECx command survives the timing roundtrip');

# --- NECx2: identical single-frame timing to NECx1 -------------------------
my $nx2 = Protocol::IR::Proto::NECX2->decode_params(
    device => 7, subdevice => 7, command => 2);
is($nx2->protocol,   'NECX2',    'NECX2 protocol name');
is($nx2->address,    7,          'NECX2 address');
is($nx2->subaddress, 7,          'NECX2 subaddress');
is($nx2->command,    2,          'NECX2 command');
is($nx2->data,       0x070702FD, 'NECX2 Samsung POWER packs expected data');

# Verify our NECX2 encoder against a real MakeHex build: the Samsung TV
# POWER row (NECx2, device 7, subdevice 7, function 2) transmits the
# wire bitstream 11100000 11100000 01000000 10111111 (header 4500/4500).
my $sam = Protocol::IR::Proto::NECX2->decode_params(
    device => 7, subdevice => 7, command => 2);
my @sam_pairs = @{ pronto_to_pairs($converter->export_code($sam, 'Pronto')) };
my @bits;
for my $i (1 .. 32) { push @bits, ($sam_pairs[$i][1] > 1000) ? 1 : 0; }
is(join('', @bits), '11100000111000000100000010111111',
    'NECX2 Samsung POWER wire bits match MakeHex');
is($sam_pairs[0][0] >= 4300 && $sam_pairs[0][0] <= 4700, 1, 'NECX2 header mark');
is($sam_pairs[0][1] >= 4300 && $sam_pairs[0][1] <= 4700, 1, 'NECX2 header space');

my $nx2_back = Protocol::IR::Proto::NECX2->decode_timing(\@sam_pairs);
is($nx2_back->protocol, 'NECX2', 'NECX2 timing decode keeps protocol');
is($nx2_back->data,     0x070702FD, 'NECX2 timing roundtrip preserves data');
is($nx2_back->address,  7, 'NECX2 timing roundtrip preserves address');
is($nx2_back->subaddress, 7, 'NECX2 timing roundtrip preserves subaddress');

# --- stop-bit validation applies to the new variants -----------------------
my @bad_mark = @sam_pairs;
$bad_mark[33] = [100, 30000];
is(Protocol::IR::Proto::NECX2->decode_timing(\@bad_mark), undef,
    'NECX2 rejects stop bit with too-short mark');
my @bad_space = @sam_pairs;
$bad_space[33] = [560, 500];
is(Protocol::IR::Proto::NECX2->decode_timing(\@bad_space), undef,
    'NECX2 rejects stop bit with too-short trailing space');

# --- IRDB CSV import preserves the variant identity -------------------------
# This is the primary use of the library: an IRDB file mixing NEC variants
# must import each row under its own protocol with the right data word.
my $csv = <<'CSV';
functionname,protocol,device,subdevice,function
KEY_POWER,NEC1,4,0,8
KEY_POWER2,NEC2,26,232,5
KEY_INPUT,NECx1,162,162,1
KEY_POWER3,NECx2,7,7,2
KEY_MUTE,nec1,4,0,9
CSV
my $codes = $converter->import_format('CSV', $csv);
is(scalar(@$codes), 5, 'all NEC-variant rows decode');
my %by_alias = map { $_->alias => $_ } @$codes;
is($by_alias{'KEY_POWER'}->protocol,  'NEC',   'NEC1 normalized to NEC');
is($by_alias{'KEY_POWER2'}->protocol, 'NEC2',  'NEC2 kept as NEC2');
is($by_alias{'KEY_POWER2'}->data,     0x1AE805FA, 'NEC2 row data');
is($by_alias{'KEY_INPUT'}->protocol,  'NECX1', 'NECx1 kept as NECX1');
is($by_alias{'KEY_INPUT'}->subaddress, 162,    'NECX1 row subaddress');
is($by_alias{'KEY_POWER3'}->protocol, 'NECX2', 'NECx2 kept as NECX2');
is($by_alias{'KEY_POWER3'}->data,     0x070702FD, 'NECX2 Samsung POWER row data');
is($by_alias{'KEY_MUTE'}->protocol,   'NEC',   'lowercase nec1 normalized to NEC');

# --- end-to-end: IRDB CSV to HAIR wig and back ------------------------------
my $wig = $converter->export_codes('wig', $codes,
    name => 'Mixed NEC', brand => 'Test', kind => 'tv');
my $back = $converter->import_format('wig', $wig);
is(scalar(@$back), 5, 'wig roundtrip decodes all five signals');
my %back_by_alias = map { $_->alias => $_ } @$back;
is($back_by_alias{'KEY_POWER'}->data,  0x040008F7, 'NEC1 wig roundtrip data');
is($back_by_alias{'KEY_POWER2'}->data, 0x1AE805FA, 'NEC2 wig roundtrip data');
is($back_by_alias{'KEY_INPUT'}->data,  0xA2A201FE, 'NECX1 wig roundtrip data');
is($back_by_alias{'KEY_POWER3'}->data, 0x070702FD, 'NECX2 wig roundtrip data');

# Single-frame NEC2 timing is identical to NEC1, and NECx1/NECx2 timing is
# identical to SAMSUNG (all 4500/4500 half-header frames), so on a *timing*
# decode the registry labels NEC2 frames as NEC and NECx frames as SAMSUNG.
# The data word is preserved either way; the protocol identity is only kept
# when importing by name (CSV/decode_params), which is the IRDB->wig path.
is($back_by_alias{'KEY_POWER'}->protocol,  'NEC',    'NEC2 frame labeled NEC by timing');
is($back_by_alias{'KEY_POWER3'}->protocol, 'SAMSUNG', 'NECx frame labeled SAMSUNG by timing');

done_testing;
