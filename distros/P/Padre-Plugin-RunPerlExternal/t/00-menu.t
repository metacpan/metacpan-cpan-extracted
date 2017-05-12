use strict;
use warnings;

## 
#  Original from Padre-Plugin-PerlTidy-0.16
##
#todo: tests
use Test::More;

BEGIN {
	if ( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}

plan tests => 5;

use Padre::Plugin::RunPerlExternal;
{
	my @menu = Padre::Plugin::RunPerlExternal->menu_plugins_simple;

	is @menu, 2, 'one menu item';
	is $menu[0], 'RunPerlExternal', 'plugin name';

	is( @{ $menu[1] }, 2, '1 key-value pairs' );

	# # check for existence and not the actual words as these
	# # are locale specific
	 ok $menu[1][0], 'menu item 1';
	 ok ref $menu[1][1], 'menu item 1 (value)';

}
