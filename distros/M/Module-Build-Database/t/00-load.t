#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Module::Build::Database' );
}

diag( "Testing Module::Build::Database $Module::Build::Database::VERSION, Perl $], $^X" );

