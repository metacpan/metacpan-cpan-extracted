#!perl

use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok( 'Net::SSH::Tunnel' ) || print "Bail out!\n";
}