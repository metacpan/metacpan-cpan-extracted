use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 23;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Freeform', MaxValues => 1, Queue => 'General');

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
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(900);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Operator: matches, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'matches', 'more');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'More informations below');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Freeform condition val with matches operator is met');

# Update value to condition not met
my $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value', single => 1);
$mjs->field($ticket_cf_condition, 'No further informations needed');
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Value').trigger('change');");
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Freeform condition val with matches operator is updated to not met');

# Operator: matches, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'No further informations needed');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Freeform condition val with matches operator is not met');

# Operator: doesn't match, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "doesn't match", 'no issue');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'More information needed');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Freeform condition val with doesn't match operator is met");

# Operator: doesn't match, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'No issue');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Freeform condition val with doesn't match operator is not met");

# Operator: is, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', 'More informations below');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'More informations below');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Freeform condition val with is operator is met');

# Operator: is, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'more informations below');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Freeform condition val with is operator is not met');

# Operator: isn't, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", 'No issue');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'no issue');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Freeform condition val with isn't operator is met");

# Operator: isn't, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'No issue');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Freeform condition val with isn't operator is not met");

# Operator: less than, numerical condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', 216);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 71);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Freeform condition numerical val with less than operator is met');

# Operator: less than, numerical condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 666);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Freeform condition numerical val with less than operator is not met');

# Operator: less than, alphabetical condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', 'g');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'a tiny string');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Freeform condition alphabetical val with less than operator is met');

# Operator: less than, alphabetical condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'this is a large string');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Freeform condition alphabetical val with less than operator is not met');

# Operator: greater than, numerical condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'greater than', 216);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 666);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Freeform condition numerical val with greater than operator is met');

# Operator: greater than, numerical condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 71);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Freeform condition numerical val with greater than operator is not met');

# Operator: between, alphabetical condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'between', ['m', 'g']);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'i am between');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Freeform condition alphabetical val with between operator is met');

# Operator: between, alphabetical condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'outside');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Freeform condition alphabetical val with between operator is not met');
