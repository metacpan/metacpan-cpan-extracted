#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Code;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

is($converter->get_protocol('nec'), 'Protocol::IR::Proto::NEC', 'protocol lookup is case-insensitive');
is($converter->get_protocol('JVC'), 'Protocol::IR::Proto::JVC', 'protocol lookup by name');

$converter->register_protocol('TESTPROTO', 'Protocol::IR::TestProto');
is($converter->get_protocol('TESTPROTO'), 'Protocol::IR::TestProto', 'register_protocol stores handler');

my @order = $converter->get_protocols();
is_deeply(\@order, ['Protocol::IR::Proto::Pioneer', 'Protocol::IR::Proto::NEC', 'Protocol::IR::Proto::NEC2',
    'Protocol::IR::Proto::NEC48', 'Protocol::IR::Proto::NEC482',
    'Protocol::IR::Proto::JVC', 'Protocol::IR::Proto::JVC48',
    'Protocol::IR::Proto::Panasonic',
    'Protocol::IR::Proto::Sony20', 'Protocol::IR::Proto::Sony15',
    'Protocol::IR::Proto::Sony12',
    'Protocol::IR::Proto::SAMSUNG', 'Protocol::IR::Proto::SAMSUNG36',
    'Protocol::IR::Proto::SAMSUNG20', 'Protocol::IR::Proto::NECX1',
    'Protocol::IR::Proto::NECX2', 'Protocol::IR::Proto::MWM',
    'Protocol::IR::Proto::RC5', 'Protocol::IR::Proto::RC6',
    'Protocol::IR::Proto::Mitsubishi', 'Protocol::IR::Proto::Denon', 'Protocol::IR::Proto::Sharp', 'Protocol::IR::Proto::Aiwa', 'Protocol::IR::Proto::GICable', 'Protocol::IR::Proto::Dish',
    'Protocol::IR::Proto::DenonK', 'Protocol::IR::Proto::Denon1', 'Protocol::IR::TestProto'],
    'get_protocols preserves registration order');

eval { $converter->import_code('BOGUS', '0x00'); };
like($@, qr/unsupported protocol/i, 'unknown protocol dies');

eval { $converter->export_code(Protocol::IR::Code->new(), 'BOGUS'); };
like($@, qr/unsupported format/i, 'unknown format dies');

done_testing;
