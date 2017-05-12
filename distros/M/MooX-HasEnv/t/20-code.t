#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use MooXTestBlub;

$ENV{MOOX_HAS_ENV_CODE_A} = 'OVERRIDDEN';

my $test = MooXTestBlub->new;

isa_ok($test,'MooXTestBlub');
is($test->bla,'blub','Testing bla value');

done_testing;
