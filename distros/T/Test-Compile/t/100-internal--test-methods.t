#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

$internal->plan(tests => 1);
$internal->ok(1, "ok method issues succesful TAP");
$internal->diag("The diag method should display this message");
$internal->done_testing

