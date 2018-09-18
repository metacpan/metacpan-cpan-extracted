#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Role::Kerberos' ) || print "Bail out!\n";
}

diag( "Testing Role::Kerberos $Role::Kerberos::VERSION, Perl $], $^X" );
