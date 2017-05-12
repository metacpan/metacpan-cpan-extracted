#!perl -T

use lib qw( ../lib );

use Test::More tests => 9;

BEGIN {
    use_ok( 'Net::MyCommerce::API' ) || print "Bail out!
";
}

diag( "Testing Net::MyCommerce::API $Net::MyCommerce::API::VERSION, Perl $], $^X" );

use_ok( 'Net::MyCommerce::API::Client' );
use_ok( 'Net::MyCommerce::API::Resource' );
use_ok( 'Net::MyCommerce::API::Token' );
use_ok( 'Net::MyCommerce::API::Resource::Carts' );
use_ok( 'Net::MyCommerce::API::Resource::Orders' );
use_ok( 'Net::MyCommerce::API::Resource::Products' );
use_ok( 'Net::MyCommerce::API::Resource::PAR' );
use_ok( 'Net::MyCommerce::API::Resource::Vendors' );
