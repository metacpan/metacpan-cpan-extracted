use strict;
use warnings;

use RT::Extension::RichtextCustomField::Test tests => 15;

use Test::WWW::Mechanize;

my ($base, $m) = RT::Extension::RichtextCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Admin/Groups/Modify.html?Create=1', 'Create group form');
$m->content_lacks('CKEDITOR.replace', 'CKEDITOR is not here without CF Richtext');

my $cf_richtext = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_richtext->Create(Name => 'Taylor', LookupType => 'RT::Group', Type => 'RichtextSingle');
ok($cf_id, "CF Richtext created");
my $group = RT::Group->new(RT->SystemUser);
my $ok;
($ok, $msg) = $cf_richtext->AddToObject($group);
ok($ok, "CF Richtext added to RT::Group");

$m->get_ok($m->rt_base_url . 'Admin/Groups/Modify.html?Create=1', 'Create group form');
$m->content_contains('CKEDITOR.replace', 'CKEDITOR is here with CF Richtext');

$m->submit_form(
    form_name => "ModifyGroup",
    fields    => {
        Name => 'test_group',
        "Object-RT::Group--CustomField-$cf_id-Value" => '<strong>rich</strong>',
    },
);
$m->content_contains("Group created", 'Group created');
$m->content_contains("Taylor &lt;strong&gt;rich&lt;/strong&gt; added", 'CF Richtext added');

undef $m;
