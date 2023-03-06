#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Museum::Rijksmuseum::Object' ) || print "Bail out!\n";
    use_ok( 'Museum::Rijksmuseum::Object::Harvester' ) || print "Bail out!\n";
}

diag( "Testing Museum::Rijksmuseum::Object $Museum::Rijksmuseum::Object::VERSION, Perl $], $^X" );
diag( "Testing Museum::Rijksmuseum::Object::Harvester $Museum::Rijksmuseum::Object::Harvester::VERSION, Perl $], $^X" );
