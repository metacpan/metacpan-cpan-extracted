#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::DBIxTransactionManager' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::DBIxTransactionManager $Mojolicious::Plugin::DBIxTransactionManager::VERSION, Perl $], $^X" );
