use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 16;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Date', MaxValues => 1, Queue => 'General');

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
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', '2019-06-21');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Date condition val with is operator is met');

# Operator: is, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-03-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Date condition val with is operator is not met');

# Operator: isn't, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", '2019-06-21');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-03-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when Date condition val with isn't operator is met");

# Operator: isn't, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Date condition val with isn't operator is not met");

# Operator: less than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', '2019-06-22');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Date condition val with less than operator is met');

# Operator: less than, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2020-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Date condition val with less than operator is not met');

# Operator: greater than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'greater than', '2019-06-21');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2020-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Date condition val with greater than operator is met');

# Operator: greater than, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2018-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Date condition val with greater than operator is not met');

# Operator: between, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'between', ['2019-06-21', '2019-07-14']);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when Date condition val with between operator is met');

# Operator: between, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2020-06-21');
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Date condition val with between operator is not met');
