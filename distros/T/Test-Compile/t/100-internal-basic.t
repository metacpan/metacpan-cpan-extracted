#!perl

use strict;
use warnings;

use Test::More;

require_ok('Test::Compile::Internal');

my $internal = new_ok('Test::Compile::Internal');

$internal->done_testing();
