#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

$internal->plan(tests => 2);
$internal->ok(1, "ok method issues succesful TAP");
$internal->skip('Actually, skip this test');
$internal->diag("The diag method should display this message");
$internal->done_testing

