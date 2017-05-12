#!/usr/bin/env perl -w

use 5.10.0;
use Test::More tests => 1;
#use Test::More 'no_plan';

my $CLASS;
BEGIN {
    $CLASS = 'PGXN::Site';
    use_ok $CLASS or die;
}
