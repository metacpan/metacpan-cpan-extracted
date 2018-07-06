use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 14;

use WWW::Mechanize::PhantomJS;

my $cf_condition_one = RT::CustomField->new(RT->SystemUser);
$cf_condition_one->Create(Name => 'ConditionOne', Type => 'Select', MaxValues => 1, Queue => 'General', RenderType => 'Select box');
$cf_condition_one->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition_one->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition_one->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_condition_two = RT::CustomField->new(RT->SystemUser);
$cf_condition_two->Create(Name => 'ConditionTwo', Type => 'Select', MaxValues => 1, Queue => 'General', RenderType => 'Select box');
$cf_condition_two->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition_two->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition_two->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition_one->Values->ItemsArrayRef;

my $cf_conditioned_by_one = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_one->Create(Name => 'ConditionedByOne', Type => 'Freeform', MaxValues => 1, Queue => 'General');
my $cf_conditioned_by_two = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_two->Create(Name => 'ConditionedByTwo', Type => 'Freeform', MaxValues => 1, Queue => 'General');

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['ConditionOne', 'ConditionedByOne' ],
        'Group two' => ['ConditionTwo', 'ConditionedByTwo'],
    ],
);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_condition_one->id , Value => $cf_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_condition_two->id , Value => $cf_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_one->id , Value => 'See me?');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_two->id , Value => 'See me too?');

$cf_conditioned_by_one->SetConditionedBy($cf_condition_one->id, [$cf_values->[0]->Name, $cf_values->[2]->Name]);
$cf_conditioned_by_two->SetConditionedBy($cf_condition_two->id, [$cf_values->[0]->Name, $cf_values->[2]->Name]);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by_one = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_conditioned_by_one->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_one->is_displayed, "Show ConditionalCF One when Condition One is met by first val");
my $ticket_cf_conditioned_by_two = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_two->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by_two->is_displayed, "Show ConditionalCF Two when Condition Two is met by first val");

my $ticket_cf_condition_one = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition_one->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition_one, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition_one->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by_one->is_hidden, "Hide ConditionalCF One when Condition One is changed to be not met");
ok($ticket_cf_conditioned_by_two->is_displayed, "Show ConditionalCF Two when Condition One is changed to be not met");

my $ticket_cf_condition_two = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_condition_two->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition_two, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Grouptwo-" . $cf_condition_two->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by_one->is_hidden, "Hide ConditionalCF One when both Conditions One and Two are changed to be not met");
ok($ticket_cf_conditioned_by_two->is_hidden, "Hide ConditionalCF Two when both Conditions One and Two are changed to be not met");

$mjs->field($ticket_cf_condition_two, $cf_values->[2]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Grouptwo-" . $cf_condition_two->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by_one->is_hidden, "Hide ConditionalCF One when Condition Two is changed to be met by second value");
ok($ticket_cf_conditioned_by_two->is_displayed, "Show ConditionalCF Two when Condition Two is changed to be met by second value");
