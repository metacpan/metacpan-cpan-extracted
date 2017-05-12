#!perl

use Test::More;

use_ok( 'DBIx::Class::Schema::Loader' );
use_ok( 'Mojolicious::Command::generate::dbicdump' ) || print "Bail out!\n";

diag( "Testing Mojolicious::Command::generate::dbicdump $Mojolicious::Command::generate::dbicdump::VERSION, Perl $], $^X" );

done_testing();
