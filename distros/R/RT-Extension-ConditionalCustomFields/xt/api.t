use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 14;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Select', MaxValues => 1, Queue => 'General');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', Type => 'Freeform', MaxValues => 1, Queue => 'General', BasedOn => $cf_conditioned_by->id);

my ($rv, $msg) = $cf_conditioned_by->SetConditionedBy($cf_condition->id, [$cf_values->[0]->Name, $cf_values->[2]->Name]);
ok($rv, "SetConditionedBy: $msg");

my $cf_condition_conditioned_by = $cf_condition->ConditionedBy;
is($cf_condition_conditioned_by, undef, 'Not ConditionedBy returns undef');
my $cf_conditioned_by_conditioned_by = $cf_conditioned_by->ConditionedBy;
is($cf_conditioned_by_conditioned_by->{CF}, $cf_condition->id, 'ConditionedBy returns CF id');
is(scalar(@{$cf_conditioned_by_conditioned_by->{vals}}), 2, 'ConditionedBy returns two vals');
is($cf_conditioned_by_conditioned_by->{vals}->[0], $cf_values->[0]->Name, 'ConditionedBy returns first val');
is($cf_conditioned_by_conditioned_by->{vals}->[1], $cf_values->[2]->Name, 'ConditionedBy returns second val');
my $cf_conditioned_by_child_conditioned_by = $cf_conditioned_by_child->ConditionedBy;
is($cf_conditioned_by_child_conditioned_by->{CF}, $cf_condition->id, 'Recursive ConditionedBy returns CF id');
is(scalar(@{$cf_conditioned_by_child_conditioned_by->{vals}}), 2, 'Recursive ConditionedBy returns two vals');
is($cf_conditioned_by_child_conditioned_by->{vals}->[0], $cf_values->[0]->Name, 'Recursive ConditionedBy returns first val');
is($cf_conditioned_by_child_conditioned_by->{vals}->[1], $cf_values->[2]->Name, 'Recursive ConditionedBy returns second val');

($rv, $msg) = $cf_conditioned_by->SetConditionedBy(undef, undef);
is($msg, 'ConditionedBy deleted', 'Delete SetConditionedBy');
