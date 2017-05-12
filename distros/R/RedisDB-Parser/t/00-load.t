#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RedisDB::Parser' ) || print "Bail out!\n";
}

diag( "Testing RedisDB::Parser $RedisDB::Parser::VERSION, Perl $], $^X" );
