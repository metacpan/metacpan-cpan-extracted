#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Nagios::Plugin::ByGmond' ) || print "Bail out!\n";
}

diag( "Testing Nagios::Plugin::ByGmond $Nagios::Plugin::ByGmond::VERSION, Perl $], $^X" );
