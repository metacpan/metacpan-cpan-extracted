use strict;
use warnings;

use RT::Extension::BooleanCustomField::Test tests => 26;

use Test::WWW::Mechanize;

my $queue = RT::Queue->new(RT->SystemUser);
$queue->Load('General');

my ($base, $m) = RT::Extension::BooleanCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Ticket/Create.html?Queue=' . $queue->id, 'Create ticket form without CF Boolean');
my $create_form = $m->form_name('TicketCreate');
ok($create_form, "Create form without CF Boolean");
my @inputs = $m->find_all_inputs(type => 'checkbox');
ok(!scalar(@inputs), 'No checkbox without CF Boolean');

my $cf_boolean = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_boolean->Create(Name => 'Active', Type => 'BooleanSingle', Queue => $queue->id);
ok($cf_id, "CF Boolean created");

$m->get_ok($m->rt_base_url . 'Ticket/Create.html?Queue=' . $queue->id, 'Create ticket form with checked CF Boolean');
$create_form = $m->form_name('TicketCreate');
ok($create_form, "Create form with checked CF Boolean");
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar(@inputs) == 1 && $inputs[0]->{name} eq "Object-RT::Ticket--CustomField-$cf_id-Value", 'Checkbox with checked CF Boolean');

is($inputs[0]->value, undef, 'Checkbox is unchecked with checked CF Boolean');
$m->tick("Object-RT::Ticket--CustomField-$cf_id-Value", '1');
is($inputs[0]->value, '1', 'Checkbox is checked with checked CF Boolean');

$m->submit_form(
    form_name => "TicketCreate",
    fields    => {
        Subject => 'test_ticket',
    },
    button => 'SubmitTicket',
);
$m->content_contains("Ticket created", 'Ticket created');
if (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $m->content_like(qr{<td class="label">Active:</td>\s*<td class="value">\s*&\#10004;\s*</td>}, 'Checked CF Boolean displayed in HTML');
} else {
    $m->content_like(qr{<div class="label col-\d+">\s*<span class="prev-icon-helper">Active:</span><span class="far fa-question-circle icon-helper" data-toggle="tooltip" data-placement="top" data-original-title="Check/Uncheck"></span>\s*</div>\s*<div class="value col-\d+\s*">\s*<span class="current-value">\s*&\#10004;\s*</span>\s*</div>}, 'Checked CF Boolean displayed in HTML');
}
$m->follow_link_ok({ id => 'page-basics' }, 'Ticket modify link');
my $modify_form = $m->form_name('TicketModify');
ok($modify_form, "Modify form with unchecked CF Boolean");
my $ticket_id = $modify_form->value('id');
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar @inputs == 1 && $inputs[0]->{name} eq "Object-RT::Ticket-$ticket_id-CustomField-$cf_id-Value", 'Checkbox with unckecked CF Boolean');
is($inputs[0]->value, '1', 'Checkbox is checked with unchecked CF Boolean');
$m->tick("Object-RT::Ticket-$ticket_id-CustomField-$cf_id-Value", '1', undef);
is($inputs[0]->value, undef, 'Checkbox is unchecked with unchecked CF Boolean');
$m->submit_form(
    form_name => "TicketModify",
);
$m->content_contains("1 is no longer a value for custom field Active", 'Ticket modified with unchecked CF Boolean');
$m->follow_link_ok({ id => 'page-display' }, 'Ticket display link');
if (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $m->content_like(qr{<td class="label">Active:</td>\s*<td class="value no-value">\s*\(no value\)\s*</td>}, 'Unchecked CF Boolean displayed in HTML');
} else {
    $m->content_like(qr{<div class="label col-\d+">\s*<span class="prev-icon-helper">Active:</span><span class="far fa-question-circle icon-helper" data-toggle="tooltip" data-placement="top" data-original-title="Check/Uncheck"></span>\s*</div>\s*<div class="value col-\d+\s* no-value">\s*<span class="current-value">\s*\(no value\)\s*</span>\s*</div>}, 'Unchecked CF Boolean displayed in HTML');
}

undef $m;
