#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Basename qw(dirname);
use File::Spec;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

# --- fully decoded codes across timing formats ---------------------------
# A fully decoded code must survive conversion to and from Pronto, Tasmota
# RawData, and wig with identical protocol/data/address/command, and the
# timings generated for each format must be identical.
my @codes = (
    $converter->import_code('NEC',      { address => 4, subaddress => 0, command => 8 }),
    $converter->import_code('NEC',      '0x10EF00FF'),
    $converter->import_code('JVC',      { address => 3, command => 12 }),
    $converter->import_code('SAMSUNG',  { address => 0xE0, command => 0x40 }),
);

for my $code (@codes) {
    my $proto = $code->protocol;

    my $pronto = $converter->export_code($code, 'Pronto');
    my $tas    = $converter->export_code($code, 'Tasmota', style => 'comma');
    my $wig    = $converter->export_codes('wig', $code);

    my $from_pronto = $converter->import_format('Pronto', $pronto);
    my $from_tas    = $converter->import_format('Tasmota', $tas)->[0];
    my $from_wig    = $converter->import_format('wig', $wig)->[0];

    for my $pair ([$from_pronto, 'Pronto'], [$from_tas, 'Tasmota'], [$from_wig, 'wig']) {
        my ($decoded, $fmt) = @$pair;
        is($decoded->protocol, $proto,              "$proto survives $fmt roundtrip");
        is($decoded->data,     $code->data,         "$proto data survives $fmt roundtrip");
        is($decoded->address,  $code->address,      "$proto address survives $fmt roundtrip");
        is($decoded->command,  $code->command,      "$proto command survives $fmt roundtrip");
    }

    # Pronto and Tasmota must generate the same timing sequence for a code,
    # so re-exporting the Pronto-decoded code yields the same RawData.
    my $tas_from_pronto = $converter->export_code($from_pronto, 'Tasmota', style => 'comma');
    is($tas_from_pronto, $tas, "$proto Pronto and Tasmota generate identical timings");
}

# --- captured data across timing formats ---------------------------------
# A real capture that decodes must keep its decoded code through Pronto and
# wig as well as Tasmota.
my $fixture = File::Spec->rel2abs(File::Spec->catfile(
    dirname(__FILE__), 'data', 'tasmota-captures.log'));
open my $fh, '<', $fixture or die "Cannot open $fixture: $!\n";
my $line_no = 0;
my $checked = 0;
while (my $line = <$fh>) {
    $line_no++;
    my $rec;
    eval { $rec = decode_json($line)->{IrReceived}; 1 } or next;

    my $orig = $converter->import_format('Tasmota', $rec->{RawData})->[0];
    next if $orig->protocol eq 'UNKNOWN';
    $checked++;

    my $via_pronto = $converter->import_format('Pronto',
        $converter->export_code($orig, 'Pronto'));
    is($via_pronto->protocol, $orig->protocol, "fixture line $line_no code survives Pronto");
    is($via_pronto->data,     $orig->data,     "fixture line $line_no data survives Pronto");

    my $via_wig = $converter->import_format('wig',
        $converter->export_codes('wig', $orig))->[0];
    is($via_wig->protocol, $orig->protocol, "fixture line $line_no code survives wig");
    is($via_wig->data,     $orig->data,     "fixture line $line_no data survives wig");
}
close $fh;
cmp_ok($checked, '>=', 11, 'cross-checked the bundled capture frames');

# --- HAIR-style wig input ------------------------------------------------
# HAIR WIGs carry Pronto hex; timings are assumed to have been quantized
# and cleaned up for recognized protocols, so a properly quantized signal
# should decode correctly, and mild jitter within one carrier pulse must
# not break it.
my $code   = $converter->import_code('NEC', '0x10EF00FF');
my $pronto = $converter->export_code($code, 'Pronto');

sub wig_json {
    my ($pronto_str) = @_;
    return JSON::PP->new->utf8->canonical->encode({
        format  => 'hair-wig/3',
        name    => 'HAIR Test Remote',
        wig_id  => '00000000-0000-4000-8000-000000000000',
        signals => [ { alias => 'POWER', pronto => $pronto_str } ],
    });
}

my $clean = $converter->import_format('wig', wig_json($pronto))->[0];
is($clean->protocol, 'NEC', 'HAIR-style wig decodes protocol');
is($clean->data,     0x10EF00FF, 'HAIR-style wig decodes data');
is($clean->alias,    'POWER', 'HAIR-style wig carries alias');

# Perturb a few timing marks by a few microseconds; as long as each value
# still rounds to the same carrier pulse the signal must decode identically.
my @t  = split /\s+/, $pronto;
my $period = 1000000.0 / int(1000000.0 / (hex($t[1]) * 0.241246));
for my $idx (6, 10, 14, 18, 22, 26) {
    my $us = hex($t[$idx]) * $period;
    $t[$idx] = sprintf('%04X', int(($us + 6) / $period + 0.5));
}
my $jittered = $converter->import_format('wig', wig_json(join ' ', @t))->[0];
is($jittered->protocol, 'NEC', 'jittered HAIR-style wig still decodes');
is($jittered->data,     0x10EF00FF, 'jittered HAIR-style wig preserves data');

done_testing;
