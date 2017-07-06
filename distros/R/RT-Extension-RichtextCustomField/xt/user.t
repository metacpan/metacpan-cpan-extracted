use strict;
use warnings;

use RT::Extension::RichtextCustomField::Test tests => 16;

use Test::WWW::Mechanize;

RT->Config->Set('UserSummaryExtraInfo', "RealName, EmailAddress, Name, CustomField.{Taylor}");

my ($base, $m) = RT::Extension::RichtextCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Admin/Users/Modify.html?Create=1', 'Create user form');
$m->content_lacks('CKEDITOR.replace', 'CKEDITOR is not here without CF Richtext');

my $cf_richtext = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_richtext->Create(Name => 'Taylor', LookupType => 'RT::User', Type => 'RichtextSingle');
ok($cf_id, "CF Richtext created");
my $user = RT::User->new(RT->SystemUser);
my $ok;
($ok, $msg) = $cf_richtext->AddToObject($user);
ok($ok, "CF Richtext added to RT::User");

$m->get_ok($m->rt_base_url . 'Admin/Users/Modify.html?Create=1', 'Create user form');
$m->content_contains('CKEDITOR.replace', 'CKEDITOR is here with CF Richtext');

$m->submit_form(
    form_name => "UserCreate",
    fields    => {
        Name => 'test_user',
        "Object-RT::User--CustomField-$cf_id-Value" => '<strong>rich</strong>',
    },
);
$m->content_contains("User created", 'User created');

$m->follow_link_ok({ id => 'page-summary' }, 'User summary link');
$m->content_contains('<strong>rich</strong>', 'CF Richtext displayed in HTML');

undef $m;
