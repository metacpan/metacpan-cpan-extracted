#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestData qw(pronto_to_pairs);
use Protocol::IR::Converter;
use Protocol::IR::Proto::NEC;

my $converter = Protocol::IR::Converter->new();

my $raw = Protocol::IR::Proto::NEC->decode_raw('0x10EF00FF');
isa_ok($raw, 'Protocol::IR::Code');
is($raw->protocol,   'NEC', 'protocol');
is($raw->bits,       32,    'bits');
is($raw->address,    0x10, 'address');
is($raw->subaddress, -1,   'subaddress inferred as inverse of address');
is($raw->command,    0x00, 'command');
is($raw->data,       0x10EF00FF, 'raw data preserved');

my $params = Protocol::IR::Proto::NEC->decode_params(address => 4, subaddress => 0, command => 8);
is($params->address, 4, 'param address');
is($params->subaddress, 0, 'param subaddress');
is($params->command, 8, 'param command');
is($params->data, 0x040008F7, 'packed data includes inverse command byte');

my $pronto = $converter->export_code($raw, 'Pronto');
like($pronto, qr/^0000 006D/, 'Pronto header carries 38 kHz frequency word');

my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'NEC', 'decode_timing identifies NEC');
is($back->data,     $raw->data, 'timing roundtrip preserves data');

# A frame with NEC's header but a corrupt stop bit must be rejected rather
# than misidentified.
my @pairs = @{ pronto_to_pairs($pronto) };
my @short_mark = @pairs;
$short_mark[33] = [100, 30000];
is(Protocol::IR::Proto::NEC->decode_timing(\@short_mark), undef,
    'rejects stop bit with too-short mark');
my @short_space = @pairs;
$short_space[33] = [560, 500];
is(Protocol::IR::Proto::NEC->decode_timing(\@short_space), undef,
    'rejects stop bit with too-short trailing space');

# Real Tasmota capture of a NEC frame (TV power).
my $capture = "+9185-4490+650-500+655dE-1630C-505+630-525Ed+625-530H-520H-1655JmJiCfCfHmH-1650CfHmHiEdCfCdHiHiEdHiEfCfHiEfEfEfEfC-40270+9160-2235H";
my $cap = $converter->import_format('Tasmota', $capture)->[0];
is($cap->protocol, 'NEC', 'real NEC capture decodes as NEC');
is($cap->data,     0x04FB09F6, 'real NEC capture data matches DataLSB');

done_testing;
