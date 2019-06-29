#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();
my $perl;

$perl = $internal->_read_shebang('t/scripts/datafile');
ok(!$perl, "The datafile doesn't look like a perl program");

$perl = $internal->_read_shebang('t/scripts/perlscript');
ok($perl, "The perlscript does look like a perl program");

$internal->done_testing

