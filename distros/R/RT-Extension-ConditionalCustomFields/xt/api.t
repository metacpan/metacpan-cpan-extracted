use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 19;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'SelectSingle', Queue => 'General');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'FreeformSingle', Queue => 'General');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', Type => 'FreeformSingle', Queue => 'General', BasedOn => $cf_conditioned_by->id);

my ($rv, $msg) = $cf_conditioned_by->SetConditionedBy($cf_values->[0]->id);
ok($rv, "SetConditionedBy: $msg");

is(ref($cf_condition->ConditionedByObj), 'RT::CustomFieldValue', 'Not ConditionedByObj returns empty RT::CustomFieldValue');
is($cf_condition->ConditionedByObj->id, undef, 'Not ConditionedByObj');
is($cf_conditioned_by->ConditionedByObj->Name, 'Passed', 'ConditionedByObj');
is(ref($cf_conditioned_by_child->ConditionedByObj), 'RT::CustomFieldValue', 'Not recursive ConditionedByObj returns empty RT::CustomFieldValue');
is($cf_conditioned_by_child->ConditionedByObj->id, undef, 'Not recursive ConditionedByObj');

is($cf_condition->ConditionedByAsString, undef, 'Not ConditionedByAsString');
is($cf_conditioned_by->ConditionedByAsString, 'Passed', 'ConditionedByAsString');
is($cf_conditioned_by_child->ConditionedByAsString, undef, 'Not recursive ConditionedByAsString');

is($cf_condition->ConditionedByCustomField, undef, 'Not ConditionedByCustomField');
is($cf_conditioned_by->ConditionedByCustomField->Name, 'Condition', 'ConditionedByCustomField');
is($cf_conditioned_by_child->ConditionedByCustomField->Name, 'Condition', 'Recursive ConditionedByCustomField');

is(ref($cf_condition->ConditionedByCustomFieldValue), 'RT::CustomFieldValue', 'Not ConditionedByCustomFieldValue returns empty RT::CustomFieldValue');
is($cf_condition->ConditionedByCustomFieldValue->id, undef, 'Not ConditionedByCustomFieldValue');
is($cf_conditioned_by->ConditionedByCustomFieldValue->Name, 'Passed', 'ConditionedByCustomFieldValue');
is($cf_conditioned_by_child->ConditionedByCustomFieldValue->Name, 'Passed', 'Recursive ConditionedByCustomFieldValue');
