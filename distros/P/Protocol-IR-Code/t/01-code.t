#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Code;

my $code = Protocol::IR::Code->new();
is($code->protocol,   'UNKNOWN', 'default protocol');
is($code->bits,       0,         'default bits');
is($code->address,    0,         'default address');
is($code->subaddress, -1,        'default subaddress');
is($code->command,    0,         'default command');
is($code->data,       undef,     'default data');
is($code->alias,      '',        'default alias');

$code->protocol('NEC');
$code->bits(32);
is($code->protocol, 'NEC', 'protocol accessor sets value');
is($code->bits,     32,    'bits accessor sets value');

my $with_data = Protocol::IR::Code->new(protocol => 'NEC', bits => 32, data => 0x10EF00FF);
is_deeply(
    $with_data->to_irsend(),
    { Protocol => 'NEC', Bits => 32, Data => '0x10EF00FF' },
    'to_irsend includes Data when set',
);

my $no_data = Protocol::IR::Code->new(protocol => 'JVC', bits => 16);
is_deeply(
    $no_data->to_irsend(),
    { Protocol => 'JVC', Bits => 16 },
    'to_irsend omits Data when unset',
);

my $with_timings = Protocol::IR::Code->new(protocol => 'NEC', bits => 32, timings => [1, -2, 3]);
is_deeply($with_timings->timings, [1, -2, 3], 'timings accessor returns stored list');
is(Protocol::IR::Code->new()->timings, undef, 'timings default to undef');

done_testing;
