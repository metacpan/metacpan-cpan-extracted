use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 20;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Select', MaxValues => 1, Queue => 'General', RenderType => 'List');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', Type => 'Freeform', MaxValues => 1, Queue => 'General', BasedOn => $cf_conditioned_by->id);

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_child->id , Value => 'See me too?');

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when no condition is set");
my $ticket_cf_conditioned_by_child = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when no condition is set");

my $ticket_cf_condition_passed = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value-' . $cf_values->[0]->id, single => 1);
$mjs->click($ticket_cf_condition_passed);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met but no condition is set");
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met but no condition is set");

my $ticket_cf_condition_failed = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value-' . $cf_values->[1]->id, single => 1);
$mjs->click($ticket_cf_condition_failed);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be not met but no condition is set");
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be not met but no condition is set");

$cf_conditioned_by->SetConditionedBy($cf_condition->id, [$cf_values->[0]->Name, $cf_values->[2]->Name]);

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when condition is met by first val");
$ticket_cf_conditioned_by_child = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when condition is met by first val");

$ticket_cf_condition_failed = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value-' . $cf_values->[1]->id, single => 1);
$mjs->click($ticket_cf_condition_failed);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Condition is changed to be not met");
ok($ticket_cf_conditioned_by_child->is_hidden, "Hide Child when Condition is changed to be not met");

$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when condition is not met");
$ticket_cf_conditioned_by_child = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_child->is_hidden, "Hide Child when condition is not met");

$ticket_cf_condition_passed = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Value-' . $cf_values->[2]->id, single => 1);
$mjs->click($ticket_cf_condition_passed);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met by second val");
ok($ticket_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met by second val");
