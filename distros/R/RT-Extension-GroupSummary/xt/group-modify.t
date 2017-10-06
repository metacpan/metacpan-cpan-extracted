use strict;
use warnings;

use RT::Extension::GroupSummary::Test tests => 9;

use Test::WWW::Mechanize;

my $group = RT::Group->new(RT->SystemUser);
$group->CreateUserDefinedGroup(Name => 'Test Group', Description => 'This group is used for testing');

my ($base, $m) = RT::Extension::GroupSummary::Test->started_ok;
ok($m->login, 'Logged in agent');
$m->get_ok($m->rt_base_url . 'Admin/Groups/Modify.html?id=' . $group->id, 'Group modify page');

$m->links_ok('/Group/Summary.html?id=' . $group->id, 'Link to Group Summary page');

undef $m;
