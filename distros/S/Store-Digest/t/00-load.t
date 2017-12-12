#!perl -T

use Test::More tests => 7;

BEGIN {
    use_ok( 'Store::Digest::Types' ) || print "Bail out!\n";
    use_ok( 'Store::Digest::Object' ) || print "Bail out!\n";
    use_ok( 'Store::Digest::Collection' ) || print "Bail out!\n";
    use_ok( 'Store::Digest::Driver' ) || print "Bail out!\n";
    use_ok( 'Store::Digest::Driver::FileSystem' ) || print "Bail out!\n";
    use_ok( 'Store::Digest' ) || print "Bail out!\n";
    use_ok( 'Store::Digest::HTTP' ) || print "Bail out!\n";
}

diag( "Testing Store::Digest $Store::Digest::VERSION, Perl $], $^X" );
