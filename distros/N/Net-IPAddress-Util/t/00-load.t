#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Net::IPAddress::Util' );
    use_ok( 'Net::IPAddress::Util::Range' );
    use_ok( 'Net::IPAddress::Util::Collection' );
    use_ok( 'Net::IPAddress::Util::Collection::Tie' );
}

diag( "Testing Net::IPAddress::Util $Net::IPAddress::Util::VERSION, Perl $], mop free, $^X" );
