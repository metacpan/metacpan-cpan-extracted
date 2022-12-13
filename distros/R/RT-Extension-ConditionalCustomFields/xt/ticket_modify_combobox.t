use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 11;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Combobox', MaxValues => 1, Queue => 'General');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

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

# Operator: is, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Combobox condition val with is operator is met');

# Update value to condition not met
my $ticket_cf_condition;
if (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value', single => 1);
} else {
    $ticket_cf_condition = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value"]', single => 1);
}

$mjs->field($ticket_cf_condition, $cf_values->[1]->Name);
sleep 1;
if (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Value').trigger('change');");
} else {
    $mjs->eval_in_page('jQuery(\'input[name="Object-RT\\\\:\\\\:Ticket-' . $ticket->id . '-CustomField\\\\:Groupone-' . $cf_condition->id . '-Value"]\').trigger(\'change\');');
}
sleep 1;
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Combobox condition val with is operator is updated to not met');

# Operator: is, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Combobox condition val with is operator is not met');

# Operator: isn't, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", $cf_values->[1]->Name);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Combobox condition val with isn't operator is met");

# Operator: isn't, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Combobox condition val with is operator isn't not met");
