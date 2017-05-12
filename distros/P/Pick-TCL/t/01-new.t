#!perl -T

use Test::More tests => 2;

use Pick::TCL;

my $ap = Pick::TCL->new();
ok( defined $ap, 'new() returned something' );
ok( $ap->isa('Pick::TCL'), ' with the right class' );

# diag( "Testing Pick::TCL $Pick::TCL::VERSION, Perl $], $^X" );
