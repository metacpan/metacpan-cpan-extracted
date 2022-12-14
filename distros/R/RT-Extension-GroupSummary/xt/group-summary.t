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

if (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $m->content_like(qr{<span class="label">Name</span>\s*<span class="value">Test Group</span>}, 'Name in Group Summary page');
    $m->content_like(qr{<span class="label">Description</span>\s*<span class="value">This group is used for testing</span>}, 'Name in Group Summary page');
    $m->content_like(qr{<td class="label">GroupCF:</td>\s*<td class="value">\s*I am a group CF\s*</td>}, 'Group CF in Group Summary page');
} else {
    $m->content_like(qr{<div class="label col-\d+">Name</div>\s*<div class="value col-\d+"><span class="current-value">Test Group</span></div>}, 'Name in Group Summary page');
    $m->content_like(qr{<div class="label col-\d+">Description</div>\s*<div class="value col-\d+"><span class="current-value">This group is used for testing</span></div>}, 'Name in Group Summary page');
    $m->content_like(qr{<div class="label col-\d+">\s*<span class="prev-icon-helper">GroupCF:</span><span class="far fa-question-circle icon-helper" data-toggle="tooltip" data-placement="top" data-original-title="Enter one value"></span>\s*</div>\s*<div class="value col-\d+\s*">\s*<span class="current-value">\s*I am a group CF\s*</span>\s*<\/div>}, 'Group CF in Group Summary page');
}

$m->links_ok('/Admin/Groups/Modify.html?id=' . $group->id, 'Link to Group Modify page');

undef $m;
