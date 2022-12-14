use strict;
use warnings;

use RT::Extension::RichtextCustomField::Test tests => 14;

use Test::WWW::Mechanize;

my $queue = RT::Queue->new(RT->SystemUser);
$queue->Load('General');

my ($base, $m) = RT::Extension::RichtextCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Ticket/Create.html?Queue=' . $queue->id, 'Create ticket form');
$m->content_lacks('CKEDITOR.replace', 'CKEDITOR is not here without CF Richtext');

my $cf_richtext = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_richtext->Create(Name => 'Taylor', Type => 'RichtextSingle', Queue => $queue->id);
ok($cf_id, "CF Richtext created");

$m->get_ok($m->rt_base_url . 'Ticket/Create.html?Queue=' . $queue->id, 'Create ticket form');
$m->content_contains('CKEDITOR.replace', 'CKEDITOR is here with CF Richtext');

$m->submit_form(
    form_name => "TicketCreate",
    fields    => {
        Subject => 'test_ticket',
        "Object-RT::Ticket--CustomField-$cf_id-Value" => '<strong>rich</strong>',
    },
    button => 'SubmitTicket',
);
$m->content_contains("Ticket created", 'Ticket created');
$m->content_contains("<strong>rich</strong>", 'CF Richtext displayed in HTML');
undef $m;
