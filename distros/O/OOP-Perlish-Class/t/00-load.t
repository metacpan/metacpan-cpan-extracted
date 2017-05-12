#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'OOP::Perlish::Class' );
}

diag( "Testing OOP::Perlish::Class $OOP::Perlish::Class::VERSION, Perl $], $^X" );
