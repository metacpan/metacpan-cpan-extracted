#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Basename qw(dirname);
use File::Spec;
use Protocol::IR::Converter;
use Protocol::IR::Proto::SAMSUNG;

my $converter = Protocol::IR::Converter->new();

# --- decode_raw ----------------------------------------------------------
my $raw = Protocol::IR::Proto::SAMSUNG->decode_raw('0xE0E040BF');
isa_ok($raw, 'Protocol::IR::Code');
is($raw->protocol,   'SAMSUNG', 'protocol');
is($raw->bits,       32,        'bits');
is($raw->address,    0xE0,      'address');
is($raw->subaddress, -1,        'subaddress unused');
is($raw->command,    0x40,      'command');
is($raw->data,       0x070702FD, 'data is the LSB-first collected value (DataLSB)');

# --- decode_params -------------------------------------------------------
my $params = Protocol::IR::Proto::SAMSUNG->decode_params(address => 0xE0, command => 0x40);
is($params->address, 0xE0,       'param address');
is($params->command, 0x40,       'param command');
is($params->data,    0x070702FD, 'params pack into the same data word');

my $params2 = Protocol::IR::Proto::SAMSUNG->decode_params(device => 4, command => 0xFF);
is($params2->address, 4,        'device alias maps to address');
is($params2->command, 0xFF,     'command kept');
is($params2->data,    0x2020FF00, 'data packs customer/command');

# --- to_pronto -----------------------------------------------------------
my $pronto = $converter->export_code($params, 'Pronto');
like($pronto, qr/^0000 006D/, 'Pronto header carries 38 kHz frequency word');
my @tokens = split /\s+/, $pronto;
is(hex($tokens[2]), 34, 'sequence1 carries header + 32 bits + stop');

# --- timing roundtrip ----------------------------------------------------
my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'SAMSUNG', 'decode_timing identifies SAMSUNG');
is($back->data,     $params->data, 'timing roundtrip preserves data');
is($back->address,  0xE0, 'timing roundtrip preserves address');
is($back->command,  0x40, 'timing roundtrip preserves command');

for my $spec ([0x04, 0xFF], [0x12, 0x56], [0xE0, 0x19], [0x00, 0x00]) {
    my ($addr, $cmd) = @$spec;
    my $label = sprintf("%02X/%02X", $addr, $cmd);
    my $code   = $converter->import_code('SAMSUNG', { address => $addr, command => $cmd });
    my $rt     = $converter->import_format('Pronto', $converter->export_code($code, 'Pronto'));
    is($rt->data,    $code->data,    "SAMSUNG $label data survives roundtrip");
    is($rt->address, $addr,          "SAMSUNG $label address survives roundtrip");
    is($rt->command, $cmd,           "SAMSUNG $label command survives roundtrip");
}

# --- stop-bit rejection --------------------------------------------------
# A SAMSUNG frame with the right header but a corrupt stop bit must be
# rejected rather than misidentified as some other protocol.
my $timings = _pronto_to_pairs($pronto);

my @short_mark = @$timings;
$short_mark[33] = [100, 30000];
is(Protocol::IR::Proto::SAMSUNG->decode_timing(\@short_mark), undef,
    'rejects stop bit with too-short mark');

my @short_space = @$timings;
$short_space[33] = [560, 500];
is(Protocol::IR::Proto::SAMSUNG->decode_timing(\@short_space), undef,
    'rejects stop bit with too-short trailing space');

# --- real captures -------------------------------------------------------
# Every SAMSUNG line in the bundled capture fixture must decode to SAMSUNG
# with data matching Tasmota's DataLSB.
my $samples = File::Spec->rel2abs(File::Spec->catfile(
    dirname(__FILE__), 'data', 'tasmota-captures.log'));
ok(-e $samples, 't/data/tasmota-captures.log present');

open my $fh, '<', $samples or die "Cannot open $samples: $!\n";
my $sam_count = 0;
while (my $line = <$fh>) {
    next unless $line =~ /\{/;
    my $rec;
    eval { $rec = decode_json($line)->{IrReceived}; 1 } or next;
    next unless $rec->{Protocol} eq 'SAMSUNG';

    $sam_count++;
    my $decoded = $converter->import_format('Tasmota', $rec->{RawData})->[0];
    is($decoded->protocol, 'SAMSUNG', "SAMSUNG sample line $. decodes as SAMSUNG");
    is($decoded->data, hex($rec->{DataLSB}), "SAMSUNG sample line $. data matches DataLSB");
}
close $fh;
cmp_ok($sam_count, '>=', 5, 'captured at least the five SAMSUNG samples');

# Known button: line 37 is Data 0xE0E040BF, i.e. customer 0xE0, command 0x40.
is($back->address, 0xE0, 'E0E040BF maps to address 0xE0');
is($back->command, 0x40, 'E0E040BF maps to command 0x40');

done_testing;

# Convert a Pronto string to microsecond burst pairs.
sub _pronto_to_pairs {
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
