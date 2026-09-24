#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestData qw(pronto_to_pairs);
use Protocol::IR::Converter;
use Protocol::IR::Proto::JVC;

my $converter = Protocol::IR::Converter->new();

my $raw = Protocol::IR::Proto::JVC->decode_raw(0x030C);
isa_ok($raw, 'Protocol::IR::Code');
is($raw->protocol,   'JVC',   'protocol');
is($raw->bits,       16,      'bits');
is($raw->address,    0x03,    'address');
is($raw->subaddress, -1,      'subaddress unused');
is($raw->command,    0x0C,    'command');
is($raw->data,       0x030C,  'packed data');

my $params = Protocol::IR::Proto::JVC->decode_params(address => 3, command => 12);
is($params->data, 0x030C, 'params pack into the same data word');

my $pronto = $converter->export_code($raw, 'Pronto');
like($pronto, qr/^0000 006D/, 'Pronto header carries 38 kHz frequency word');

my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'JVC',  'decode_timing identifies JVC');
is($back->data,     $raw->data, 'timing roundtrip preserves data');

# A frame with JVC's header but a corrupt stop bit must be rejected rather
# than misidentified.
my @pairs = @{ pronto_to_pairs($pronto) };
my @bad = @pairs;
$bad[17] = [100, 1000];
is(Protocol::IR::Proto::JVC->decode_timing(\@bad), undef,
    'rejects corrupt stop bit');

# Real Tasmota capture of a JVC frame.
my $capture = "+8495-4070+660-1440C-1450+620-430+655-390H-400+645-405Ci+650jHeCdC-1445+625-425M-1480OjMjCiC";
my $cap = $converter->import_format('Tasmota', $capture)->[0];
is($cap->protocol, 'JVC', 'real JVC capture decodes as JVC');
is($cap->data,     0x317, 'real JVC capture data matches DataLSB');
is($cap->address,  3,     'real JVC capture address');
is($cap->command,  23,    'real JVC capture command');

done_testing;
