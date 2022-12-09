use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 18;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'IPAddress', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(600);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Operator: is, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', '192.168.1.6');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.1.6');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when IPAddress condition val with is operator is met');

# Update value to condition not met
my $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value', single => 1);
$mjs->field($ticket_cf_condition, '192.168.1.66');
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Value').trigger('change');");
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Autocomplete condition val with is operator is updated to not met');

# Operator: is, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.1.66');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when IPAddress condition val with is operator is not met');

# Operator: is, condition met, IPv6
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', '2001:db8:0:200:0:0:0:7');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2001:db8:0:200:0:0:0:7');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when IPAddress condition val with is operator is met');

# Operator: isn't, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", '192.168.1.6');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.1.66');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when IPAddress condition val with isn't operator is met");

# Operator: isn't, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.1.6');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when IPAddress condition val with isn't operator is not met");

# Operator: less than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', '192.168.1.6');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '191.168.1.6');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when IPAddress condition val with less than operator is met');

# Operator: less than, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.2.6');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when IPAddress condition val with less than operator is not met');

# Operator: greater than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'greater than', '192.168.1.6');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.2.6');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when IPAddress condition val with greater than operator is met');

# Operator: greater than, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.166.1.6');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when IPAddress condition val with greater than operator is not met');

# Operator: between, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'between', ['192.168.1.6', '192.168.1.51']);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.1.42');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when IPAddress condition val with between operator is met');

# Operator: between, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '192.168.1.66');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when IPAddress condition val with between operator is not met');
