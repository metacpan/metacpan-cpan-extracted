use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 20;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', LookupType => 'RT::Class-RT::Article', Type => 'SelectSingle', RenderType => 'Select box');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', LookupType => 'RT::Class-RT::Article', Type => 'FreeformSingle');

my $cf_conditioned_by_child = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_child->Create(Name => 'Child', LookupType => 'RT::Class-RT::Article', Type => 'FreeformSingle', BasedOn => $cf_conditioned_by->id);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');

my $class = RT::Class->new(RT->SystemUser);
$class->Load('General');
my $article = RT::Article->new(RT->SystemUser);
$article->Create(Class => $class->Name, Name => 'Test Article ConditionalCF');
$cf_condition->AddToObject($class);
$cf_conditioned_by->AddToObject($class);
$cf_conditioned_by_child->AddToObject($class);
$article->AddCustomFieldValue(Field => $cf_condition->id , Value => 'Passed');
$article->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');
$article->AddCustomFieldValue(Field => $cf_conditioned_by_child->id , Value => 'See me too?');

$mjs->get($m->rt_base_url . 'Articles/Article/Edit.html?id=' . $article->id);
my $article_cf_conditioned_by = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($article_cf_conditioned_by->is_displayed, "Show ConditionalCF when no condition is set");
my $article_cf_conditioned_by_child = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($article_cf_conditioned_by_child->is_displayed, "Show Child when no condition is set");

my $article_cf_condition = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($article_cf_condition, $cf_values->[0]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Article-" . $article->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($article_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met but no condition is set");
ok($article_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met but no condition is set");

$mjs->field($article_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Article-" . $article->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($article_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be not met but no condition is set");
ok($article_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be not met but no condition is set");

$cf_conditioned_by->SetConditionedBy($cf_values->[0]->id);

$mjs->get($m->rt_base_url . 'Articles/Article/Edit.html?id=' . $article->id);
$article_cf_conditioned_by = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($article_cf_conditioned_by->is_displayed, "Show ConditionalCF when condition is met");
$article_cf_conditioned_by_child = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($article_cf_conditioned_by_child->is_displayed, "Show Child when condition is met");

$article_cf_condition = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($article_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Article-" . $article->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($article_cf_conditioned_by->is_hidden, "Hide ConditionalCF when Condition is changed to be not met");
ok($article_cf_conditioned_by_child->is_hidden, "Hide Child when Condition is changed to be not met");

$article->AddCustomFieldValue(Field => $cf_condition->id , Value => 'Failed');

$mjs->get($m->rt_base_url . 'Articles/Article/Edit.html?id=' . $article->id);
$article_cf_conditioned_by = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($article_cf_conditioned_by->is_hidden, "Hide ConditionalCF when condition is not met");
$article_cf_conditioned_by_child = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_conditioned_by_child->id . '-Value', single => 1);
ok($article_cf_conditioned_by_child->is_hidden, "Hide Child when condition is not met");

$article_cf_condition = $mjs->by_id('Object-RT::Article-' . $article->id . '-CustomField-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($article_cf_condition, $cf_values->[0]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Article-" . $article->id . "-CustomField-" . $cf_condition->id . "-Values').trigger('change');");
ok($article_cf_conditioned_by->is_displayed, "Show ConditionalCF when Condition is changed to be met");
ok($article_cf_conditioned_by_child->is_displayed, "Show Child when Condition is changed to be met");
