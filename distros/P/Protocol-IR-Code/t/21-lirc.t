#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);

use Protocol::IR::Converter;
use Protocol::IR::Code;

my $converter = Protocol::IR::Converter->new();

my $data = File::Spec->catdir(dirname(__FILE__), 'data');
my $samsung_lirc = File::Spec->catfile($data, 'lirc-samsung-tv.lircd.conf');

# --- Import: Samsung TV remote with pre_data -----------------------------

subtest 'import Samsung LIRC remote' => sub {
    my $codes = $converter->import_format('LIRC', $samsung_lirc);
    ok($codes && @$codes > 0, 'decoded codes from Samsung LIRC file');
    is(scalar @$codes, 43, '43 buttons in the Samsung remote');

    # Check a known button: KEY_POWER 0x40BF with pre_data 0xE0E0
    my ($power) = grep { $_->alias eq 'KEY_POWER' } @$codes;
    ok($power, 'found KEY_POWER');
    is($power->protocol, 'SAMSUNG', 'POWER decoded as SAMSUNG');
    is($power->data, 0x070702FD, 'POWER lands on the accumulated word (pre_data|code per-byte reversed)');

    # Check another button
    my ($volup) = grep { $_->alias eq 'KEY_VOLUMEUP' } @$codes;
    ok($volup, 'found KEY_VOLUMEUP');
    is($volup->protocol, 'SAMSUNG', 'VOLUMEUP decoded as SAMSUNG');
    is($volup->data, 0x070707F8, 'VOLUMEUP accumulated word');
};

# --- Import: minimal inline LIRC ----------------------------------------

subtest 'import minimal inline LIRC' => sub {
    my $lirc = <<'LIRC';
begin remote
  name  TestNEC
  bits           32
  flags SPACE_ENC|CONST_LENGTH
  eps            30
  aeps          100
  header       9000  4500
  one           560  1690
  zero          560   560
  ptrail        560
  repeat       9000  2250
  gap          108000
  toggle_bit_mask 0x0

      begin codes
          KEY_POWER    0x10EF00FF
          KEY_VOLUP    0x10EF40BF
      end codes
end remote
LIRC

    my $codes = $converter->import_format('LIRC', $lirc);
    ok($codes && @$codes == 2, 'decoded 2 NEC buttons');

    is($codes->[0]->alias, 'KEY_POWER', 'first button alias');
    is($codes->[0]->protocol, 'NEC', 'NEC timing inferred');
    is($codes->[0]->data, 0x10EF00FF, 'NEC data from codes section');

    is($codes->[1]->alias, 'KEY_VOLUP', 'second button alias');
    is($codes->[1]->data, 0x10EF40BF, 'second NEC data');
};

# --- Import: NEC with 16-bit pre_data (RM-SG20/accumulated bytes) ---------

# A NEC signalling remote whose LIRC file carries pre_data in accumulated byte
# order (pre_data 0xC100 with 16-bit values 0x00FF) used to decode straight
# from the composed word 0xC10000FF and land on address 0xC1. The composed
# word must be reduced to the display form (0x830000FF / address 131) exactly
# as the JS port and the rm-sg20 samples do.
subtest 'import NEC pre_data accumulated (rm-sg20)' => sub {
    my $lirc = <<'LIRC';
begin remote
  name  RM_SG20_NEC
  bits           16
  flags SPACE_ENC
  eps            25
  aeps          100
  header       9102  4396
  one           638  1586
  zero          638   462
  ptrail        638
  pre_data_bits  16
  pre_data       0xC100
  gap          45584
  toggle_bit      0
      begin codes
          KEY_POWER       0x00FF
          KEY_BAND        0x0100
      end codes
end remote
LIRC

    my $codes = $converter->import_format('LIRC', $lirc);
    ok($codes && @$codes == 2, 'decoded 2 NEC buttons');

    my ($power) = grep { $_->alias eq 'KEY_POWER' } @$codes;
    ok($power, 'found KEY_POWER');
    is($power->protocol, 'NEC', 'NEC timing inferred');
    is($power->address, 131, 'KEY_POWER address is the display byte 0x83');
    is($power->command, 0,   'KEY_POWER command');
    is($power->data, 0x830000FF, 'KEY_POWER data is the display-form word');

    my ($band) = grep { $_->alias eq 'KEY_BAND' } @$codes;
    ok($band, 'found KEY_BAND');
    is($band->address,   131, 'KEY_BAND address still the display byte 0x83');
};

# --- Import: NEC with the REVERSE flag (Vizio VX37L) ----------------------
#
# The SAME Vizio VX37L TV key is recorded in two places: IRDB carries the
# display form (NEC 4,-1,8 for KEY_POWER, 0x04FB08F7) and the lirc-remotes
# vizio/VX37L conf stores each 16-bit word bit-mirrored (REVERSE flag):
# pre_data 0xFB04 / Power 0xF708 instead of LCD_TV's non-reverse
# pre_data 0x20DF / Power 0x10EF. The REVERSE words are the same signal
# written backwards, so the LIRC import must mirror each word back to the
# wire's accumulated order, then reduce to the identical display form.
subtest 'import REVERSE LIRC remote (Vizio VX37L)' => sub {
    my $vx37l = File::Spec->catfile($data, 'lirc-vizio-VX37L.lircd.conf');
    my $codes = $converter->import_format('LIRC', $vx37l);
    ok($codes && @$codes > 0, 'decoded codes from VX37L LIRC file');

    my ($power) = grep { $_->alias eq 'KEY_POWER' } @$codes;
    ok($power, 'found KEY_POWER');
    is($power->protocol, 'NEC', 'KEY_POWER decoded as NEC');
    is($power->bits, 32, 'full 32-bit word (16 pre_data + 16 value)');
    is($power->address,    4, 'KEY_POWER address');
    is($power->subaddress, -1, 'KEY_POWER subaddress (none)');
    is($power->command,    8, 'KEY_POWER command');
    is($power->data,       0x04FB08F7, 'REVERSE words mirrored and reduced to the display form');
};

# LIRC VX37L and the IRDB Unknown_VX37L CSV record the same NEC signal; the
# shared buttons must agree on every field.
subtest 'VX37L REVERSE agrees with IRDB CSV' => sub {
    my $vx37l = File::Spec->catfile($data, 'lirc-vizio-VX37L.lircd.conf');
    my $irdb  = File::Spec->catfile($data, 'irdb-vizio-Unknown_VX37L-4,-1.csv');
    my $lirc  = $converter->import_format('LIRC', $vx37l);
    my $csv   = $converter->import_format('CSV',  $irdb);
    my (%li) = map { $_->alias => $_ } @$lirc;
    my (%ic) = map { $_->alias => $_ } @$csv;

    for my $button (['KEY_POWER', 8], ['KEY_MUTE', 9], ['KEY_VOLUMEDOWN', 3], ['KEY_VOLUMEUP', 2]) {
        my ($alias, $cmd) = @$button;
        my $l = $li{$alias};
        my $i = $ic{$alias};
        ok($l && $i, "$alias present in both files");
        next unless $l && $i;
        is($l->protocol,   $i->protocol,   "$alias protocol agrees");
        is($l->address,    $i->address,    "$alias address agrees");
        is($l->subaddress, $i->subaddress, "$alias subaddress agrees");
        is($l->command,    $i->command,    "$alias command agrees");
        is($l->command,    $cmd,           "$alias command value");
        is($l->data,       $i->data,       "$alias data agrees");
        is($l->data, 0x04FB0000 | ($cmd << 8) | (~$cmd & 0xFF), "$alias data is the display-form word");
    }
};

# The two databases must also agree on the transmitted pulse train.
subtest 'VX37L exports Pronto identical to IRDB' => sub {
    my $vx37l = File::Spec->catfile($data, 'lirc-vizio-VX37L.lircd.conf');
    my $irdb  = File::Spec->catfile($data, 'irdb-vizio-Unknown_VX37L-4,-1.csv');
    my $lirc  = $converter->import_format('LIRC', $vx37l);
    my $csv   = $converter->import_format('CSV',  $irdb);
    my (%li) = map { $_->alias => $_ } @$lirc;
    my (%ic) = map { $_->alias => $_ } @$csv;

    for my $alias (qw(KEY_POWER KEY_MUTE KEY_VOLUMEDOWN KEY_VOLUMEUP)) {
        my $l = $li{$alias};
        my $i = $ic{$alias};
        next unless $l && $i;
        my $lp = $converter->export_code($l, 'Pronto');
        my $ip = $converter->export_code($i, 'Pronto');
        is($lp, $ip, "$alias Pronto is identical");
    }
};

# REVERSE (VX37L) and non-REVERSE (LCD_TV) are the same NEC power signal.
subtest 'REVERSE VX37L and non-REVERSE LCD_TV describe the same power key' => sub {
    my $vx37l  = File::Spec->catfile($data, 'lirc-vizio-VX37L.lircd.conf');
    my $lcdtv  = File::Spec->catfile($data, 'lirc-vizio-LCD_TV.lircd.conf');
    my $rev    = $converter->import_format('LIRC', $vx37l);
    my $plain  = $converter->import_format('LIRC', $lcdtv);
    my ($r) = grep { $_->alias eq 'KEY_POWER' } @$rev;
    my ($p) = grep { $_->alias eq 'KEY_POWER' } @$plain;
    ok($r && $p, 'KEY_POWER present in both');
    is($r->data,    $p->data,    'both land on the same display form');
    is($r->address, $p->address, 'same address');
    is($r->command, $p->command, 'same command');
};

# --- Import: Bose remote (unknown protocol, timing-based decode) ---------

subtest 'import Bose SoundTouch remote' => sub {
    my $lirc = <<'LIRC';
begin remote
  name  BOSE_SOUNDTOUCH
  bits           16
  flags SPACE_ENC|CONST_LENGTH
  eps            30
  aeps          100
  header        941  1553
  one           440  1550
  zero          440   555
  ptrail        438
  gap          77681
  min_repeat      1
  toggle_bit_mask 0x0

      begin codes
          KEY_POWER                0xCD32
          KEY_1                    0x1FE0
          KEY_VOLUMEUP             0x3FC0
          KEY_VOLUMEDOWN           0xBF40
      end codes
end remote
LIRC

    my $codes = $converter->import_format('LIRC', $lirc);
    ok($codes && @$codes == 4, 'decoded 4 Bose buttons');
    is($codes->[0]->alias, 'KEY_POWER', 'first button alias');
    # Bose timing doesn't match NEC/Samsung/JVC, so it may be UNKNOWN
    ok(defined $codes->[0]->data, 'data is defined');
};

# --- Import: JVC VCR remote with 48-bit hex values -----------------------

subtest 'import JVC VCR LIRC remote' => sub {
    my $jvc_lirc = File::Spec->catfile($data, 'lirc-jvc-vcr.lircd.conf');
    my $codes = $converter->import_format('LIRC', $jvc_lirc);
    ok($codes && @$codes > 0, 'decoded codes from JVC VCR LIRC file');
    is(scalar @$codes, 20, '20 buttons in the JVC VCR remote');

    my ($power) = grep { $_->alias eq 'KEY_POWER' } @$codes;
    ok($power, 'found KEY_POWER');
    is($power->protocol, 'JVC', 'POWER decoded as JVC');
    is($power->data, 0xC2D0, 'POWER 16-bit data (48-bit hex masked)');

    my ($play) = grep { $_->alias eq 'KEY_PLAY' } @$codes;
    ok($play, 'found KEY_PLAY');
    is($play->data, 0xC230, 'PLAY data');

    # TV_POWER uses a different device address (0xC0 vs 0xC2)
    my ($tv_power) = grep { $_->alias eq 'TV_POWER' } @$codes;
    ok($tv_power, 'found TV_POWER');
    is($tv_power->data, 0xC0E8, 'TV_POWER data (different device address)');
};

# --- Import: raw codes ---------------------------------------------------

subtest 'import raw codes LIRC' => sub {
    my $lirc = <<'LIRC';
begin remote
  name  RAW_TEST
  flags RAW_CODES|CONST_LENGTH
  eps            25
  aeps          100
  ptrail          0
  repeat     0     0
  gap    100000

      begin raw_codes
          name Power
               9020  4520  560  560  560  560  560  560
               560  560  560  1690  560  1690  560  1690
               560  560  560  560  560  560  560  560
               560  1690  560  1690  560  560  560  560
               560  560  560  560  560  560  560  560
               560  560  560  560  560  560  560  560
               560  1690  560  1690  560  1690  560  1690
               560  560  560  1690  560  1690  560  1690
               560  1690  560  43310
      end raw_codes
end remote
LIRC

    my $codes = $converter->import_format('LIRC', $lirc);
    ok($codes && @$codes == 1, 'decoded 1 raw code');
    is($codes->[0]->alias, 'Power', 'raw code alias');
    is($codes->[0]->protocol, 'NEC', 'raw NEC timing decoded');
    is(ref($codes->[0]->timings), 'ARRAY', 'timings preserved');
};

# --- Export: NEC code to LIRC -------------------------------------------

subtest 'export NEC code to LIRC' => sub {
    my $code = $converter->import_code('NEC', '0x10EF00FF');
    $code->alias('KEY_POWER');

    my $lirc = $converter->export_code($code, 'LIRC', name => 'TestRemote');
    like($lirc, qr/begin remote/, 'output has begin remote');
    like($lirc, qr/name\s+TestRemote/, 'remote name present');
    like($lirc, qr/bits\s+32/, '32-bit NEC');
    like($lirc, qr/header\s+9000\s+4500/, 'NEC header timings');
    like($lirc, qr/one\s+560\s+1690/, 'NEC one timings');
    like($lirc, qr/zero\s+560\s+560/, 'NEC zero timings');
    like($lirc, qr/KEY_POWER\s+0x10EF00FF/, 'button name and value');
    like($lirc, qr/end remote/, 'output has end remote');
};

# --- Export: Samsung code to LIRC ---------------------------------------

subtest 'export Samsung code to LIRC' => sub {
    # Build through the converter so the code carries proper address/command
    # fields and the accumulated data word, as Import/CSV/Pronto do; a raw
    # Code->new with a display hex and no fields would be probed, detected as
    # accumulated, and reversed on export instead of passing through.
    my $code = $converter->import_code('SAMSUNG', '0xE0E040BF');
    $code->alias('KEY_POWER');

    my $lirc = $converter->export_code($code, 'LIRC', name => 'SamsungTV');
    like($lirc, qr/bits\s+32/, '32-bit Samsung');
    like($lirc, qr/header\s+4500\s+4500/, 'Samsung header timings');
    like($lirc, qr/KEY_POWER\s+0xE0E040BF/, 'button value (display form)');
};

# --- Roundtrip: Samsung LIRC import -> export ---------------------------

subtest 'Samsung LIRC roundtrip' => sub {
    my $codes = $converter->import_format('LIRC', $samsung_lirc);
    my $lirc_out = $converter->export_codes('LIRC', $codes, name => 'SamsungRT');

    like($lirc_out, qr/begin remote/, 'roundtrip produces valid LIRC');
    like($lirc_out, qr/SamsungRT/, 'roundtrip preserves name');

    # Re-import should recover the same codes
    my $codes2 = $converter->import_format('LIRC', $lirc_out);
    is(scalar @$codes2, scalar @$codes, 'roundtrip preserves button count');

    # Check POWER survived
    my ($p1) = grep { $_->alias eq 'KEY_POWER' } @$codes;
    my ($p2) = grep { $_->alias eq 'KEY_POWER' } @$codes2;
    ok($p1 && $p2, 'POWER button present in both directions');
    is($p2->data, $p1->data, 'POWER data survives roundtrip');
};

# --- CLI integration -----------------------------------------------------

sub _run_ir_convert {
    my (@args) = @_;
    my $cmd = File::Spec->catfile(dirname(__FILE__), '..', 'bin', 'ir-convert');
    my $lib = File::Spec->catdir(dirname(__FILE__), '..', 'lib');
    my @quoted = map { "'" . ($_ =~ s/'/'\\''/gr) . "'" } @args;
    my $out = `$^X -I'$lib' '$cmd' @quoted 2>/dev/null`;
    my $exit = $? >> 8;
    return ($out, $exit);
}

subtest 'CLI: lirc to pronto' => sub {
    my ($out, $exit) = _run_ir_convert('--from', 'lirc', '--to', 'pronto',
        '--in', $samsung_lirc);
    is($exit, 0, 'exits 0');
    my @lines = grep { /\S/ } split /\n/, $out;
    is(scalar @lines, 43, 'one Pronto line per button');
    ok($lines[0] =~ /^0000 /, 'raw Pronto hex lines');
};

subtest 'CLI: nec code to lirc' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $pronto_file = File::Spec->catfile($dir, 'nec.pronto');

    my $code = $converter->import_code('NEC', '0x10EF00FF');
    my $pronto = $converter->export_code($code, 'Pronto');
    open my $fh, '>', $pronto_file or die "Cannot write: $!\n";
    print {$fh} $pronto;
    close $fh;

    my ($out, $exit) = _run_ir_convert('--from', 'pronto', '--to', 'lirc',
        '--in', $pronto_file, '--name', 'CLI Test');
    is($exit, 0, 'exits 0');
    like($out, qr/begin remote/, 'LIRC output');
    like($out, qr/CLI Test/, 'name passed through');
};

# --- Error handling ------------------------------------------------------

subtest 'error on empty input' => sub {
    eval { $converter->import_format('LIRC', '') };
    like($@, qr/empty/i, 'rejects empty input');
};

subtest 'error on no begin remote' => sub {
    eval { $converter->import_format('LIRC', "just some text\nno remote here\n") };
    like($@, qr/begin remote/i, 'rejects input without begin remote');
};

done_testing;
