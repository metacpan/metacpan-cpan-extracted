
use strict;
use warnings;

use Test::More (-x '/bin/hostname' ? (tests => 8)
                                   : (skip_all => 'No /bin/hostname'));

use System::Sub
    hostname => [ '$0' => '/bin/hostname' ],
    'hostname_proto()' => [ '$0' => '/bin/hostname' ],
    'hostname_proto2' => [ '()' => '', '$0' => '/bin/hostname' ];

my $expected = `hostname`;
chomp $expected;

my $got = hostname;
is($got, $expected, 'scalar context');
is(prototype \&hostname, undef, 'prototype: undef');

$got = hostname_proto;
is($got, $expected, 'scalar context');
is(prototype \&hostname_proto, '', 'prototype: ""');

is(scalar eval 'hostname_proto(1)', undef, 'call with arg fails');
like($@, qr/Too many arguments for main::hostname_proto at /, 'error "Too many arguments"');

$got = hostname_proto2;
is($got, $expected, 'scalar context');
is(prototype \&hostname_proto2, '', 'prototype: ""');


# vim:set et sw=4 sts=4:
