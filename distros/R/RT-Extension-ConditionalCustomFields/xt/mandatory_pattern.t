use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 11;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Select', MaxValues => 1, Queue => 'General', RenderType => 'Dropdown');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(600);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');

$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', [$cf_values->[0]->Name, $cf_values->[2]->Name]);

$cf_conditioned_by->SetPattern('(?#Mandatory).');
my ($ok, $msg) = $ticket->DeleteCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
is($msg, 'Input must match [Mandatory]', 'ConditionedBy mandatory value cannot be deleted when condition is met');

$cf_conditioned_by->SetPattern(undef);
$ticket->DeleteCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
is($ticket->FirstCustomFieldValue($cf_conditioned_by->Name), undef, 'ConditionedBy not mandatory value can be deleted when condition is met');

$cf_conditioned_by->SetPattern('(?#Mandatory).');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
my ($tok, $tmsg) = $ticket->DeleteCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
is($ticket->FirstCustomFieldValue($cf_conditioned_by->Name), undef, 'ConditionedBy mandatory value can be deleted when condition is not met !'.$tmsg.'!');

$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition, $cf_values->[2]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
$mjs->click('SubmitTicket');
ok($mjs->content =~ /ConditionedBy: Input must match \[Mandatory\]/, 'Raise error for ConditionedBy mandatory CF when condition is met');

$ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
$mjs->click('SubmitTicket');
ok($mjs->content !~ /ConditionedBy: Input must match \[Mandatory\]/, 'Do not raise error for ConditionedBy mandatory CF when condition is not met');
