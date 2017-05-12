#!/usr/bin/perl
use Test::More;
use Dir::Self;
use lib __DIR__;

use strict;
use warnings;
BEGIN {
    $ENV{DOUBLE_FACED_DUMMIES} =1;
}

use dummy;


my $ret = expensive_function 'foo', 'bar', 'baz';
is($ret, undef, "expensive_function() overriden with DOUBLE_FACED_DUMMIES");
is(dummy::replaced_function(), 1, "Replaced function using CODE ref");


use dummy_trigger qw(BE_A_DUMMY);
$ret = expensive2();
is($ret, undef, "expensive2() overriden with import option");


use dummy_ext qw(cheapo returns_a_value);
is(returns_a_value(), 42, "Override value");


package user2;
use strict;
use warnings;
use Test::More;
use dummy_ext;
is(returns_a_value(), 42, 'Value still overidden');
is(dummy_ext::returns_a_value(), 42, 
    'fully qualified call overridden');

use dummy_notrigger;
is(foofunc(), 1, 'Module behaves when not triggered');
done_testing();
