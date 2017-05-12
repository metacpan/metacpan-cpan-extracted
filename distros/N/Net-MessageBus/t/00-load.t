#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Net::MessageBus::Base' )   || print "Bail out!\n";
    use_ok( 'Net::MessageBus' )         || print "Bail out!\n";
    use_ok( 'Net::MessageBus::Server' ) || print "Bail out!\n";
    use_ok( 'Net::MessageBus::Message' ) || print "Bail out!\n";
}

diag( "Testing Net::MessageBus $Net::MessageBus::VERSION, Perl $], $^X" );
