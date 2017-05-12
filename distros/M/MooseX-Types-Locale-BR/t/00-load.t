#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Types::Locale::BR' ) || print "Bail out!\n";
}

diag( "Testing MooseX::Types::Locale::BR $MooseX::Types::Locale::BR::VERSION, Perl $], $^X" );
