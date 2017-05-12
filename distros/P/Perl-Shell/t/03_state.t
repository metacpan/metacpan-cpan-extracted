#!/usr/bin/perl

# Verify the state package behaves as expected

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Perl::Shell;

# Create the state
my $state = Perl::Shell::_State->new;
isa_ok( $state, 'Perl::Shell::_State' );
is( $state->get_package, 'main', 'Initial package is main' );

# Does the normal lexical behaviour work
$state->do('my $var = 1;');
$state->do('$var += 1;');
$state->do('$var += 1;');
$state->do('$My::OUTPUT = $var;');
$My::OUTPUT = $My::OUTPUT; # Prevent a warning
is( $My::OUTPUT, 3, 'Lexical variable persisted correctly' );

# Is the package sticky
$state->do('package Foo;');
is( $state->get_package, 'Foo' );
$state->do('sub bar { return 4; }');
is( Foo::bar(), 4, 'Package sticks correctly' );
