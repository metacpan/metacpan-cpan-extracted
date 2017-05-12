#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 5;

ok 1, "$0 ***** 1";
ok 1, "$0 ***** 2";

SKIP: {
    skip "checking plan ($0 ***** 3)", 1;
    ok 1;
}

ok !exists $ENV{aggregated_current_script},
  'env variables should not hang around';
ok 1, "$0 ***** 4";
$ENV{aggregated_current_script} = $0;
