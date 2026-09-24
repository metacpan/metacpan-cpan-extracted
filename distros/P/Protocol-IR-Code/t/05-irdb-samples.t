#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

my $data_dir = File::Spec->catdir(dirname(__FILE__), 'data');

# --- Real IRDB NEC receiver capture --------------------------------------
my $nec_file = File::Spec->catfile($data_dir, 'irdb-nec-receiver.csv');
ok(-e $nec_file, 'NEC IRDB fixture present');

my $nec = $converter->import_format('CSV', $nec_file);
is(scalar(@$nec), 7, 'NEC fixture yields 7 buttons');

my %nec_by_alias = map { $_->alias => $_ } @$nec;
ok($nec_by_alias{'VCR POWER'}, 'POWER button imported');
is($nec_by_alias{'VCR POWER'}->protocol, 'NEC', 'NEC1 normalized to NEC');
is($nec_by_alias{'VCR POWER'}->address, 25, 'POWER address');
is($nec_by_alias{'VCR POWER'}->subaddress, -1, 'single-byte address inferred');
is($nec_by_alias{'VCR POWER'}->command, 8, 'POWER command');
is($nec_by_alias{'VCR POWER'}->data, 0x19E608F7, 'POWER packs into expected data word');
is($nec_by_alias{'VCR STOP []'}->data, 0x19E604FB, 'STOP packs into expected data word');

# Every imported NEC button can be encoded to Pronto and decoded back.
my $rt = $converter->import_format('Pronto',
    $converter->export_code($nec_by_alias{'VCR POWER'}, 'Pronto'));
is($rt->address, 25, 'NEC POWER address survives Pronto roundtrip');
is($rt->command, 8,  'NEC POWER command survives Pronto roundtrip');
is($rt->data,    0x19E608F7, 'NEC POWER data survives Pronto roundtrip');

# --- Real IRDB JVC VCR capture -------------------------------------------
my $jvc_file = File::Spec->catfile($data_dir, 'irdb-jvc-vcr.csv');
ok(-e $jvc_file, 'JVC IRDB fixture present');

my $jvc = $converter->import_format('CSV', $jvc_file);
is(scalar(@$jvc), 5, 'JVC fixture yields 5 buttons');

my %jvc_by_alias = map { $_->alias => $_ } @$jvc;
is($jvc_by_alias{'TAPE PLAY >'}->protocol, 'JVC', 'JVC protocol kept');
is($jvc_by_alias{'TAPE PLAY >'}->address, 131, 'PLAY address');
is($jvc_by_alias{'TAPE PLAY >'}->command, 12, 'PLAY command');
is($jvc_by_alias{'TAPE PLAY >'}->data, 0x830C, 'PLAY packs into expected data word');
is($jvc_by_alias{'TAPE STOP []'}->data, 0x8303, 'STOP packs into expected data word');

my $jrt = $converter->import_format('Pronto',
    $converter->export_code($jvc_by_alias{'TAPE PLAY >'}, 'Pronto'));
is($jrt->address, 131, 'JVC PLAY address survives Pronto roundtrip');
is($jrt->command, 12,  'JVC PLAY command survives Pronto roundtrip');
is($jrt->data,    0x830C, 'JVC PLAY data survives Pronto roundtrip');

# --- Real IRDB Samsung TV capture -----------------------------------------
my $sam_file = File::Spec->catfile($data_dir, 'irdb-samsung-tv.csv');
ok(-e $sam_file, 'Samsung IRDB fixture present');

my $sam = $converter->import_format('CSV', $sam_file);
is(scalar(@$sam), 7, 'Samsung fixture yields 7 buttons');

my %sam_by_alias = map { $_->alias => $_ } @$sam;
is($sam_by_alias{'POWER'}->protocol, 'NECX2', 'NECX2 protocol kept');
is($sam_by_alias{'POWER'}->address, 7, 'POWER address');
is($sam_by_alias{'POWER'}->subaddress, 7, 'POWER subaddress');
is($sam_by_alias{'POWER'}->command, 2, 'POWER command');
is($sam_by_alias{'POWER'}->data, 0x070702FD, 'POWER packs into expected data word');
is($sam_by_alias{'VOLUME +'}->data, 0x070707F8, 'VOLUME+ packs into expected data word');
is($sam_by_alias{'MUTE'}->data, 0x07070FF0, 'MUTE packs into expected data word');
is($sam_by_alias{'ENTER'}->data, 0x07076897, 'ENTER packs into expected data word');

# NECx2 shares the 4500/4500 header with Samsung; Pronto roundtrip may
# decode as Samsung rather than preserving the NECx2 classification.
# Verify the data word survives even if the protocol label changes.
my $srt = $converter->import_format('Pronto',
    $converter->export_code($sam_by_alias{'POWER'}, 'Pronto'));
is($srt->data, 0x070702FD, 'NECx2 POWER data survives Pronto roundtrip');

done_testing;
