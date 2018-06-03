use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 14;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', LookupType => 'RT::Catalog-RT::Asset', Type => 'Select', MaxValues => 1);
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', LookupType => 'RT::Catalog-RT::Asset', Type => 'Freeform', MaxValues => 1);

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', LookupType => 'RT::Catalog-RT::Asset', Type => 'Freeform', MaxValues => 1, BasedOn => $cf_conditioned_by->id);

my $catalog = RT::Catalog->new(RT->SystemUser);
$catalog->Load('General assets');
my $asset = RT::Asset->new(RT->SystemUser);
$asset->Create(Catalog => $catalog->Name, Name => 'Test Asset ConditionalCF');
$cf_condition->AddToObject($catalog);
$cf_conditioned_by->AddToObject($catalog);
$cf_conditioned_by_child->AddToObject($catalog);
$asset->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$asset->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
$asset->AddCustomFieldValue(Field => $cf_conditioned_by_child->id , Value => 'See me too?');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');

$mjs->get($m->rt_base_url . 'Asset/Display.html?id=' . $asset->id);
my $asset_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by->is_displayed, 'Show ConditionalCF when no condition is set');
my $asset_cf_conditioned_by_child = $mjs->selector('#CF-'. $cf_conditioned_by_child->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by_child->is_displayed, 'Show Child when no condition is set');

$cf_conditioned_by->SetConditionedBy($cf_condition->id, [$cf_values->[0]->Name, $cf_values->[2]->Name]);
$mjs->get($m->rt_base_url . 'Asset/Display.html?id=' . $asset->id);
$asset_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by->is_displayed, 'Show ConditionalCF when first condition val is met');
$asset_cf_conditioned_by_child = $mjs->selector('#CF-'. $cf_conditioned_by_child->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by_child->is_displayed, 'Show Child when first condition val is met');

$asset->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);
$mjs->get($m->rt_base_url . 'Asset/Display.html?id=' . $asset->id);
$asset_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when condition is not met');
$asset_cf_conditioned_by_child = $mjs->selector('#CF-'. $cf_conditioned_by_child->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by_child->is_hidden, 'Hide Child when condition is not met');

$asset->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[2]->Name);
$mjs->get($m->rt_base_url . 'Asset/Display.html?id=' . $asset->id);
$asset_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by->is_displayed, 'Show ConditionalCF when second condition val is met');
$asset_cf_conditioned_by_child = $mjs->selector('#CF-'. $cf_conditioned_by_child->id . '-ShowRow', single => 1);
ok($asset_cf_conditioned_by_child->is_displayed, 'Show Child when second condition val is met');
