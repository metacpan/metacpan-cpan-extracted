use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 20;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', LookupType => 'RT::Catalog-RT::Asset', Type => 'SelectSingle', RenderType => 'Select box');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
$cf_condition->AddValue(Name => 'Schrödingerized', SortOrder => 2);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', LookupType => 'RT::Catalog-RT::Asset', Type => 'FreeformSingle');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', LookupType => 'RT::Catalog-RT::Asset', Type => 'FreeformSingle', BasedOn => $cf_conditioned_by->id);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');

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

$mjs->get($m->rt_base_url . 'Asset/Modify.html?id=' . $asset->id);
my $asset_cf_conditioned_by = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($asset_cf_conditioned_by->is_displayed, "Show ConditionalCF when no condition is set");
my $asset_cf_conditioned_by_child = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($asset_cf_conditioned_by_child->is_displayed, "Show Child when no condition is set");

my $asset_cf_condition = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($asset_cf_condition, $cf_values->[0]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Asset-" . $asset->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($asset_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met but no condition is set");
ok($asset_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met but no condition is set");

$mjs->field($asset_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Asset-" . $asset->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($asset_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be not met but no condition is set");
ok($asset_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be not met but no condition is set");

$cf_conditioned_by->SetConditionedBy($cf_condition->id, [$cf_values->[0]->Name, $cf_values->[2]->Name]);

$mjs->get($m->rt_base_url . 'Asset/Modify.html?id=' . $asset->id);
$asset_cf_conditioned_by = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($asset_cf_conditioned_by->is_displayed, "Show ConditionalCF when condition is met by first val");
$asset_cf_conditioned_by_child = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($asset_cf_conditioned_by_child->is_displayed, "Show Child when condition is met by first val");

$asset_cf_condition = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($asset_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Asset-" . $asset->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($asset_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Condition is changed to be not met");
ok($asset_cf_conditioned_by_child->is_hidden, "Hide Child when Condition is changed to be not met");

$asset->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);

$mjs->get($m->rt_base_url . 'Asset/Modify.html?id=' . $asset->id);
$asset_cf_conditioned_by = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($asset_cf_conditioned_by->is_hidden, "Hide ConditionalCF when condition is not met");
$asset_cf_conditioned_by_child = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($asset_cf_conditioned_by_child->is_hidden, "Hide Child when condition is not met");

$asset_cf_condition = $mjs->by_id('Object-RT::Asset-' . $asset->id . '-CustomField-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($asset_cf_condition, $cf_values->[2]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Asset-" . $asset->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($asset_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met by second val");
ok($asset_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met by second val");
