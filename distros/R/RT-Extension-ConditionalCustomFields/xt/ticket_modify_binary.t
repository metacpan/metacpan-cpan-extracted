use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 27;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Binary', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);
RT->Config->PostLoadCheck;

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
ok($m->login, 'logged in');

$m->get_ok('/Ticket/Modify.html?id=' . $ticket->id);
my $binary_name = 'ee-rt.pdf';
my $binary_path = RT::Test::get_relocatable_file($binary_name, 'data');
$m->submit_form_ok({
    form_name => 'TicketModify',
    fields    => {
        'Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Upload' => $binary_path,
    },
});
$m->content_contains('ee-rt.pdf added');
$m->content_contains('/Download/CustomFieldValue/' .$cf_condition->id . '/ee-rt.pdf');

sleep 1;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(900);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Operator: matches, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'matches', 'rt');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Binary condition val with matches operator is met');

# Update value to condition not met
my $ticket_cf_condition = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Upload"]', single => 1);
my $ticket_cf_condition_name = $ticket_cf_condition->get_attribute('name');
$ticket_cf_condition_name =~ s/:/\\:/g;
my $sputnik_name = 'picture.png';
my $sputnik_path = RT::Test::get_relocatable_file($sputnik_name, 'data');
$ticket_cf_condition->send_keys($sputnik_path);
is($mjs->eval_in_page("document.getElementsByName(\"$ticket_cf_condition_name\")[0].files.length"), 1);
$mjs->eval_in_page("jQuery('input[name=\"$ticket_cf_condition_name\"]').trigger('change');");
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Binary condition val with matches operator is updated to not met');

# Operator: matches, condition not met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'matches', 'sputnik');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Binary condition val with matches operator is not met');

# Operator: doesn't match, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "doesn't match", 'sputnik');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Binary condition val with doesn't match operator is met");

# Operator: doesn't match, condition not met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "doesn't match", 'rt');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Binary condition val with doesn't match operator is not met");

# Operator: is, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', 'ee-rt.pdf');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Binary condition val with is operator is met');

# Operator: is, condition not met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', 'ee-rt.epub');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Binary condition val with is operator is not met');

# Operator: isn't, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", 'ee-rt.epub');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Binary condition val with isn't operator is met");

# Operator: isn't, condition not met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", 'ee-rt.pdf');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Binary condition val with isn't operator is not met");

# Operator: less than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', 'm');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Binary condition numerical val with less than operator is met');

# Operator: less than, condition not met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', 'd');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Binary condition numerical val with less than operator is not met');

# Operator: greater than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'greater than', 'e');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Binary condition numerical val with greater than operator is met');

# Operator: greater than, condition not met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'greater than', 'g');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Binary condition numerical val with greater than operator is not met');

# Operator: between, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'between', ['g', 'e']);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Binary condition alphabetical val with between operator is met');

# Operator: between, alphabetical condition not met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'between', ['m', 'j']);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Binary condition alphabetical val with between operator is not met');
