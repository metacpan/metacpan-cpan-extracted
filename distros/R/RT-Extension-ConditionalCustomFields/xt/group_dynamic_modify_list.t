use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 20;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', LookupType => 'RT::Group', Type => 'Select', MaxValues => 1, RenderType => 'List');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', LookupType => 'RT::Group', Type => 'Freeform', MaxValues => 1);

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', LookupType => 'RT::Group', Type => 'Freeform', MaxValues => 1, BasedOn => $cf_conditioned_by->id);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(540);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

my $group = RT::Group->new(RT->SystemUser);
$group->CreateUserDefinedGroup(Name => 'Test Group ConditionalCF');
$cf_condition->AddToObject($group);
$cf_conditioned_by->AddToObject($group);
$cf_conditioned_by_child->AddToObject($group);
$group->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$group->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
$group->AddCustomFieldValue(Field => $cf_conditioned_by_child->id , Value => 'See me too?');

$mjs->get($m->rt_base_url . 'Admin/Groups/Modify.html?id=' . $group->id);
my $group_cf_conditioned_by = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($group_cf_conditioned_by->is_displayed, "Show ConditionalCF when no condition is set");
my $group_cf_conditioned_by_child = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($group_cf_conditioned_by_child->is_displayed, "Show Child when no condition is set");

my $group_cf_condition_passed = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_condition->id . '-Value-' . $cf_values->[0]->id, single => 1);
$mjs->click($group_cf_condition_passed);
ok($group_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met but no condition is set");
ok($group_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met but no condition is set");

my $group_cf_condition_failed = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_condition->id . '-Value-' . $cf_values->[1]->id, single => 1);
$mjs->click($group_cf_condition_failed);
ok($group_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be not met but no condition is set");
ok($group_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be not met but no condition is set");

$cf_conditioned_by->SetConditionedBy($cf_condition->id, 'is', [$cf_values->[0]->Name, $cf_values->[2]->Name]);

$mjs->get($m->rt_base_url . 'Admin/Groups/Modify.html?id=' . $group->id);
$group_cf_conditioned_by = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($group_cf_conditioned_by->is_displayed, "Show ConditionalCF when condition is met by first val");
$group_cf_conditioned_by_child = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($group_cf_conditioned_by_child->is_displayed, "Show Child when condition is met by first val");

$group_cf_condition_failed = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_condition->id . '-Value-' . $cf_values->[1]->id, single => 1);
$mjs->click($group_cf_condition_failed);
ok($group_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Condition is changed to be not met");
ok($group_cf_conditioned_by_child->is_hidden, "Hide Child when Condition is changed to be not met");

$group->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);

$mjs->get($m->rt_base_url . 'Admin/Groups/Modify.html?id=' . $group->id);
$group_cf_conditioned_by = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($group_cf_conditioned_by->is_hidden, "Hide ConditionalCF when condition is not met");
$group_cf_conditioned_by_child = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($group_cf_conditioned_by_child->is_hidden, "Hide Child when condition is not met");

$group_cf_condition_passed = $mjs->by_id('Object-RT::Group-' . $group->id . '-CustomField-' . $cf_condition->id . '-Value-' . $cf_values->[2]->id, single => 1);
$mjs->click($group_cf_condition_passed);
ok($group_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met by second val");
ok($group_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met by second val");
