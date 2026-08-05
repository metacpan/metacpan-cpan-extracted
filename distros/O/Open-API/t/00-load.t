#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Open::API' ) || print "Bail out!\n";
}

# Loading at all means BOOT resolved JSON::Schema::Fast's C ABI (the .pm
# croaks otherwise); assert it explicitly too.
ok( Open::API::_abi_ok(), 'JSON::Schema::Fast C ABI resolved' );

diag( "Testing Open::API $Open::API::VERSION, Perl $], $^X" );

done_testing();
