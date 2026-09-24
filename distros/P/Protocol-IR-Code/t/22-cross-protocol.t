#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestData qw(pronto_to_pairs);
use Protocol::IR::Converter;
use Protocol::IR::Code;
use Protocol::IR::Proto::NECX2;
use Protocol::IR::Proto::SAMSUNG;

my $converter = Protocol::IR::Converter->new();

# === reverse_byte utility ===
is(Protocol::IR::Code::reverse_byte(0x00), 0x00, 'reverse_byte(0x00) = 0x00');
is(Protocol::IR::Code::reverse_byte(0xFF), 0xFF, 'reverse_byte(0xFF) = 0xFF');
is(Protocol::IR::Code::reverse_byte(0x01), 0x80, 'reverse_byte(0x01) = 0x80');
is(Protocol::IR::Code::reverse_byte(0x80), 0x01, 'reverse_byte(0x80) = 0x01');
is(Protocol::IR::Code::reverse_byte(0xE0), 0x07, 'reverse_byte(0xE0) = 0x07');
is(Protocol::IR::Code::reverse_byte(0x07), 0xE0, 'reverse_byte(0x07) = 0xE0');
is(Protocol::IR::Code::reverse_byte(0x40), 0x02, 'reverse_byte(0x40) = 0x02');
is(Protocol::IR::Code::reverse_byte(0x02), 0x40, 'reverse_byte(0x02) = 0x40');

# === SAMSUNG -> NECX2 cross-protocol ===
# Samsung TV POWER: address=0xE0, command=0x40
#   -> NECX2 device=7, subdevice=7, function=2
my $sam = $converter->import_code('SAMSUNG',
    { address => 0xE0, command => 0x40 });
is($sam->protocol, 'SAMSUNG', 'Samsung POWER imported');
is($sam->address,  0xE0,       'Samsung address');
is($sam->command,  0x40,       'Samsung command');

my $necx2_params = Protocol::IR::Proto::SAMSUNG->as_necx2_params($sam);
is($necx2_params->{device},    7,  'SAMSUNG->NECX2 device=7');
is($necx2_params->{subdevice}, 7,  'SAMSUNG->NECX2 subdevice=7');
is($necx2_params->{command},   2,  'SAMSUNG->NECX2 function=2');

# Build the NECX2 code from those params and verify it matches IRDB data
my $necx2_from_sam = $converter->import_code('NECX2', $necx2_params);
is($necx2_from_sam->data, 0x070702FD, 'SAMSUNG->NECX2 data matches IRDB Samsung POWER');

# === NECX2 -> SAMSUNG cross-protocol ===
my $necx2 = $converter->import_code('NECX2',
    { device => 7, subdevice => 7, command => 2 });
is($necx2->protocol, 'NECX2', 'NECX2 POWER imported');
is($necx2->address,  7,        'NECX2 address');
is($necx2->command,  2,        'NECX2 command');
is($necx2->subaddress, 7,      'NECX2 subaddress');

my $sam_params = Protocol::IR::Proto::NECX2->as_samsung_params($necx2);
is($sam_params->{address}, 0xE0, 'NECX2->SAMSUNG address=0xE0');
is($sam_params->{command}, 0x40, 'NECX2->SAMSUNG command=0x40');

my $sam_from_necx2 = $converter->import_code('SAMSUNG', $sam_params);
is($sam_from_necx2->data, 0x070702FD, 'NECX2->SAMSUNG data matches');

# === Converter.cross_protocol ===
my $equivs = $converter->cross_protocol($sam);
is(scalar @$equivs, 1, 'cross_protocol returns one equivalent');
is($equivs->[0]->protocol, 'NECX2',    'SAMSUNG cross-protocols to NECX2');
is($equivs->[0]->address,  7,          'cross-protocol NECX2 address');
is($equivs->[0]->command,  2,          'cross-protocol NECX2 command');
is($equivs->[0]->data,     0x070702FD, 'cross-protocol NECX2 data');

my $equivs2 = $converter->cross_protocol($necx2);
is(scalar @$equivs2, 1, 'NECX2 cross-protocol returns one equivalent');
is($equivs2->[0]->protocol, 'SAMSUNG', 'NECX2 cross-protocols to SAMSUNG');
is($equivs2->[0]->address,  0xE0,      'cross-protocol SAMSUNG address');
is($equivs2->[0]->command,  0x40,      'cross-protocol SAMSUNG command');

# === Round-trip: SAMSUNG -> NECX2 -> SAMSUNG preserves values ===
my $rt_sam = $converter->cross_protocol($equivs->[0]);
is($rt_sam->[0]->address, 0xE0, 'round-trip SAMSUNG address');
is($rt_sam->[0]->command, 0x40, 'round-trip SAMSUNG command');
is($rt_sam->[0]->data,    $sam->data, 'round-trip SAMSUNG data identical');

# === Non-cross-protocol protocols return empty ===
my $nec = $converter->import_code('NEC', '0x10EF00FF');
is(scalar @{$converter->cross_protocol($nec)}, 0, 'NEC has no cross-protocol');

my $jvc = $converter->import_code('JVC', { address => 3, command => 12 });
is(scalar @{$converter->cross_protocol($jvc)}, 0, 'JVC has no cross-protocol');

# === Samsung MUTE: address=0xE0, command=0xF0 -> NECX2 device=7, function=240 ===
my $mute_sam = $converter->import_code('SAMSUNG',
    { address => 0xE0, command => 0xF0 });
my $mute_necx2 = $converter->cross_protocol($mute_sam);
is($mute_necx2->[0]->protocol, 'NECX2', 'Samsung MUTE cross-protocols to NECX2');
is($mute_necx2->[0]->address,  7,        'Samsung MUTE NECX2 device=7');
is($mute_necx2->[0]->command,  15,       'Samsung MUTE NECX2 function=15 (bit-reverse of 0xF0)');

# Verify via the NECX2 Samsung HLN507W power-off code:
# NECX2 device=7, function=152 -> SAMSUNG address=0xE0, command=0x19
my $poweroff = $converter->import_code('NECX2',
    { device => 7, subdevice => 7, command => 152 });
my $poweroff_sam = $converter->cross_protocol($poweroff);
is($poweroff_sam->[0]->protocol, 'SAMSUNG', 'HLN507W power-off cross-protocols to SAMSUNG');
is($poweroff_sam->[0]->address,  0xE0,      'HLN507W power-off SAMSUNG address');
is($poweroff_sam->[0]->command,  0x19,      'HLN507W power-off SAMSUNG command=0x19 (25)');

done_testing;
