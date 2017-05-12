use Test::More tests => 17;

use_ok('Padre::Plugin::Cookbook::Recipe04::FBP::MainFB');

######
# let's check our subs/methods.
######

my @subs = qw( new about_clicked about_menu_clicked  clean_clicked clean_session clean_session_files clean_history clean_lastpositioninfile plugin_disable load_dialog_about set_up update_clicked show_clicked width_adjust_clicked );
use_ok( 'Padre::Plugin::Cookbook::Recipe04::Main', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Cookbook::Recipe04::Main', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::Cookbook::Recipe04::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::FBP::MainFB');

done_testing();
