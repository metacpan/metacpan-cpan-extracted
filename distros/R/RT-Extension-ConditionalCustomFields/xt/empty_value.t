use strict;
use warnings;

package main;
use RT::Extension::ConditionalCustomFields::Test tests => 13;

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

my $fake_ticket = RT::Ticket->new(RT->SystemUser);
$fake_ticket->Create(Queue => 'General', Subject => 'Fake ticket to have ticket id not equal to queue id');
my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(600);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Display, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", '');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'Some value');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when displaying and not empty condition val is met');

# Display, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when displaying and not empty condition val is not met');

# Display, condition not met with value deleted
# RT::Record->DeleteCustomFieldValue warns if value is empty,
# so add some non-empty value before deleting it!
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'Delete me');
$ticket->DeleteCustomFieldValue(Field => $cf_condition->id , Value => 'Delete me');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when displaying and not empty condition val is not met by empty val');

# Modify, condition met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'Some value');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when modifying and not empty condition val is met');

# Update value to condition not met
my $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value', single => 1);
$mjs->field($ticket_cf_condition, '');
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Value').trigger('change');");
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when modifying and not empty condition val is updated to not met');

# Modify, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when modifying and not empty condition val is not met');

# Modify, condition not met with value deleted
# RT::Record->DeleteCustomFieldValue warns if value is empty,
# so add some non-empty value before deleting it!
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => 'Delete me');
$ticket->DeleteCustomFieldValue(Field => $cf_condition->id , Value => 'Delete me');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when modifying and not empty condition val is not met by empty val');
