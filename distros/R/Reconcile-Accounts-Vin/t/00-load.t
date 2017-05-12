#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Reconcile::Accounts::Vin' ) || print "Bail out!\n";
}

diag( "Testing Reconcile::Accounts::Vin $Reconcile::Accounts::Vin::VERSION, Perl $], $^X" );
