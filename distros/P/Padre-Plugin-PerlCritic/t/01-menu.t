#!/usr/bin/perl

# Test the menu structure of Perl::Critic

use strict;
use warnings;

use Test::More;

BEGIN {
	if ( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}

plan tests => 3;

use Padre::Plugin::PerlCritic;

my @menu = Padre::Plugin::PerlCritic->menu_plugins_simple;
is( @menu,         2,                               'Found one menu item' );
is( $menu[0],      'Perl Critic',                   'Plugin name' );
is( $menu[1]->[0], 'Perl::Critic Current Document', 'Menu item 1, Perl::Critic Current Document' );
