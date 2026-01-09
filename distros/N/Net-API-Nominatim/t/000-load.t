#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.03';

BEGIN {
    use_ok( 'Net::API::Nominatim' ) || print "Bail out!\n";
    use_ok( 'Net::API::Nominatim::Model::BoundingBox' ) || print "Bail out!\n";
    use_ok( 'Net::API::Nominatim::Model::Address' ) || print "Bail out!\n";
}

diag( "Testing Net::API::Nominatim $Net::API::Nominatim::VERSION, Perl $], $^X" );

done_testing();
