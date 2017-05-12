#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Storage::Nexsan::NMP' ) || print "Bail out!\n";
}

diag( "Testing Storage::Nexsan::NMP $Storage::Nexsan::NMP::VERSION, Perl $], $^X" );
