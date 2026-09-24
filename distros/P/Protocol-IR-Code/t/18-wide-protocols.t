#!/usr/bin/env perl
use strict;
use warnings;
# 48-bit hex literals exceed the 32-bit range that triggers Perl's
# "portable" warning; the wide protocols use them by design.
no warnings 'portable';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestData qw(pronto_to_pairs);
use Protocol::IR::Converter;
use Protocol::IR::Proto::NEC48;
use Protocol::IR::Proto::NEC482;
use Protocol::IR::Proto::JVC48;
use Protocol::IR::Proto::SAMSUNG20;
use Protocol::IR::Proto::SAMSUNG36;

# The wide protocol additions ported from the sibling ir-remote-tools
# project: the 48-bit NEC family (48-NEC1/48-NEC2), JVC-48 (Kaseikyo, OEM
# 3/1), SAMSUNG20 (20-bit AC), and SAMSUNG36 (36-bit, two blocks).
#
# Unlike the 32-bit family, each of these carries its whole word in a single
# frame: 48-NEC1/2 send all six bytes (D:S:F:~F:E:~E) behind the usual
# 9000/4500 us header; JVC-48 sends OEM1:OEM2:D:S:F:checksum behind a
# 3456/1728 us header; SAMSUNG20 sends D:6:S:6:F:8 behind a 4512/4512 us
# header; SAMSUNG36 sends the 16-bit address then the 20-bit command in two
# MSB-first blocks. None of them accumulates across frames.

my $converter = Protocol::IR::Converter->new();

# --- 48-NEC2: packs D:S:F:~F:E:~E, E cleared for IRDB rows -----------------
my $n = Protocol::IR::Proto::NEC482->decode_params(
    address => 77, subaddress => 178, command => 222);
is($n->protocol,   '48-NEC2',   '48-NEC2 protocol name');
is($n->bits,       48,          '48-NEC2 bits');
is($n->address,    77,          '48-NEC2 address');
is($n->subaddress, 178,         '48-NEC2 subaddress');
is($n->command,    222,         '48-NEC2 command');
is($n->data,       0x4DB2DE2100FF, '48-NEC2 packs D:S:F:~F:E:~E');

# The accumulated (DataLSB) form decodes the same fields.
my $nl = Protocol::IR::Proto::NEC482->decode_raw('0x4DB2DE2100FF');
is($nl->address,    77,  '48-NEC2 raw decode address');
is($nl->subaddress, 178, '48-NEC2 raw decode subaddress');
is($nl->command,    222, '48-NEC2 raw decode command');

# The display (Data) form is the per-byte bit reversal of the accumulated
# word (0x4DB2DE2100FF <-> 0xB24D7B8400FF).
my $nm = Protocol::IR::Proto::NEC48->decode_byte_order('0xB24D7B8400FF', 0);
is($nm->data, 0x4DB2DE2100FF, '48-NEC1 display form translates to accumulated');
is($nm->protocol, '48-NEC1', '48-NEC1 keeps its identity on by-name import');

# 48-NEC2 keeps its identity too.
my $n2m = Protocol::IR::Proto::NEC482->decode_byte_order('0xB24D7B8400FF', 0);
is($n2m->protocol, '48-NEC2', '48-NEC2 keeps its identity on by-name import');

# Pronto roundtrip: 38 kHz word, header + 48 bits + stop = 50 pairs.
my $n_pronto = $converter->export_code($n, 'Pronto');
like($n_pronto, qr/^0000 006D/, '48-NEC2 Pronto carries 38 kHz word');
my @n_pairs = @{ pronto_to_pairs($n_pronto) };
is(scalar(@n_pairs), 50, '48-NEC2 Pronto has header + 48 bits + stop');
my $n_back = $converter->import_format('Pronto', $n_pronto);
# A single frame cannot tell 48-NEC1 from 48-NEC2 (they share the framing and
# differ only in repeat structure), so the base variant absorbs the timing
# decode just as NEC absorbs NEC2.
is($n_back->protocol,   '48-NEC1', 'timing decode identifies the 48-bit NEC framing');
is($n_back->data,       0x4DB2DE2100FF, '48-NEC timing roundtrip preserves the word');
is($n_back->address,    77,  '48-NEC timing roundtrip preserves address');
is($n_back->subaddress, 178, '48-NEC timing roundtrip preserves subaddress');
is($n_back->command,    222, '48-NEC timing roundtrip preserves command');

# Stop-bit validation applies here too.
my @bad_n = @n_pairs;
$bad_n[49] = [100, 108000];
is(Protocol::IR::Proto::NEC48->decode_timing(\@bad_n), undef,
    '48-NEC rejects stop bit with too-short mark');

# --- JVC-48: Kaseikyo OEM 3/1, checksum = D^S^F ----------------------------
my $j = Protocol::IR::Proto::JVC48->decode_params(
    address => 34, subaddress => 33, command => 3);
is($j->protocol,   'JVC-48', 'JVC-48 protocol name');
is($j->bits,       48,       'JVC-48 bits');
is($j->address,    34,       'JVC-48 address');
is($j->subaddress, 33,       'JVC-48 subaddress');
is($j->command,    3,        'JVC-48 command');
is($j->data,       0x030122210300, 'JVC-48 packs OEM 3/1 then D:S:F:checksum');

# A missing subdevice sends a zero field (there is no Default S rule).
my $jo = Protocol::IR::Proto::JVC48->decode_params(address => 34, command => 3);
is($jo->subaddress, -1, 'JVC-48 omitted subaddress stays -1');
is($jo->data,       0x030122000321, 'JVC-48 wire subdevice defaults to 0');

my $jl = Protocol::IR::Proto::JVC48->decode_raw('0x030122210300');
is($jl->address,    34,  'JVC-48 raw decode address');
is($jl->subaddress, 33,  'JVC-48 raw decode subaddress');
is($jl->command,    3,   'JVC-48 raw decode command');

my $jm = Protocol::IR::Proto::JVC48->decode_byte_order('0xC0804484C000', 0);
is($jm->data, 0x030122210300, 'JVC-48 display form translates to accumulated');

# Pronto roundtrip: 37 kHz word (0x0070), 50 pairs.
my $j_pronto = $converter->export_code($j, 'Pronto');
like($j_pronto, qr/^0000 0070/, 'JVC-48 Pronto carries 37 kHz word');
my $j_back = $converter->import_format('Pronto', $j_pronto);
is($j_back->protocol,   'JVC-48', 'timing decode identifies JVC-48');
is($j_back->data,       0x030122210300, 'JVC-48 timing roundtrip preserves the word');
is($j_back->address,    34,  'JVC-48 timing roundtrip preserves address');
is($j_back->subaddress, 33,  'JVC-48 timing roundtrip preserves subaddress');
is($j_back->command,    3,   'JVC-48 timing roundtrip preserves command');

# --- SAMSUNG20: D:6 S:6 F:8, Default S=0 ------------------------------------
my $s = Protocol::IR::Proto::SAMSUNG20->decode_params(
    address => 1, subaddress => 8, command => 39);
is($s->protocol, 'SAMSUNG20', 'SAMSUNG20 protocol name');
is($s->bits,     20,          'SAMSUNG20 bits');
is($s->data,     0x27201,     'SAMSUNG20 packs F:8 into the high byte then D:6:S:6');

my $so = Protocol::IR::Proto::SAMSUNG20->decode_params(address => 1, command => 39);
is($so->subaddress, -1,    'SAMSUNG20 omitted subdevice stays -1');
is($so->data,       0x27001, 'SAMSUNG20 wire subdevice defaults to 0');

my $sr = Protocol::IR::Proto::SAMSUNG20->decode_raw('0x27201');
is($sr->address,    1,  'SAMSUNG20 raw decode address');
is($sr->subaddress, 8,  'SAMSUNG20 raw decode subaddress');
is($sr->command,    39, 'SAMSUNG20 raw decode command');

my $s_pronto = $converter->export_code($s, 'Pronto');
my $s_back = $converter->import_format('Pronto', $s_pronto);
is($s_back->protocol,   'SAMSUNG20', 'timing decode identifies SAMSUNG20');
is($s_back->data,       0x27201,     'SAMSUNG20 timing roundtrip preserves the word');
is($s_back->address,    1,  'SAMSUNG20 timing roundtrip preserves address');
is($s_back->subaddress, 8,  'SAMSUNG20 timing roundtrip preserves subaddress');
is($s_back->command,    39, 'SAMSUNG20 timing roundtrip preserves command');

# Ground truth from the MakeHex EncodeIR tool (Samsung20.irp, D=1 S=8 F=39):
# the exact wire timings MakeHex generates for the same parameters, baked in
# so CI needs no MakeHex build. Our encoder must match them bit-for-bit
# (Pronto quantization shifts individual pulses by a few us at most).
my @s20_enc = qw(4512 4512 564 1692 564 564 564 564 564 564 564 564
    564 564 564 564 564 564 564 564 564 1692 564 564 564 564 564 1692
    564 1692 564 1692 564 564 564 564 564 1692 564 564 564 564 564 24816);
my @s20_pairs = @{ pronto_to_pairs($converter->export_code($s, 'Pronto')) };
is(scalar(@s20_pairs), 22, 'SAMSUNG20 matches EncodeIR pair count');
is($s20_pairs[0][0] >= 4300 && $s20_pairs[0][0] <= 4700, 1, 'SAMSUNG20 header mark vs EncodeIR');
is($s20_pairs[0][1] >= 4300 && $s20_pairs[0][1] <= 4700, 1, 'SAMSUNG20 header space vs EncodeIR');
my @s20_bits;
for my $i (1 .. 20) { push @s20_bits, ($s20_pairs[$i][1] > 1000) ? 1 : 0; }
my @s20_enc_bits;
for my $i (1 .. 20) { push @s20_enc_bits, ($s20_enc[$i * 2 + 1] > 1000) ? 1 : 0; }
is(join('', @s20_bits), join('', @s20_enc_bits), 'SAMSUNG20 wire bits match EncodeIR');
is($s20_pairs[21][1] >= 20000, 1, 'SAMSUNG20 stop space vs EncodeIR ~24.8 ms');

# --- SAMSUNG36: 16-bit address block + 20-bit command block, MSB-first ------
my $s36 = Protocol::IR::Proto::SAMSUNG36->decode_params(
    address => 0x7004, command => 0xF023E);
is($s36->protocol,   'SAMSUNG36', 'SAMSUNG36 protocol name');
is($s36->bits,       36,          'SAMSUNG36 bits');
is($s36->address,    0x7004,      'SAMSUNG36 address');
is($s36->subaddress, -1,          'SAMSUNG36 has no subaddress');
is($s36->command,    0xF023E,     'SAMSUNG36 command');
is($s36->data,       0x7004F023E, 'SAMSUNG36 packs block1 (16) and block2 (20)');

# decode_raw expects the display form: the word read MSB-first.
my $s36raw = Protocol::IR::Proto::SAMSUNG36->decode_raw('0x7004F023E');
is($s36raw->address, 0x7004, 'SAMSUNG36 raw decode address');
is($s36raw->command, 0xF023E, 'SAMSUNG36 raw decode command');
is($s36raw->data,    0x7004F023E, 'SAMSUNG36 raw decode data');

# The "LSB" column is the whole word read end to end in reverse.
my $s36lsb = Protocol::IR::Proto::SAMSUNG36->decode_byte_order('0x7C40F200E', 1);
is($s36lsb->data, 0x7004F023E, 'SAMSUNG36 LSB form reverses end to end to display');

# Pronto roundtrip: two blocks, so 1 + 16 + 1 + 20 + 1 = 39 pairs.
my $s36_pronto = $converter->export_code($s36, 'Pronto');
like($s36_pronto, qr/^0000 006D/, 'SAMSUNG36 Pronto carries 38 kHz word');
my @s36_pairs = @{ pronto_to_pairs($s36_pronto) };
is(scalar(@s36_pairs), 39, 'SAMSUNG36 Pronto has header + both blocks + stops');
# Mid-block footer: a short mark and a ~4438 us space after the 16 address bits.
is($s36_pairs[17][0] >= 400 && $s36_pairs[17][0] <= 900, 1, 'SAMSUNG36 mid-block mark');
is($s36_pairs[17][1] >= 3800 && $s36_pairs[17][1] <= 5200, 1, 'SAMSUNG36 mid-block space');
my $s36_back = $converter->import_format('Pronto', $s36_pronto);
is($s36_back->protocol, 'SAMSUNG36', 'timing decode identifies SAMSUNG36');
is($s36_back->data,     0x7004F023E, 'SAMSUNG36 timing roundtrip preserves the word');
is($s36_back->address,  0x7004, 'SAMSUNG36 timing roundtrip preserves address');
is($s36_back->command,  0xF023E, 'SAMSUNG36 timing roundtrip preserves command');

# --- IRDB CSV import keeps the wide protocols' identity ----------------------
my $csv = <<'CSV';
functionname,protocol,device,subdevice,function
KEY_POWER,48-NEC1,77,178,222
KEY_TEMPUP,48-NEC2,77,178,223
KEY_PLAY,JVC-48,34,33,3
KEY_AC,SAMSUNG20,1,8,39
KEY_BLURAY,SAMSUNG36,0x7004,,0xF023E
CSV
my $codes = $converter->import_format('CSV', $csv);
is(scalar(@$codes), 5, 'all wide-protocol rows decode');
my %by_alias = map { $_->alias => $_ } @$codes;
is($by_alias{'KEY_POWER'}->protocol,  '48-NEC1',  '48-NEC1 row keeps protocol');
is($by_alias{'KEY_POWER'}->data,      0x4DB2DE2100FF, '48-NEC1 row data');
is($by_alias{'KEY_TEMPUP'}->protocol, '48-NEC2',  '48-NEC2 row keeps protocol');
is($by_alias{'KEY_PLAY'}->protocol,   'JVC-48',   'JVC-48 row keeps protocol');
is($by_alias{'KEY_PLAY'}->data,       0x030122210300, 'JVC-48 row data');
is($by_alias{'KEY_AC'}->protocol,     'SAMSUNG20', 'SAMSUNG20 row keeps protocol');
is($by_alias{'KEY_AC'}->data,         0x27201,    'SAMSUNG20 row data');
is($by_alias{'KEY_BLURAY'}->protocol, 'SAMSUNG36', 'SAMSUNG36 row keeps protocol');
is($by_alias{'KEY_BLURAY'}->data,     0x7004F023E, 'SAMSUNG36 row data');

# --- end-to-end: IRDB CSV to HAIR wig and back -------------------------------
my $wig = $converter->export_codes('wig', $codes, name => 'Wide Protocols');
my $back = $converter->import_format('wig', $wig);
is(scalar(@$back), 5, 'wig roundtrip decodes all five signals');
my %back_by_alias = map { $_->alias => $_ } @$back;
is($back_by_alias{'KEY_POWER'}->data,  0x4DB2DE2100FF, '48-NEC1 wig roundtrip data');
is($back_by_alias{'KEY_PLAY'}->data,   0x030122210300, 'JVC-48 wig roundtrip data');
is($back_by_alias{'KEY_AC'}->data,     0x27201,        'SAMSUNG20 wig roundtrip data');
is($back_by_alias{'KEY_BLURAY'}->data, 0x7004F023E,    'SAMSUNG36 wig roundtrip data');

done_testing;
