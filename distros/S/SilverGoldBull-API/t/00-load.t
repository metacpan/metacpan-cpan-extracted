#!perl -T

use strict;
use warnings;
use Test::More;

plan tests => 10;

BEGIN {
    use_ok( 'SilverGoldBull::API' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::Order' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::Quote' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::Item' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::BillingAddress' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::ShippingAddress' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::Response' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::CommonMethodsRole' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::OrderRole' ) || print "Bail out!\n";
    use_ok( 'SilverGoldBull::API::AddressRole' ) || print "Bail out!\n";
}

diag( "Testing SilverGoldBull::API $SilverGoldBull::API::VERSION, Perl $], $^X" );
