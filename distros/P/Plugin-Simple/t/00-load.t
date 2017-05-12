#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Plugin::Simple' ) || print "Bail out!\n";
}

use Plugin::Simple sub_name => 'blah';
