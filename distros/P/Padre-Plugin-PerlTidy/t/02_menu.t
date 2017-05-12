#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
	if ( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}

plan tests => 13;

use Padre::Plugin::PerlTidy;

SCOPE: {
	my @menu = Padre::Plugin::PerlTidy->menu_plugins_simple;
	is @menu, 2, 'one menu item';
	is $menu[0], 'Perl Tidy', 'plugin name';

	is( @{ $menu[1] }, 10, '5 key-value pairs' );

	# check for existence and not the actual words as these
	# are locale specific
	ok $menu[1][0], 'menu item 1';
	ok ref $menu[1][1], 'menu item 1 (value)';

	ok $menu[1][2], 'menu item 2';
	ok ref $menu[1][3], 'menu item 2 (value)';

	ok $menu[1][4], 'separator';
	ok !defined $menu[1][5], 'separator (value)';

	ok $menu[1][6], 'menu item 3';
	ok ref $menu[1][7], 'menu item 3 (value)';

	ok $menu[1][8], 'menu item 4';
	ok ref $menu[1][9], 'menu item 4 (value)';
}
