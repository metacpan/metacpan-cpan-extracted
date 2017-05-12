#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SWISH::Filters::ImageTypesToXml' ) || print "Bail out!\n";
}

diag( "Testing SWISH::Filters::ImageTypesToXml $SWISH::Filters::ImageTypesToXml::VERSION, Perl $], $^X" );
