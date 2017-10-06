use strict;
use warnings;

use RT::Extension::GroupSummary::Test tests => 12;

use Test::WWW::Mechanize;

my $cf = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf->Create(Name => 'GroupCF', LookupType => 'RT::Group', Type => 'FreeformSingle');
my $group = RT::Group->new(RT->SystemUser);
$group->CreateUserDefinedGroup(Name => 'Test Group', Description => 'This group is used for testing');
$cf->AddToObject($group);
$group->AddCustomFieldValue(Field => $cf->id , Value => 'I am a group CF');

my ($base, $m) = RT::Extension::GroupSummary::Test->started_ok;
ok($m->login, 'Logged in agent');
$m->get_ok($m->rt_base_url . 'Group/Summary.html?id=' . $group->id, 'Group summary page');

$m->content_like(qr{<span class="label">Name</span>\s*<span class="value">Test Group</span>}, 'Name in Group Summary page');

$m->content_like(qr{<span class="label">Description</span>\s*<span class="value">This group is used for testing</span>}, 'Name in Group Summary page');

$m->content_like(qr{<td class="label">GroupCF:</td>\s*<td class="value">\s*I am a group CF\s*</td>}, 'Group CF in Group Summary page');

$m->links_ok('/Admin/Groups/Modify.html?id=' . $group->id, 'Link to Group Modify page');

undef $m;
