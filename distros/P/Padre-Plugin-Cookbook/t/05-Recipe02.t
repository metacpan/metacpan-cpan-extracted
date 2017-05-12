use Test::More tests => 10;

use_ok('Padre::Plugin::Cookbook::Recipe02::FBP::MainFB');

######
# let's check our subs/methods.
######

my @subs = qw( new output_clicked update_clicked ttennis_checked ping_checked pong_checked set_name_label_value );
use_ok( 'Padre::Plugin::Cookbook::Recipe02::Main', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Cookbook::Recipe02::Main', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::Cookbook::Recipe02::FBP::MainFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe02::FBP::MainFB');

done_testing();
