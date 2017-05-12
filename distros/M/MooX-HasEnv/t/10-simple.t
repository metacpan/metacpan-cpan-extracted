#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use MooXTestBla;

$ENV{MOOX_HAS_ENV_TEST_BLAOVER} = 'OVERRIDDEN';
$ENV{MOOX_HAS_ENV_ZEROTEST} = '0';

my $test = MooXTestBla->new( over => 'blablub' );

isa_ok($test,'MooXTestBla');
is($test->bla,'blub','Testing bla value');
is($test->blaover,'OVERRIDDEN','Testing blaover value');
is($test->blabla,'blubblub','Testing blabla value');
is($test->over,'blablub','Testing over value');
is($test->nodefault,undef,'Testing nodefault value');
is($test->zerotest,"0",'Testing zerotest value');
is($test->zerodef,"0",'Testing zerodef value');

done_testing;
