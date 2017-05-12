use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 18;

BEGIN {
	use_ok( 'Padre',                 '0.96' );
	use_ok( 'Padre::Plugin',         '0.96' );
	use_ok( 'Padre::Wx::Role::Main', '0.96' );
}

######
# let's check our subs/methods.
######

my @subs = qw( padre_interfaces plugin_name menu_plugins_simple
	plugin_disable plugin_icon load_dialog_recipe01_main load_dialog_recipe02_main
	load_dialog_recipe03_main load_dialog_recipe04_main );

BEGIN {
	use_ok( 'Padre::Plugin::Cookbook', @subs );
}

can_ok( 'Padre::Plugin::Cookbook', @subs );

my @needs = Padre::Plugin::Cookbook::padre_interfaces();
cmp_ok( @needs % 2, '==', 0, 'plugin interface check' );

######
# let's check our lib's are here.
######
my $test_object;
require Padre::Plugin::Cookbook::Recipe01::Main;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe01::Main');

require Padre::Plugin::Cookbook::Recipe01::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe01::FBP::MainFB');

require Padre::Plugin::Cookbook::Recipe02::Main;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe02::Main');

require Padre::Plugin::Cookbook::Recipe02::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe02::FBP::MainFB');

require Padre::Plugin::Cookbook::Recipe03::Main;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe03::Main');

require Padre::Plugin::Cookbook::Recipe03::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe03::FBP::MainFB');

require Padre::Plugin::Cookbook::Recipe03::About;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe03::About');

require Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB');

require Padre::Plugin::Cookbook::Recipe04::Main;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::Main');

require Padre::Plugin::Cookbook::Recipe04::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::FBP::MainFB');

require Padre::Plugin::Cookbook::Recipe04::About;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::About');

require Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');

done_testing();

__END__

