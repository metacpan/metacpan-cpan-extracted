#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

# Without this line, this test file would fail
$internal->skip_all('Skipping this test should test skip_all()');

$internal->ok(0, "This is a failing test, but it shouldn't actually matter");
$internal->done_testing();

