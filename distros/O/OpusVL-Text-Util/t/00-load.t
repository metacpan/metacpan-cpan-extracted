#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'OpusVL::Text::Util' ) || print "Bail out!\n";
}

diag( "Testing OpusVL::Text::Util $OpusVL::Text::Util::VERSION, Perl $], $^X" );
