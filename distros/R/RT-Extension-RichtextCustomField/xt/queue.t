use strict;
use warnings;

use RT::Extension::RichtextCustomField::Test tests => 15;

use Test::WWW::Mechanize;

my ($base, $m) = RT::Extension::RichtextCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Admin/Queues/Modify.html?Create=1', 'Create queue form');
$m->content_lacks('CKEDITOR.replace', 'CKEDITOR is not here without CF Richtext');

my $cf_richtext = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_richtext->Create(Name => 'Taylor', LookupType => 'RT::Queue', Type => 'RichtextSingle');
ok($cf_id, "CF Richtext created");
my $ok;
my $queue = RT::Queue->new(RT->SystemUser);
($ok, $msg) = $cf_richtext->AddToObject($queue);
ok($ok, "CF Richtext added to General Queue");

$m->get_ok($m->rt_base_url . 'Admin/Queues/Modify.html?Create=1', 'Create queue form');
$m->content_contains('CKEDITOR.replace', 'CKEDITOR is here with CF Richtext');

$m->submit_form(
    form_name => "ModifyQueue",
    fields    => {
        Name => 'test_queue',
        "Object-RT::Queue--CustomField-$cf_id-Value" => '<strong>rich</strong>',
    },
);
$m->content_contains("Queue created", 'Queue created');
$m->content_contains("Taylor &lt;strong&gt;rich&lt;/strong&gt; added", 'CF Richtext added');

undef $m;
