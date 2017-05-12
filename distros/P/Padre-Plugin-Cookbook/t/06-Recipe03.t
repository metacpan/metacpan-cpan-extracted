use Test::More tests => 7;

use_ok('Padre::Plugin::Cookbook::Recipe03::FBP::MainFB');

######
# let's check our subs/methods.
######

my @subs = qw( new about_clicked plugin_disable load_dialog_about );
use_ok( 'Padre::Plugin::Cookbook::Recipe03::Main', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Cookbook::Recipe03::Main', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::Cookbook::Recipe03::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe03::FBP::MainFB');

done_testing();
