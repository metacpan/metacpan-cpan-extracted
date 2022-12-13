use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 17;

use WWW::Mechanize::PhantomJS;

# Set user TZ to play with datetime
my $user = RT::Test->load_or_create_user(Name => 'root', Password => 'password');
$user->SetTimezone('Europe/Paris');

my $cf_condition = RT::CustomField->new($user);
$cf_condition->Create(Name => 'Condition', Type => 'DateTime', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by = RT::CustomField->new($user);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);
RT->Config->PostLoadCheck;

my $ticket = RT::Ticket->new($user);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(900);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Operator: is, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', '2021-06-21 00:42:00');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2021-06-21 00:42:00');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with is operator is met');

# Update value to condition not met
my $ticket_cf_condition;
if (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
} else {
    $ticket_cf_condition = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values"]', single => 1);
}
$mjs->field($ticket_cf_condition, '2019-06-21 06:06:06');
sleep 1;
if (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
} else {
    $mjs->eval_in_page('jQuery(\'input[name="Object-RT\\\\:\\\\:Ticket-' . $ticket->id . '-CustomField\\\\:Groupone-' . $cf_condition->id . '-Values"]\').trigger(\'change\');');
}
sleep 1;
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when Autocomplete condition val with is operator is updated to not met');

# Operator: is, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 06:06:06');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with is operator is not met');

# Operator: isn't, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, "isn't", '2021-06-21 00:42:00');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 06:06:06');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, "Show ConditionalCF when DateTime condition val with is operator isn't met");

# Operator: isn't, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2021-06-21 00:42:00');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, "Hide ConditionalCF when DateTime condition val with is operator isn't not met");

# Operator: less than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'less than', '2019-06-21 00:42:00');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 00:00:00');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with less than operator is met');

# Operator: less than, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 00:42:01');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with less than operator is not met');

# Operator: greater than, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'greater than', '2019-06-21 00:42:00');
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 00:42:01');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with greater than operator is met');

# Operator: greater than, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 00:41:59');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with greater than operator is not met');

# Operator: between, condition met
$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'between', ['2019-06-21 00:42:00', '2019-07-14 00:42:00']);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 00:42:01');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when DateTime condition val with between operator is met');

# Operator: between, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => '2019-06-21 00:41:59');
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
sleep 1;
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when DateTime condition val with between operator is not met');
