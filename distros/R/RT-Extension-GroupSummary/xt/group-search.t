use strict;
use warnings;

use RT::Extension::GroupSummary::Test tests => 24;

use Test::WWW::Mechanize;

my $group_always_found = RT::Group->new(RT->SystemUser);
$group_always_found->CreateUserDefinedGroup(Name => 'Always Found Test Group', Description => 'This group is used for testing and should always be found in a group summary search');
my $group_always_found_id = $group_always_found->id;
my $group_always_found_name = $group_always_found->Name;

my $group_sometimes_found = RT::Group->new(RT->SystemUser);
$group_sometimes_found->CreateUserDefinedGroup(Name => 'Sometimes Found Test Group', Description => 'This group is used for testing and should sometimes be found in a group summary search');
my $group_sometimes_found_id = $group_sometimes_found->id;

my $group_hidden = RT::Group->new(RT->SystemUser);
$group_hidden->CreateUserDefinedGroup(Name => 'Hidden Test Group', Description => 'This group is used for testing and should *not* be found in a group summary search');
my $group_hidden_id = $group_hidden->id;

my ($base, $m) = RT::Extension::GroupSummary::Test->started_ok;
ok($m->login, 'Logged in agent');
$m->get_ok($m->rt_base_url . 'Group/Search.html', 'Group Summary Search page');

$m->content_like(qr{<li id="li-search-users"><a id="search-users" class="menu-item" href="/User/Search.html">Users</a></li>\s*<li id="li-search-groups"><a id="search-groups" class="menu-item" href="/Group/index.html">Groups</a></li>}, 'Group Search in menu');
$m->content_like(qr{<input type="text" name="GroupString" value="" data-autocomplete="Groups" id="autocomplete-GroupString" />}, 'Go to group input field');
$m->content_like(qr{<select name="GroupField">\s*<option  value="Name">Name</option>\s*<option  value="Description">Description</option>\s*</select>}, 'GroupField input field');
$m->content_like(qr{<select name="GroupOp">\s*<option value="LIKE"  selected="selected">matches</option>\s*<option value="NOT LIKE" >doesn&#39;t match</option>\s*<option value="=" >is</option>\s*<option value="!=" >isn&#39;t</option>\s*</select>}, 'GroupOp input field');
$m->content_like(qr{<input size="8" name="GroupString" value="" />}, 'GroupString input field');

$m->content_like(qr{<tbody class="list-item" data-record-id="$group_always_found_id">}, 'First group found without request');
$m->content_like(qr{<tbody class="list-item" data-record-id="$group_sometimes_found_id">}, 'Second group found without request');
$m->content_like(qr{<tbody class="list-item" data-record-id="$group_hidden_id">}, 'Third group found without request');

$m->submit_form(
    form_number => 4,
    fields    => {
        GroupField  => 'Name',
        GroupOp     => 'LIKE',
        GroupString => 'found',
    },
);
$m->warning_like(qr/Case sensitive search by Groups.Name/, "Case sensitive search warning");

$m->content_like(qr{<tbody class="list-item" data-record-id="$group_always_found_id">}, 'First group found with large request');
$m->content_like(qr{<tbody class="list-item" data-record-id="$group_sometimes_found_id">}, 'First group found with large request');
$m->content_unlike(qr{<tbody class="list-item" data-record-id="$group_hidden_id">}, 'Second group not found with large request');

$m->submit_form(
    form_number => 4,
    fields    => {
        GroupField  => 'Name',
        GroupOp     => 'LIKE',
        GroupString => 'Always',
    },
);
$m->warning_like(qr/Case sensitive search by Groups.Name/, "Another case sensitive search warning");

$m->title_like(qr{Group: $group_always_found_name}, 'Redirect to first group summary with narrow request');

undef $m;
