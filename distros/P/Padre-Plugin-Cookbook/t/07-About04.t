use Test::More tests => 6;

use_ok('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');

######
# let's check our subs/methods.
######

my @subs = qw( new credits_clicked licence_clicked);
use_ok( 'Padre::Plugin::Cookbook::Recipe04::About', @subs );

foreach my $subs (@subs) {
	can_ok( 'Padre::Plugin::Cookbook::Recipe04::About', $subs );
}


######
# let's check our lib's are here.
######
my $test_object;

require Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB;
$test_object = new_ok('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');

done_testing();
