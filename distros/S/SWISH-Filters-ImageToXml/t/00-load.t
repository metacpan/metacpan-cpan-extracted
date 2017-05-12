#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SWISH::Filters::ImageToXml' ) || print "Bail out!\n";
}

diag( "Testing SWISH::Filters::ImageToXml $SWISH::Filters::ImageToXml::VERSION, Perl $], $^X" );
