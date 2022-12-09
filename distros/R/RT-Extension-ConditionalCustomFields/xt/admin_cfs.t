use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 755;

use WWW::Mechanize::PhantomJS;

# Set user TZ to play with datetime
my $user = RT::Test->load_or_create_user(Name => 'root', Password => 'password');
$user->SetTimezone('Europe/Paris');

my $cf_condition_select_single = RT::CustomField->new($user);
$cf_condition_select_single->Create(Name => 'ConditionSelectSingle', Type => 'Select', MaxValues => 1, RenderType => 'Dropdown', Queue => 'General');
$cf_condition_select_single->AddValue(Name => 'Single Passed', SortOder => 0);
$cf_condition_select_single->AddValue(Name => 'Single Failed', SortOrder => 1);
$cf_condition_select_single->AddValue(Name => 'Single Schrödingerized', SortOrder => 2);
my $cf_values_select_single = $cf_condition_select_single->Values->ItemsArrayRef;

my $cf_condition_select_multiple = RT::CustomField->new($user);
$cf_condition_select_multiple->Create(Name => 'ConditionSelectMultiple', Type => 'Select', MaxValues => 0, RenderType => 'List', Queue => 'General');
$cf_condition_select_multiple->AddValue(Name => 'Multiple Passed', SortOder => 0);
$cf_condition_select_multiple->AddValue(Name => 'Multiple Failed', SortOrder => 1);
$cf_condition_select_multiple->AddValue(Name => 'Multiple Schrödingerized', SortOrder => 2);
my $cf_values_select_multiple = $cf_condition_select_multiple->Values->ItemsArrayRef;

my $cf_condition_freeform_single = RT::CustomField->new($user);
$cf_condition_freeform_single->Create(Name => 'ConditionFreeformSingle', Type => 'Freeform', MaxValues => 1, Queue => 'General');

my $cf_condition_freeform_multiple = RT::CustomField->new($user);
$cf_condition_freeform_multiple->Create(Name => 'ConditionFreeformMultiple', Type => 'Freeform', MaxValues => 0, Queue => 'General');

my $cf_condition_text_single = RT::CustomField->new($user);
$cf_condition_text_single->Create(Name => 'ConditionTextSingle', Type => 'Text', MaxValues => 1, Queue => 'General');

my $cf_condition_wikitext_single = RT::CustomField->new($user);
$cf_condition_wikitext_single->Create(Name => 'ConditionWikitextSingle', Type => 'Wikitext', MaxValues => 1, Queue => 'General');

my $cf_condition_image_single = RT::CustomField->new($user);
$cf_condition_image_single->Create(Name => 'ConditionImageSingle', Type => 'Image', MaxValues => 1, Queue => 'General');

my $cf_condition_image_multiple = RT::CustomField->new($user);
$cf_condition_image_multiple->Create(Name => 'ConditionImageMultiple', Type => 'Image', MaxValues => 0, Queue => 'General');

my $cf_condition_binary_single = RT::CustomField->new($user);
$cf_condition_binary_single->Create(Name => 'ConditionBinarySingle', Type => 'Binary', MaxValues => 1, Queue => 'General');

my $cf_condition_binary_multiple = RT::CustomField->new($user);
$cf_condition_binary_multiple->Create(Name => 'ConditionBinaryMultiple', Type => 'Binary', MaxValues => 0, Queue => 'General');

my $cf_condition_combobox_single = RT::CustomField->new($user);
$cf_condition_combobox_single->Create(Name => 'ConditionComboboxSingle', Type => 'Combobox', MaxValues => 1, Queue => 'General');
$cf_condition_combobox_single->AddValue(Name => 'Single Passed', SortOder => 0);
$cf_condition_combobox_single->AddValue(Name => 'Single Failed', SortOrder => 1);
$cf_condition_combobox_single->AddValue(Name => 'Single Schrödingerized', SortOrder => 2);
my $cf_values_combobox_single = $cf_condition_combobox_single->Values->ItemsArrayRef;

my $cf_condition_autocomplete_single = RT::CustomField->new($user);
$cf_condition_autocomplete_single->Create(Name => 'ConditionAutocompleteSingle', Type => 'Autocomplete', MaxValues => 1, Queue => 'General');
$cf_condition_autocomplete_single->AddValue(Name => 'Single Passed', SortOder => 0);
$cf_condition_autocomplete_single->AddValue(Name => 'Single Failed', SortOrder => 1);
$cf_condition_autocomplete_single->AddValue(Name => 'Single Schrödingerized', SortOrder => 2);
my $cf_values_autocomplete_single = $cf_condition_autocomplete_single->Values->ItemsArrayRef;

my $cf_condition_autocomplete_multiple = RT::CustomField->new($user);
$cf_condition_autocomplete_multiple->Create(Name => 'ConditionAutocompleteMultiple', Type => 'Autocomplete', MaxValues => 0, Queue => 'General');
$cf_condition_autocomplete_multiple->AddValue(Name => 'Multiple Passed', SortOder => 0);
$cf_condition_autocomplete_multiple->AddValue(Name => 'Multiple Failed', SortOrder => 1);
$cf_condition_autocomplete_multiple->AddValue(Name => 'Multiple Schrödingerized', SortOrder => 2);
my $cf_values_autocomplete_multiple = $cf_condition_autocomplete_multiple->Values->ItemsArrayRef;

my $cf_condition_date_single = RT::CustomField->new($user);
$cf_condition_date_single->Create(Name => 'ConditionDateSingle', Type => 'Date', MaxValues => 1, Queue => 'General');

my $cf_condition_datetime_single = RT::CustomField->new($user);
$cf_condition_datetime_single->Create(Name => 'ConditionDateTimeSingle', Type => 'DateTime', MaxValues => 1, Queue => 'General');

my $cf_condition_ipaddress_single = RT::CustomField->new($user);
$cf_condition_ipaddress_single->Create(Name => 'ConditionIPAddressSingle', Type => 'IPAddress', MaxValues => 1, Queue => 'General');

my $cf_condition_ipaddress_multiple = RT::CustomField->new($user);
$cf_condition_ipaddress_multiple->Create(Name => 'ConditionIPAddressMultiple', Type => 'IPAddress', MaxValues => 1, Queue => 'General');

my $cf_conditioned_by = RT::CustomField->new($user);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->follow_link_ok({ id => 'admin-custom-fields-create' }, 'CustomField create link');
$m->content_lacks('Customfield is conditioned by', 'No ConditionedBy on CF creation');

$m->get_ok($m->rt_base_url . 'Admin/CustomFields/Modify.html?id=' . $cf_conditioned_by->id, 'ConditionedBy CF modify form');
my $cf_conditioned_by_form = $m->form_name('ModifyCustomField');
my $cf_conditioned_by_CF = $cf_conditioned_by_form->find_input('ConditionalCF');
my @cf_conditioned_by_CF_options = $cf_conditioned_by_CF->possible_values;
is(scalar(@cf_conditioned_by_CF_options), 18, 'Can be conditioned by 18 CFs');
is($cf_conditioned_by_CF_options[0], '', 'Can be conditioned by nothing');
is($cf_conditioned_by_CF_options[1], $cf_condition_autocomplete_multiple->id, 'Can be conditioned by ConditionAutocompleteMultiple CF');
is($cf_conditioned_by_CF_options[2], $cf_condition_autocomplete_single->id, 'Can be conditioned by ConditionAutocompleteSingle CF');
is($cf_conditioned_by_CF_options[3], $cf_condition_binary_multiple->id, 'Can be conditioned by ConditionBinaryMultiple CF');
is($cf_conditioned_by_CF_options[4], $cf_condition_binary_single->id, 'Can be conditioned by ConditionBinarySingle CF');
is($cf_conditioned_by_CF_options[5], $cf_condition_combobox_single->id, 'Can be conditioned by ConditionComboboxSingle CF');
is($cf_conditioned_by_CF_options[6], $cf_condition_date_single->id, 'Can be conditioned by ConditionDateSingle CF');
is($cf_conditioned_by_CF_options[7], $cf_condition_datetime_single->id, 'Can be conditioned by ConditionDateTimeSingle CF');
is($cf_conditioned_by_CF_options[8], $cf_condition_freeform_multiple->id, 'Can be conditioned by ConditionFreeformMultiple CF');
is($cf_conditioned_by_CF_options[9], $cf_condition_freeform_single->id, 'Can be conditioned by ConditionFreeformSingle CF');
is($cf_conditioned_by_CF_options[10], $cf_condition_image_multiple->id, 'Can be conditioned by ConditionImageMultiple CF');
is($cf_conditioned_by_CF_options[11], $cf_condition_image_single->id, 'Can be conditioned by ConditionImageSingle CF');
is($cf_conditioned_by_CF_options[12], $cf_condition_ipaddress_multiple->id, 'Can be conditioned by ConditionIPAddressMultiple CF');
is($cf_conditioned_by_CF_options[13], $cf_condition_ipaddress_single->id, 'Can be conditioned by ConditionIPAddressSingle CF');
is($cf_conditioned_by_CF_options[14], $cf_condition_select_multiple->id, 'Can be conditioned by ConditionSelectMultiple CF');
is($cf_conditioned_by_CF_options[15], $cf_condition_select_single->id, 'Can be conditioned by ConditionSelectSingle CF');
is($cf_conditioned_by_CF_options[16], $cf_condition_text_single->id, 'Can be conditioned by ConditionTextSingle CF');
is($cf_conditioned_by_CF_options[17], $cf_condition_wikitext_single->id, 'Can be conditioned by ConditionWikitextSingle CF');

my $mjs = WWW::Mechanize::PhantomJS->new(phantomjs_arg => ["--ssl-protocol=any"]);
$mjs->driver->ua->timeout(600);
$mjs->get($m->rt_base_url . '?user=root;pass=password');
$mjs->get($m->rt_base_url . 'Admin/CustomFields/Modify.html?id=' . $cf_conditioned_by->id);
ok($mjs->content =~ /Customfield is conditioned by/, 'Can be conditioned by (with js)');

@cf_conditioned_by_CF_options = $mjs->xpath('//select[@name="ConditionalCF"]/option');
is(scalar(@cf_conditioned_by_CF_options), 18, 'Can be conditioned by 18 CFs (with js)');
is($cf_conditioned_by_CF_options[0]->get_value, '', 'Can be conditioned by nothing (with js)');
is($cf_conditioned_by_CF_options[1]->get_value, $cf_condition_autocomplete_multiple->id, 'Can be conditioned by ConditionAutocompleteMultiple CF (with js)');
is($cf_conditioned_by_CF_options[2]->get_value, $cf_condition_autocomplete_single->id, 'Can be conditioned by ConditionAutocompleteSingle CF (with js)');
is($cf_conditioned_by_CF_options[3]->get_value, $cf_condition_binary_multiple->id, 'Can be conditioned by ConditionBinaryMultiple CF (with js)');
is($cf_conditioned_by_CF_options[4]->get_value, $cf_condition_binary_single->id, 'Can be conditioned by ConditionBinarySingle CF (with js)');
is($cf_conditioned_by_CF_options[5]->get_value, $cf_condition_combobox_single->id, 'Can be conditioned by ConditionComboboxSingle CF (with js)');
is($cf_conditioned_by_CF_options[6]->get_value, $cf_condition_date_single->id, 'Can be conditioned by ConditionDateSingle CF (with js)');
is($cf_conditioned_by_CF_options[7]->get_value, $cf_condition_datetime_single->id, 'Can be conditioned by ConditionDateTimeSingle CF (with js)');
is($cf_conditioned_by_CF_options[8]->get_value, $cf_condition_freeform_multiple->id, 'Can be conditioned by ConditionFreeformMultiple CF (with js)');
is($cf_conditioned_by_CF_options[9]->get_value, $cf_condition_freeform_single->id, 'Can be conditioned by ConditionFreeformSingle CF (with js)');
is($cf_conditioned_by_CF_options[10]->get_value, $cf_condition_image_multiple->id, 'Can be conditioned by ConditionImageMultiple CF (with js)');
is($cf_conditioned_by_CF_options[11]->get_value, $cf_condition_image_single->id, 'Can be conditioned by ConditionImageSingle CF (with js)');
is($cf_conditioned_by_CF_options[12]->get_value, $cf_condition_ipaddress_multiple->id, 'Can be conditioned by ConditionIPAddressMultiple CF (with js)');
is($cf_conditioned_by_CF_options[13]->get_value, $cf_condition_ipaddress_single->id, 'Can be conditioned by ConditionIPAddressSingle CF (with js)');
is($cf_conditioned_by_CF_options[14]->get_value, $cf_condition_select_multiple->id, 'Can be conditioned by ConditionSelectMultiple CF (with js)');
is($cf_conditioned_by_CF_options[15]->get_value, $cf_condition_select_single->id, 'Can be conditioned by ConditionSelectSingle CF (with js)');
is($cf_conditioned_by_CF_options[16]->get_value, $cf_condition_text_single->id, 'Can be conditioned by ConditionTextSingle CF (with js)');
is($cf_conditioned_by_CF_options[17]->get_value, $cf_condition_wikitext_single->id, 'Can be conditioned by ConditionWikitextSingle CF (with js)');

# Conditioned by Select Single CF
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_select_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_select_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_select_single), 2, 'Can be conditioned with 2 operations by ConditionSelectSingle');
is($cf_conditioned_by_op_options_select_single[0]->get_value, "is", "Is operation for conditioned by ConditionSelectSingle");
is($cf_conditioned_by_op_options_select_single[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionSelectSingle");

my @cf_conditioned_by_CFV_options_select_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_CFV_options_select_single), 3, 'Three values available for conditioned by ConditionSelectSingle');
is($cf_conditioned_by_CFV_options_select_single[0]->get_value, $cf_values_select_single->[0]->Name, 'First value for conditioned by ConditionSelectSingle');
is($cf_conditioned_by_CFV_options_select_single[1]->get_value, $cf_values_select_single->[1]->Name, 'Second value for conditioned by ConditionSelectSingle');
is($cf_conditioned_by_CFV_options_select_single[2]->get_value, $cf_values_select_single->[2]->Name, 'Third value for conditioned by ConditionSelectSingle');

my $cf_conditioned_by_CFV_1 = $mjs->xpath('//input[@value="' . $cf_values_select_single->[0]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_1->click;
my $cf_conditioned_by_CFV_2 = $mjs->xpath('//input[@value="' . $cf_values_select_single->[2]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_2->click;
$mjs->click('Update');

my $conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_select_single->id, 'ConditionedBy ConditionSelectSingle CF');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionSelectSingle two vals');
is($conditioned_by->{vals}->[0], $cf_values_select_single->[0]->Name, 'ConditionedBy ConditionSelectSingle first val');
is($conditioned_by->{vals}->[1], $cf_values_select_single->[2]->Name, 'ConditionedBy ConditionSelectSingle second val');

# Conditioned by Select Multiple CF
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_select_multiple->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_select_multiple = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_select_multiple), 2, 'Can be conditioned with 2 operations by ConditionSelectMultiple');
is($cf_conditioned_by_op_options_select_multiple[0]->get_value, "is", "Is operation for conditioned by ConditionSelectMultiple");
is($cf_conditioned_by_op_options_select_multiple[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionSelectMultiple");

my @cf_conditioned_by_CFV_options_select_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_CFV_options_select_multiple), 3, 'Three values available for conditioned by ConditionSelectMultiple');
is($cf_conditioned_by_CFV_options_select_multiple[0]->get_value, $cf_values_select_multiple->[0]->Name, 'First value for conditioned by ConditionSelectMultiple');
is($cf_conditioned_by_CFV_options_select_multiple[1]->get_value, $cf_values_select_multiple->[1]->Name, 'Second value for conditioned by ConditionSelectMultiple');
is($cf_conditioned_by_CFV_options_select_multiple[2]->get_value, $cf_values_select_multiple->[2]->Name, 'Third value for conditioned by ConditionSelectMultiple');

$cf_conditioned_by_CFV_1 = $mjs->xpath('//input[@value="' . $cf_values_select_multiple->[0]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_1->click;
$cf_conditioned_by_CFV_2 = $mjs->xpath('//input[@value="' . $cf_values_select_multiple->[2]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_2->click;
$mjs->click('Update');

$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_select_multiple->id, 'ConditionedBy ConditionSelectMultiple CF');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionSelectMultiple two vals');
is($conditioned_by->{vals}->[0], $cf_values_select_multiple->[0]->Name, 'ConditionedBy ConditionSelectMultiple first val');
is($conditioned_by->{vals}->[1], $cf_values_select_multiple->[2]->Name, 'ConditionedBy ConditionSelectMultiple second val');

# Conditioned by Freeform Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_freeform_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_freeform_single), 7, 'Can be conditioned with 7 operations by ConditionFreeformSingle');
is($cf_conditioned_by_op_options_freeform_single[0]->get_value, "matches", "Matches operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[2]->get_value, "is", "Is operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[4]->get_value, "less than", "Less than operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionFreeformSingle");
is($cf_conditioned_by_op_options_freeform_single[6]->get_value, "between", "Between operation for conditioned by ConditionFreeformSingle");

my $cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_freeform_single->get_value, "matches", "Matches operation selected for conditioned by ConditionFreeformSingle");
my @cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by matches ConditionFreeformSingle");
$mjs->field($cf_conditioned_by_value_freeform_single[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionFreeformSingle CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformSingle one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionFreeformSingle val');

$cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_single, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by doesn't match ConditionFreeformSingle");
$mjs->field($cf_conditioned_by_value_freeform_single[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionFreeformSingle CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformSingle one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionFreeformSingle val');

$cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "is", "Is operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by is ConditionFreeformSingle");
$mjs->field($cf_conditioned_by_value_freeform_single[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionFreeformSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformSingle one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionFreeformSingle val');

$cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by isn't ConditionFreeformSingle");
$mjs->field($cf_conditioned_by_value_freeform_single[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionFreeformSingle CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformSingle one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionFreeformSingle val');

$cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_single, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "less than", "Less than operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by less than ConditionFreeformSingle");
$mjs->field($cf_conditioned_by_value_freeform_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionFreeformSingle CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionFreeformSingle val');

$cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 1, "One possible value for conditioned by greater than ConditionFreeformSingle");
$mjs->field($cf_conditioned_by_value_freeform_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionFreeformSingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionFreeformSingle val');

$cf_conditioned_by_op_freeform_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_single->get_value, "between", "Between operation selected for conditioned by ConditionFreeformSingle");
@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_single), 2, "Two possible values for conditioned by between ConditionFreeformSingle");
$mjs->field($cf_conditioned_by_value_freeform_single[0], "you");
$mjs->field($cf_conditioned_by_value_freeform_single[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionFreeformSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionFreeformSingle two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionFreeformSingle first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionFreeformSingle second val');

@cf_conditioned_by_value_freeform_single = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_freeform_single[0], "10");
$mjs->field($cf_conditioned_by_value_freeform_single[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_single->id, 'ConditionedBy ConditionFreeformSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionFreeformSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionFreeformSingle two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionFreeformSingle first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionFreeformSingle second val');

# Conditioned by Freeform Multiple
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_freeform_multiple->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_freeform_multiple), 7, 'Can be conditioned with 7 operations by ConditionFreeformMultiple');
is($cf_conditioned_by_op_options_freeform_multiple[0]->get_value, "matches", "Matches operation for conditioned by ConditionFreeformMultiple");
is($cf_conditioned_by_op_options_freeform_multiple[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionFreeformMultiple");
is($cf_conditioned_by_op_options_freeform_multiple[2]->get_value, "is", "Is operation for conditioned by ConditionFreeformMultiple");
is($cf_conditioned_by_op_options_freeform_multiple[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionFreeformMultiple");
is($cf_conditioned_by_op_options_freeform_multiple[4]->get_value, "less than", "Less than operation for conditioned by ConditionFreeformMultiple");
is($cf_conditioned_by_op_options_freeform_multiple[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionFreeformMultiple");
is($cf_conditioned_by_op_options_freeform_multiple[6]->get_value, "between", "Between operation for conditioned by ConditionFreeformMultiple");

my $cf_conditioned_by_op_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_freeform_multiple->get_value, "matches", "Matches operation selected for conditioned by ConditionFreeformMultiple");
my @cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_multiple), 1, "One possible value for conditioned by matches ConditionFreeformMultiple");
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionFreeformMultiple CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformMultiple one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionFreeformMultiple val');

$cf_conditioned_by_op_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_multiple, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_multiple->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionFreeformMultiple");
@cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_multiple), 1, "One possible value for conditioned by doesn't match ConditionFreeformMultiple");
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionFreeformMultiple CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformMultiple one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionFreeformMultiple val');

$cf_conditioned_by_op_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_multiple, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_multiple->get_value, "is", "Is operation selected for conditioned by ConditionFreeformMultiple");
@cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_multiple), 1, "One possible value for conditioned by is ConditionFreeformMultiple");
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionFreeformMultiple CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformMultiple one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionFreeformMultiple val');

$cf_conditioned_by_op_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_multiple, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_multiple->get_value, "isn't", "Isn't operation selected for conditioned by ConditionFreeformMultiple");
@cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_multiple), 1, "One possible value for conditioned by isn't ConditionFreeformMultiple");
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionFreeformMultiple CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformMultiple one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionFreeformMultiple val');

$cf_conditioned_by_op_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_multiple, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_multiple->get_value, "less than", "Less than operation selected for conditioned by ConditionFreeformMultiple");
@cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_multiple), 1, "One possible value for conditioned by less than ConditionFreeformMultiple");
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionFreeformMultiple CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformMultiple one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionFreeformMultiple val');

$cf_conditioned_by_op_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_multiple, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_multiple->get_value, "greater than", "Greater than operation selected for conditioned by ConditionFreeformMultiple");
@cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_multiple), 1, "One possible value for conditioned by greater than ConditionFreeformMultiple");
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionFreeformMultiple CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionFreeformMultiple one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionFreeformMultiple val');

$cf_conditioned_by_op_freeform_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_freeform_multiple, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_freeform_multiple->get_value, "between", "Between operation selected for conditioned by ConditionFreeformMultiple");
@cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_freeform_multiple), 2, "Two possible values for conditioned by between ConditionFreeformMultiple");
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "you");
$mjs->field($cf_conditioned_by_value_freeform_multiple[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionFreeformMultiple CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionFreeformMultiple two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionFreeformMultiple first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionFreeformMultiple second val');

@cf_conditioned_by_value_freeform_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_freeform_multiple[0], "10");
$mjs->field($cf_conditioned_by_value_freeform_multiple[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_freeform_multiple->id, 'ConditionedBy ConditionFreeformMultiple CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionFreeformMultiple CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionFreeformMultiple two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionFreeformMultiple first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionFreeformMultiple second val');

# Conditioned by Text Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_text_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_text_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_text_single), 7, 'Can be conditioned with 7 operations by ConditionTextSingle');
is($cf_conditioned_by_op_options_text_single[0]->get_value, "matches", "Matches operation for conditioned by ConditionTextSingle");
is($cf_conditioned_by_op_options_text_single[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionTextSingle");
is($cf_conditioned_by_op_options_text_single[2]->get_value, "is", "Is operation for conditioned by ConditionTextSingle");
is($cf_conditioned_by_op_options_text_single[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionTextSingle");
is($cf_conditioned_by_op_options_text_single[4]->get_value, "less than", "Less than operation for conditioned by ConditionTextSingle");
is($cf_conditioned_by_op_options_text_single[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionTextSingle");
is($cf_conditioned_by_op_options_text_single[6]->get_value, "between", "Between operation for conditioned by ConditionTextSingle");

my $cf_conditioned_by_op_text_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_text_single->get_value, "matches", "Matches operation selected for conditioned by ConditionTextSingle");
my @cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_text_single), 1, "One possible value for conditioned by matches ConditionTextSingle");
$mjs->field($cf_conditioned_by_value_text_single[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionTextSingle CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionTextSingle one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionTextSingle val');

$cf_conditioned_by_op_text_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_text_single, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_text_single->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionTextSingle");
@cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_text_single), 1, "One possible value for conditioned by doesn't match ConditionTextSingle");
$mjs->field($cf_conditioned_by_value_text_single[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionTextSingle CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionTextSingle one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionTextSingle val');

$cf_conditioned_by_op_text_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_text_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_text_single->get_value, "is", "Is operation selected for conditioned by ConditionTextSingle");
@cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_text_single), 1, "One possible value for conditioned by is ConditionTextSingle");
$mjs->field($cf_conditioned_by_value_text_single[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionTextSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionTextSingle one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionTextSingle val');

$cf_conditioned_by_op_text_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_text_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_text_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionTextSingle");
@cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_text_single), 1, "One possible value for conditioned by isn't ConditionTextSingle");
$mjs->field($cf_conditioned_by_value_text_single[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionTextSingle CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionTextSingle one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionTextSingle val');

$cf_conditioned_by_op_text_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_text_single, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_text_single->get_value, "less than", "Less than operation selected for conditioned by ConditionTextSingle");
@cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_text_single), 1, "One possible value for conditioned by less than ConditionTextSingle");
$mjs->field($cf_conditioned_by_value_text_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionTextSingle CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionTextSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionTextSingle val');

$cf_conditioned_by_op_text_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_text_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_text_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionTextSingle");
@cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_text_single), 1, "One possible value for conditioned by greater than ConditionTextSingle");
$mjs->field($cf_conditioned_by_value_text_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionTextSingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionTextSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionTextSingle val');

$cf_conditioned_by_op_text_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_text_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_text_single->get_value, "between", "Between operation selected for conditioned by ConditionTextSingle");
@cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_text_single), 2, "Two possible values for conditioned by between ConditionTextSingle");
$mjs->field($cf_conditioned_by_value_text_single[0], "you");
$mjs->field($cf_conditioned_by_value_text_single[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionTextSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionTextSingle two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionTextSingle first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionTextSingle second val');

@cf_conditioned_by_value_text_single = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_text_single[0], "10");
$mjs->field($cf_conditioned_by_value_text_single[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_text_single->id, 'ConditionedBy ConditionTextSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionTextSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionTextSingle two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionTextSingle first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionTextSingle second val');

# Conditioned by Wikitext Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_wikitext_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_wikitext_single), 7, 'Can be conditioned with 7 operations by ConditionWikitextSingle');
is($cf_conditioned_by_op_options_wikitext_single[0]->get_value, "matches", "Matches operation for conditioned by ConditionWikitextSingle");
is($cf_conditioned_by_op_options_wikitext_single[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionWikitextSingle");
is($cf_conditioned_by_op_options_wikitext_single[2]->get_value, "is", "Is operation for conditioned by ConditionWikitextSingle");
is($cf_conditioned_by_op_options_wikitext_single[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionWikitextSingle");
is($cf_conditioned_by_op_options_wikitext_single[4]->get_value, "less than", "Less than operation for conditioned by ConditionWikitextSingle");
is($cf_conditioned_by_op_options_wikitext_single[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionWikitextSingle");
is($cf_conditioned_by_op_options_wikitext_single[6]->get_value, "between", "Between operation for conditioned by ConditionWikitextSingle");

my $cf_conditioned_by_op_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_wikitext_single->get_value, "matches", "Matches operation selected for conditioned by ConditionWikitextSingle");
my @cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_wikitext_single), 1, "One possible value for conditioned by matches ConditionWikitextSingle");
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionWikitextSingle CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionWikitextSingle one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionWikitextSingle val');

$cf_conditioned_by_op_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_wikitext_single, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_wikitext_single->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionWikitextSingle");
@cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_wikitext_single), 1, "One possible value for conditioned by doesn't match ConditionWikitextSingle");
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionWikitextSingle CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionWikitextSingle one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionWikitextSingle val');

$cf_conditioned_by_op_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_wikitext_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_wikitext_single->get_value, "is", "Is operation selected for conditioned by ConditionWikitextSingle");
@cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_wikitext_single), 1, "One possible value for conditioned by is ConditionWikitextSingle");
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionWikitextSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionWikitextSingle one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionWikitextSingle val');

$cf_conditioned_by_op_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_wikitext_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_wikitext_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionWikitextSingle");
@cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_wikitext_single), 1, "One possible value for conditioned by isn't ConditionWikitextSingle");
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionWikitextSingle CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionWikitextSingle one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionWikitextSingle val');

$cf_conditioned_by_op_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_wikitext_single, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_wikitext_single->get_value, "less than", "Less than operation selected for conditioned by ConditionWikitextSingle");
@cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_wikitext_single), 1, "One possible value for conditioned by less than ConditionWikitextSingle");
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionWikitextSingle CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionWikitextSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionWikitextSingle val');

$cf_conditioned_by_op_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_wikitext_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_wikitext_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionWikitextSingle");
@cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_wikitext_single), 1, "One possible value for conditioned by greater than ConditionWikitextSingle");
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionWikitextSingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionWikitextSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionWikitextSingle val');

$cf_conditioned_by_op_wikitext_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_wikitext_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_wikitext_single->get_value, "between", "Between operation selected for conditioned by ConditionWikitextSingle");
@cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_wikitext_single), 2, "Two possible values for conditioned by between ConditionWikitextSingle");
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "you");
$mjs->field($cf_conditioned_by_value_wikitext_single[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionWikitextSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionWikitextSingle two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionWikitextSingle first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionWikitextSingle second val');

@cf_conditioned_by_value_wikitext_single = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_wikitext_single[0], "10");
$mjs->field($cf_conditioned_by_value_wikitext_single[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_wikitext_single->id, 'ConditionedBy ConditionWikitextSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionWikitextSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionWikitextSingle two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionWikitextSingle first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionWikitextSingle second val');

# Conditioned by Image Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_image_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_image_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_image_single), 7, 'Can be conditioned with 7 operations by ConditionImageSingle');
is($cf_conditioned_by_op_options_image_single[0]->get_value, "matches", "Matches operation for conditioned by ConditionImageSingle");
is($cf_conditioned_by_op_options_image_single[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionImageSingle");
is($cf_conditioned_by_op_options_image_single[2]->get_value, "is", "Is operation for conditioned by ConditionImageSingle");
is($cf_conditioned_by_op_options_image_single[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionImageSingle");
is($cf_conditioned_by_op_options_image_single[4]->get_value, "less than", "Less than operation for conditioned by ConditionImageSingle");
is($cf_conditioned_by_op_options_image_single[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionImageSingle");
is($cf_conditioned_by_op_options_image_single[6]->get_value, "between", "Between operation for conditioned by ConditionImageSingle");

my $cf_conditioned_by_op_image_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_image_single->get_value, "matches", "Matches operation selected for conditioned by ConditionImageSingle");
my @cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_single), 1, "One possible value for conditioned by matches ConditionImageSingle");
$mjs->field($cf_conditioned_by_value_image_single[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionImageSingle CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageSingle one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionImageSingle val');

$cf_conditioned_by_op_image_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_single, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_single->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionImageSingle");
@cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_single), 1, "One possible value for conditioned by doesn't match ConditionImageSingle");
$mjs->field($cf_conditioned_by_value_image_single[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionImageSingle CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageSingle one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionImageSingle val');

$cf_conditioned_by_op_image_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_single->get_value, "is", "Is operation selected for conditioned by ConditionImageSingle");
@cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_single), 1, "One possible value for conditioned by is ConditionImageSingle");
$mjs->field($cf_conditioned_by_value_image_single[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionImageSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageSingle one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionImageSingle val');

$cf_conditioned_by_op_image_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionImageSingle");
@cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_single), 1, "One possible value for conditioned by isn't ConditionImageSingle");
$mjs->field($cf_conditioned_by_value_image_single[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionImageSingle CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageSingle one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionImageSingle val');

$cf_conditioned_by_op_image_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_single, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_single->get_value, "less than", "Less than operation selected for conditioned by ConditionImageSingle");
@cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_single), 1, "One possible value for conditioned by less than ConditionImageSingle");
$mjs->field($cf_conditioned_by_value_image_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionImageSingle CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionImageSingle val');

$cf_conditioned_by_op_image_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionImageSingle");
@cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_single), 1, "One possible value for conditioned by greater than ConditionImageSingle");
$mjs->field($cf_conditioned_by_value_image_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionImageSingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageSingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionImageSingle val');

$cf_conditioned_by_op_image_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_single->get_value, "between", "Between operation selected for conditioned by ConditionImageSingle");
@cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_single), 2, "Two possible values for conditioned by between ConditionImageSingle");
$mjs->field($cf_conditioned_by_value_image_single[0], "you");
$mjs->field($cf_conditioned_by_value_image_single[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionImageSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionImageSingle two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionImageSingle first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionImageSingle second val');

@cf_conditioned_by_value_image_single = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_image_single[0], "10");
$mjs->field($cf_conditioned_by_value_image_single[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_single->id, 'ConditionedBy ConditionImageSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionImageSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionImageSingle two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionImageSingle first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionImageSingle second val');

# Conditioned by Image Multiple
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_image_multiple->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_image_multiple), 7, 'Can be conditioned with 7 operations by ConditionImageMultiple');
is($cf_conditioned_by_op_options_image_multiple[0]->get_value, "matches", "Matches operation for conditioned by ConditionImageMultiple");
is($cf_conditioned_by_op_options_image_multiple[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionImageMultiple");
is($cf_conditioned_by_op_options_image_multiple[2]->get_value, "is", "Is operation for conditioned by ConditionImageMultiple");
is($cf_conditioned_by_op_options_image_multiple[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionImageMultiple");
is($cf_conditioned_by_op_options_image_multiple[4]->get_value, "less than", "Less than operation for conditioned by ConditionImageMultiple");
is($cf_conditioned_by_op_options_image_multiple[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionImageMultiple");
is($cf_conditioned_by_op_options_image_multiple[6]->get_value, "between", "Between operation for conditioned by ConditionImageMultiple");

my $cf_conditioned_by_op_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_image_multiple->get_value, "matches", "Matches operation selected for conditioned by ConditionImageMultiple");
my @cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_multiple), 1, "One possible value for conditioned by matches ConditionImageMultiple");
$mjs->field($cf_conditioned_by_value_image_multiple[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionImageMultiple CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageMultiple one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionImageMultiple val');

$cf_conditioned_by_op_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_multiple, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_multiple->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionImageMultiple");
@cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_multiple), 1, "One possible value for conditioned by doesn't match ConditionImageMultiple");
$mjs->field($cf_conditioned_by_value_image_multiple[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionImageMultiple CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageMultiple one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionImageMultiple val');

$cf_conditioned_by_op_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_multiple, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_multiple->get_value, "is", "Is operation selected for conditioned by ConditionImageMultiple");
@cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_multiple), 1, "One possible value for conditioned by is ConditionImageMultiple");
$mjs->field($cf_conditioned_by_value_image_multiple[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionImageMultiple CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageMultiple one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionImageMultiple val');

$cf_conditioned_by_op_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_multiple, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_multiple->get_value, "isn't", "Isn't operation selected for conditioned by ConditionImageMultiple");
@cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_multiple), 1, "One possible value for conditioned by isn't ConditionImageMultiple");
$mjs->field($cf_conditioned_by_value_image_multiple[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionImageMultiple CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageMultiple one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionImageMultiple val');

$cf_conditioned_by_op_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_multiple, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_multiple->get_value, "less than", "Less than operation selected for conditioned by ConditionImageMultiple");
@cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_multiple), 1, "One possible value for conditioned by less than ConditionImageMultiple");
$mjs->field($cf_conditioned_by_value_image_multiple[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionImageMultiple CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageMultiple one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionImageMultiple val');

$cf_conditioned_by_op_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_multiple, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_multiple->get_value, "greater than", "Greater than operation selected for conditioned by ConditionImageMultiple");
@cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_multiple), 1, "One possible value for conditioned by greater than ConditionImageMultiple");
$mjs->field($cf_conditioned_by_value_image_multiple[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionImageMultiple CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionImageMultiple one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionImageMultiple val');

$cf_conditioned_by_op_image_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_image_multiple, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_image_multiple->get_value, "between", "Between operation selected for conditioned by ConditionImageMultiple");
@cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_image_multiple), 2, "Two possible values for conditioned by between ConditionImageMultiple");
$mjs->field($cf_conditioned_by_value_image_multiple[0], "you");
$mjs->field($cf_conditioned_by_value_image_multiple[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionImageMultiple CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionImageMultiple two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionImageMultiple first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionImageMultiple second val');

@cf_conditioned_by_value_image_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_image_multiple[0], "10");
$mjs->field($cf_conditioned_by_value_image_multiple[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_image_multiple->id, 'ConditionedBy ConditionImageMultiple CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionImageMultiple CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionImageMultiple two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionImageMultiple first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionImageMultiple second val');

# Conditioned by Binary Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_binary_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_binary_single), 7, 'Can be conditioned with 7 operations by ConditionBinarySingle');
is($cf_conditioned_by_op_options_binary_single[0]->get_value, "matches", "Matches operation for conditioned by ConditionBinarySingle");
is($cf_conditioned_by_op_options_binary_single[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionBinarySingle");
is($cf_conditioned_by_op_options_binary_single[2]->get_value, "is", "Is operation for conditioned by ConditionBinarySingle");
is($cf_conditioned_by_op_options_binary_single[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionBinarySingle");
is($cf_conditioned_by_op_options_binary_single[4]->get_value, "less than", "Less than operation for conditioned by ConditionBinarySingle");
is($cf_conditioned_by_op_options_binary_single[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionBinarySingle");
is($cf_conditioned_by_op_options_binary_single[6]->get_value, "between", "Between operation for conditioned by ConditionBinarySingle");

my $cf_conditioned_by_op_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_binary_single->get_value, "matches", "Matches operation selected for conditioned by ConditionBinarySingle");
my @cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_single), 1, "One possible value for conditioned by matches ConditionBinarySingle");
$mjs->field($cf_conditioned_by_value_binary_single[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionBinarySingle CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinarySingle one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionBinarySingle val');

$cf_conditioned_by_op_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_single, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_single->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionBinarySingle");
@cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_single), 1, "One possible value for conditioned by doesn't match ConditionBinarySingle");
$mjs->field($cf_conditioned_by_value_binary_single[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionBinarySingle CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinarySingle one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionBinarySingle val');

$cf_conditioned_by_op_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_single->get_value, "is", "Is operation selected for conditioned by ConditionBinarySingle");
@cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_single), 1, "One possible value for conditioned by is ConditionBinarySingle");
$mjs->field($cf_conditioned_by_value_binary_single[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionBinarySingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinarySingle one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionBinarySingle val');

$cf_conditioned_by_op_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionBinarySingle");
@cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_single), 1, "One possible value for conditioned by isn't ConditionBinarySingle");
$mjs->field($cf_conditioned_by_value_binary_single[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionBinarySingle CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinarySingle one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionBinarySingle val');

$cf_conditioned_by_op_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_single, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_single->get_value, "less than", "Less than operation selected for conditioned by ConditionBinarySingle");
@cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_single), 1, "One possible value for conditioned by less than ConditionBinarySingle");
$mjs->field($cf_conditioned_by_value_binary_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionBinarySingle CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinarySingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionBinarySingle val');

$cf_conditioned_by_op_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionBinarySingle");
@cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_single), 1, "One possible value for conditioned by greater than ConditionBinarySingle");
$mjs->field($cf_conditioned_by_value_binary_single[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionBinarySingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinarySingle one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionBinarySingle val');

$cf_conditioned_by_op_binary_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_single->get_value, "between", "Between operation selected for conditioned by ConditionBinarySingle");
@cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_single), 2, "Two possible values for conditioned by between ConditionBinarySingle");
$mjs->field($cf_conditioned_by_value_binary_single[0], "you");
$mjs->field($cf_conditioned_by_value_binary_single[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionBinarySingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionBinarySingle two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionBinarySingle first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionBinarySingle second val');

@cf_conditioned_by_value_binary_single = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_binary_single[0], "10");
$mjs->field($cf_conditioned_by_value_binary_single[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_single->id, 'ConditionedBy ConditionBinarySingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionBinarySingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionBinarySingle two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionBinarySingle first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionBinarySingle second val');

# Conditioned by Binary Multiple
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_binary_multiple->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_binary_multiple), 7, 'Can be conditioned with 7 operations by ConditionBinaryMultiple');
is($cf_conditioned_by_op_options_binary_multiple[0]->get_value, "matches", "Matches operation for conditioned by ConditionBinaryMultiple");
is($cf_conditioned_by_op_options_binary_multiple[1]->get_value, "doesn't match", "Doesn't match operation for conditioned by ConditionBinaryMultiple");
is($cf_conditioned_by_op_options_binary_multiple[2]->get_value, "is", "Is operation for conditioned by ConditionBinaryMultiple");
is($cf_conditioned_by_op_options_binary_multiple[3]->get_value, "isn't", "Isn't operation for conditioned by ConditionBinaryMultiple");
is($cf_conditioned_by_op_options_binary_multiple[4]->get_value, "less than", "Less than operation for conditioned by ConditionBinaryMultiple");
is($cf_conditioned_by_op_options_binary_multiple[5]->get_value, "greater than", "Greater than operation for conditioned by ConditionBinaryMultiple");
is($cf_conditioned_by_op_options_binary_multiple[6]->get_value, "between", "Between operation for conditioned by ConditionBinaryMultiple");

my $cf_conditioned_by_op_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_binary_multiple->get_value, "matches", "Matches operation selected for conditioned by ConditionBinaryMultiple");
my @cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_multiple), 1, "One possible value for conditioned by matches ConditionBinaryMultiple");
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "more");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, "matches", "ConditionedBy ConditionBinaryMultiple CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinaryMultiple one val');
is($conditioned_by->{vals}->[0], 'more', 'ConditionedBy ConditionBinaryMultiple val');

$cf_conditioned_by_op_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_multiple, "doesn't match");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_multiple->get_value, "doesn't match", "Doesn't match operation selected for conditioned by ConditionBinaryMultiple");
@cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_multiple), 1, "One possible value for conditioned by doesn't match ConditionBinaryMultiple");
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "no issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, "doesn't match", "ConditionedBy ConditionBinaryMultiple CF and doesn't match operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinaryMultiple one val');
is($conditioned_by->{vals}->[0], 'no issue', 'ConditionedBy ConditionBinaryMultiple val');

$cf_conditioned_by_op_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_multiple, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_multiple->get_value, "is", "Is operation selected for conditioned by ConditionBinaryMultiple");
@cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_multiple), 1, "One possible value for conditioned by is ConditionBinaryMultiple");
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "More info");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionBinaryMultiple CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinaryMultiple one val');
is($conditioned_by->{vals}->[0], 'More info', 'ConditionedBy ConditionBinaryMultiple val');

$cf_conditioned_by_op_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_multiple, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_multiple->get_value, "isn't", "Isn't operation selected for conditioned by ConditionBinaryMultiple");
@cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_multiple), 1, "One possible value for conditioned by isn't ConditionBinaryMultiple");
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "No issue");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionBinaryMultiple CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinaryMultiple one val');
is($conditioned_by->{vals}->[0], 'No issue', 'ConditionedBy ConditionBinaryMultiple val');

$cf_conditioned_by_op_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_multiple, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_multiple->get_value, "less than", "Less than operation selected for conditioned by ConditionBinaryMultiple");
@cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_multiple), 1, "One possible value for conditioned by less than ConditionBinaryMultiple");
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionBinaryMultiple CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinaryMultiple one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionBinaryMultiple val');

$cf_conditioned_by_op_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_multiple, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_multiple->get_value, "greater than", "Greater than operation selected for conditioned by ConditionBinaryMultiple");
@cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_multiple), 1, "One possible value for conditioned by greater than ConditionBinaryMultiple");
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "216");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionBinaryMultiple CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionBinaryMultiple one val');
is($conditioned_by->{vals}->[0], '216', 'ConditionedBy ConditionBinaryMultiple val');

$cf_conditioned_by_op_binary_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_binary_multiple, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_binary_multiple->get_value, "between", "Between operation selected for conditioned by ConditionBinaryMultiple");
@cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_binary_multiple), 2, "Two possible values for conditioned by between ConditionBinaryMultiple");
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "you");
$mjs->field($cf_conditioned_by_value_binary_multiple[1], "me");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionBinaryMultiple CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionBinaryMultiple two vals');
is($conditioned_by->{vals}->[0], 'me', 'ConditionedBy ConditionBinaryMultiple first val');
is($conditioned_by->{vals}->[1], 'you', 'ConditionedBy ConditionBinaryMultiple second val');

@cf_conditioned_by_value_binary_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
$mjs->field($cf_conditioned_by_value_binary_multiple[0], "10");
$mjs->field($cf_conditioned_by_value_binary_multiple[1], "1");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_binary_multiple->id, 'ConditionedBy ConditionBinaryMultiple CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionBinaryMultiple CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionBinaryMultiple two vals');
is($conditioned_by->{vals}->[0], '1', 'ConditionedBy ConditionBinaryMultiple first val');
is($conditioned_by->{vals}->[1], '10', 'ConditionedBy ConditionBinaryMultiple second val');

# Conditioned by Combobox Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_combobox_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_combobox_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_combobox_single), 2, 'Can be conditioned with 2 operations by ConditionComboboxSingle');
is($cf_conditioned_by_op_options_combobox_single[0]->get_value, "is", "Is operation for conditioned by ConditionComboboxSingle");
is($cf_conditioned_by_op_options_combobox_single[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionComboboxSingle");

my @cf_conditioned_by_CFV_options_combobox_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_CFV_options_combobox_single), 3, 'Three values available for conditioned by ConditionComboboxSingle');
is($cf_conditioned_by_CFV_options_combobox_single[0]->get_value, $cf_values_combobox_single->[0]->Name, 'First value for conditioned by ConditionComboboxSingle');
is($cf_conditioned_by_CFV_options_combobox_single[1]->get_value, $cf_values_combobox_single->[1]->Name, 'Second value for conditioned by ConditionComboboxSingle');
is($cf_conditioned_by_CFV_options_combobox_single[2]->get_value, $cf_values_combobox_single->[2]->Name, 'Third value for conditioned by ConditionComboboxSingle');

$cf_conditioned_by_CFV_1 = $mjs->xpath('//input[@value="' . $cf_values_combobox_single->[0]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_1->click;
$cf_conditioned_by_CFV_2 = $mjs->xpath('//input[@value="' . $cf_values_combobox_single->[2]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_2->click;
$mjs->click('Update');

$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_combobox_single->id, 'ConditionedBy ConditionComboboxSingle CF');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionComboboxSingle two vals');
is($conditioned_by->{vals}->[0], $cf_values_combobox_single->[0]->Name, 'ConditionedBy ConditionComboboxSingle first val');
is($conditioned_by->{vals}->[1], $cf_values_combobox_single->[2]->Name, 'ConditionedBy ConditionComboboxSingle second val');

# Conditioned by Autocomplete Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_autocomplete_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_autocomplete_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_autocomplete_single), 2, 'Can be conditioned with 2 operations by ConditionAutocompleteSingle');
is($cf_conditioned_by_op_options_autocomplete_single[0]->get_value, "is", "Is operation for conditioned by ConditionAutocompleteSingle");
is($cf_conditioned_by_op_options_autocomplete_single[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionAutocompleteSingle");

my @cf_conditioned_by_CFV_options_autocomplete_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_CFV_options_autocomplete_single), 3, 'Three values available for conditioned by ConditionAutocompleteSingle');
is($cf_conditioned_by_CFV_options_autocomplete_single[0]->get_value, $cf_values_autocomplete_single->[0]->Name, 'First value for conditioned by ConditionAutocompleteSingle');
is($cf_conditioned_by_CFV_options_autocomplete_single[1]->get_value, $cf_values_autocomplete_single->[1]->Name, 'Second value for conditioned by ConditionAutocompleteSingle');
is($cf_conditioned_by_CFV_options_autocomplete_single[2]->get_value, $cf_values_autocomplete_single->[2]->Name, 'Third value for conditioned by ConditionAutocompleteSingle');

$cf_conditioned_by_CFV_1 = $mjs->xpath('//input[@value="' . $cf_values_autocomplete_single->[0]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_1->click;
$cf_conditioned_by_CFV_2 = $mjs->xpath('//input[@value="' . $cf_values_autocomplete_single->[2]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_2->click;
$mjs->click('Update');

$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_autocomplete_single->id, 'ConditionedBy ConditionAutocompleteSingle CF');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionAutocompleteSingle two vals');
is($conditioned_by->{vals}->[0], $cf_values_autocomplete_single->[0]->Name, 'ConditionedBy ConditionAutocompleteSingle first val');
is($conditioned_by->{vals}->[1], $cf_values_autocomplete_single->[2]->Name, 'ConditionedBy ConditionAutocompleteSingle second val');

# Conditioned by Autocomplete Multiple
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_autocomplete_multiple->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_autocomplete_multiple = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_autocomplete_multiple), 2, 'Can be conditioned with 2 operations by ConditionAutocompleteMultiple');
is($cf_conditioned_by_op_options_autocomplete_multiple[0]->get_value, "is", "Is operation for conditioned by ConditionAutocompleteMultiple");
is($cf_conditioned_by_op_options_autocomplete_multiple[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionAutocompleteMultiple");

my @cf_conditioned_by_CFV_options_autocomplete_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_CFV_options_autocomplete_multiple), 3, 'Three values available for conditioned by ConditionAutocompleteMultiple');
is($cf_conditioned_by_CFV_options_autocomplete_multiple[0]->get_value, $cf_values_autocomplete_multiple->[0]->Name, 'First value for conditioned by ConditionAutocompleteMultiple');
is($cf_conditioned_by_CFV_options_autocomplete_multiple[1]->get_value, $cf_values_autocomplete_multiple->[1]->Name, 'Second value for conditioned by ConditionAutocompleteMultiple');
is($cf_conditioned_by_CFV_options_autocomplete_multiple[2]->get_value, $cf_values_autocomplete_multiple->[2]->Name, 'Third value for conditioned by ConditionAutocompleteMultiple');

$cf_conditioned_by_CFV_1 = $mjs->xpath('//input[@value="' . $cf_values_autocomplete_multiple->[0]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_1->click;
$cf_conditioned_by_CFV_2 = $mjs->xpath('//input[@value="' . $cf_values_autocomplete_multiple->[2]->Name . '"]', single => 1);
$cf_conditioned_by_CFV_2->click;
$mjs->click('Update');

$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_autocomplete_multiple->id, 'ConditionedBy ConditionAutocompleteMultiple CF');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionAutocompleteMultiple two vals');
is($conditioned_by->{vals}->[0], $cf_values_autocomplete_multiple->[0]->Name, 'ConditionedBy ConditionAutocompleteMultiple first val');
is($conditioned_by->{vals}->[1], $cf_values_autocomplete_multiple->[2]->Name, 'ConditionedBy ConditionAutocompleteMultiple second val');

# Conditioned by Date Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_date_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_date_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_date_single), 5, 'Can be conditioned with 5 operations by ConditionDateSingle');
is($cf_conditioned_by_op_options_date_single[0]->get_value, "less than", "Less than operation for conditioned by ConditionDateSingle");
is($cf_conditioned_by_op_options_date_single[1]->get_value, "is", "Is operation for conditioned by ConditionDateSingle");
is($cf_conditioned_by_op_options_date_single[2]->get_value, "isn't", "Isn't than operation for conditioned by ConditionDateSingle");
is($cf_conditioned_by_op_options_date_single[3]->get_value, "greater than", "Greater than operation for conditioned by ConditionDateSingle");
is($cf_conditioned_by_op_options_date_single[4]->get_value, "between", "Between operation for conditioned by ConditionDateSingle");

my $cf_conditioned_by_op_date_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_date_single->get_value, "less than", "Less than operation selected for conditioned by ConditionDateSingle");
my @cf_conditioned_by_value_date_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_date_single), 1, "One possible value for conditioned by less than ConditionDateSingle");
my $calendar = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar->is_hidden, 'Hide Calendar before clicking on date field');
$mjs->click($cf_conditioned_by_value_date_single[0]);
ok($calendar->is_displayed, 'Show Calendar after clicking on date field');
my $calendar_year = $mjs->xpath('//select[@class="ui-datepicker-year"]', single => 1);
$mjs->field($calendar_year, '2021');
$mjs->eval_in_page("jQuery('.ui-datepicker-year').trigger('change');");
my $calendar_month = $mjs->xpath('//select[@class="ui-datepicker-month"]', single => 1);
$mjs->field($calendar_month, '5');
$mjs->eval_in_page("jQuery('.ui-datepicker-month').trigger('change');");
my @calendar_days = $mjs->xpath('//td[@data-month="5"]');
is(scalar(@calendar_days), 30, 'Calendar has 30 days in June');
$mjs->click($calendar_days[20]);
my $calendar_done = $mjs->xpath('//button[@data-handler="hide"]', single => 1);
$mjs->click($calendar_done);
is($cf_conditioned_by_value_date_single[0]->get_value, "2021-06-21", "Value set with datepicker for less than ConditionalDateSingle");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_date_single->id, 'ConditionedBy ConditionDateSingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionDateSingle CF and matches operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateSingle one val');
is($conditioned_by->{vals}->[0], '2021-06-21', 'ConditionedBy ConditionDateSingle val');

$cf_conditioned_by_op_date_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_date_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_date_single->get_value, "is", "Is operation selected for conditioned by ConditionDateSingle");
@cf_conditioned_by_value_date_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_date_single), 1, "One possible value for conditioned by is ConditionDateSingle");
$calendar = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar->is_hidden, 'Hide Calendar before clicking on date field');
$mjs->click($cf_conditioned_by_value_date_single[0]);
ok($calendar->is_displayed, 'Show Calendar after clicking on date field');
$calendar_year = $mjs->xpath('//select[@class="ui-datepicker-year"]', single => 1);
$mjs->field($calendar_year, '2021');
$mjs->eval_in_page("jQuery('.ui-datepicker-year').trigger('change');");
$calendar_month = $mjs->xpath('//select[@class="ui-datepicker-month"]', single => 1);
$mjs->field($calendar_month, '2');
$mjs->eval_in_page("jQuery('.ui-datepicker-month').trigger('change');");
@calendar_days = $mjs->xpath('//td[@data-month="2"]');
is(scalar(@calendar_days), 31, 'Calendar has 31 days in March');
$mjs->click($calendar_days[20]);
$calendar_done = $mjs->xpath('//button[@data-handler="hide"]', single => 1);
$mjs->click($calendar_done);
is($cf_conditioned_by_value_date_single[0]->get_value, "2021-03-21", "Value set with datepicker for is ConditionalDateSingle");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_date_single->id, 'ConditionedBy ConditionDateSingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionDateSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateSingle one val');
is($conditioned_by->{vals}->[0], '2021-03-21', 'ConditionedBy ConditionDateSingle val');

$cf_conditioned_by_op_date_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_date_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_date_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionDateSingle");
@cf_conditioned_by_value_date_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_date_single), 1, "One possible value for conditioned by isn't ConditionDateSingle");
$calendar = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar->is_hidden, 'Hide Calendar before clicking on date field');
$mjs->click($cf_conditioned_by_value_date_single[0]);
ok($calendar->is_displayed, 'Show Calendar after clicking on date field');
$calendar_year = $mjs->xpath('//select[@class="ui-datepicker-year"]', single => 1);
$mjs->field($calendar_year, '2021');
$mjs->eval_in_page("jQuery('.ui-datepicker-year').trigger('change');");
$calendar_month = $mjs->xpath('//select[@class="ui-datepicker-month"]', single => 1);
$mjs->field($calendar_month, '2');
$mjs->eval_in_page("jQuery('.ui-datepicker-month').trigger('change');");
@calendar_days = $mjs->xpath('//td[@data-month="2"]');
is(scalar(@calendar_days), 31, 'Calendar has 31 days in March');
$mjs->click($calendar_days[20]);
$calendar_done = $mjs->xpath('//button[@data-handler="hide"]', single => 1);
$mjs->click($calendar_done);
is($cf_conditioned_by_value_date_single[0]->get_value, "2021-03-21", "Value set with datepicker for isn't ConditionalDateSingle");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_date_single->id, 'ConditionedBy ConditionDateSingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionDateSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateSingle one val');
is($conditioned_by->{vals}->[0], '2021-03-21', 'ConditionedBy ConditionDateSingle val');

$cf_conditioned_by_op_date_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_date_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_date_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionDateSingle");
@cf_conditioned_by_value_date_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_date_single), 1, "One possible value for conditioned by greater than ConditionDateSingle");
is($cf_conditioned_by_value_date_single[0]->get_value, "2021-03-21", "Value set with datepicker for greater than ConditionalDateSingle");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_date_single->id, 'ConditionedBy ConditionDateSingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionDateSingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateSingle one val');
is($conditioned_by->{vals}->[0], '2021-03-21', 'ConditionedBy ConditionDateSingle val');

$cf_conditioned_by_op_date_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_date_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_date_single->get_value, "between", "Between operation selected for conditioned by ConditionDateSingle");
@cf_conditioned_by_value_date_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_date_single), 2, "Two possible values for conditioned by between ConditionDateSingle");
$calendar = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar->is_hidden, 'Hide Calendar before clicking on second date field');
$mjs->click($cf_conditioned_by_value_date_single[1]);
ok($calendar->is_displayed, 'Show Calendar after clicking on second date field');
$calendar_year = $mjs->xpath('//select[@class="ui-datepicker-year"]', single => 1);
$mjs->field($calendar_year, '2021');
$mjs->eval_in_page("jQuery('.ui-datepicker-year').trigger('change');");
$calendar_month = $mjs->xpath('//select[@class="ui-datepicker-month"]', single => 1);
$mjs->field($calendar_month, '2');
$mjs->eval_in_page("jQuery('.ui-datepicker-month').trigger('change');");
@calendar_days = $mjs->xpath('//td[@data-month="2"]');
is(scalar(@calendar_days), 31, 'Calendar has 31 days in March');
$mjs->click($calendar_days[20]);
$calendar_done = $mjs->xpath('//button[@data-handler="hide"]', single => 1);
$mjs->click($calendar_done);
is($cf_conditioned_by_value_date_single[1]->get_value, "2021-03-21", "Second value set with datepicker for between ConditionalDateSingle");
$calendar = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
$mjs->click($cf_conditioned_by_value_date_single[0]);
$calendar_year = $mjs->xpath('//select[@class="ui-datepicker-year"]', single => 1);
$mjs->field($calendar_year, '2021');
$mjs->eval_in_page("jQuery('.ui-datepicker-year').trigger('change');");
$calendar_month = $mjs->xpath('//select[@class="ui-datepicker-month"]', single => 1);
$mjs->field($calendar_month, '5');
$mjs->eval_in_page("jQuery('.ui-datepicker-month').trigger('change');");
@calendar_days = $mjs->xpath('//td[@data-month="5"]');
is(scalar(@calendar_days), 30, 'Calendar has 30 days in June');
$mjs->click($calendar_days[20]);
$calendar_done = $mjs->xpath('//button[@data-handler="hide"]', single => 1);
$mjs->click($calendar_done);
is($cf_conditioned_by_value_date_single[0]->get_value, "2021-06-21", "First value set with datepicker for between ConditionalDateSingle");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_date_single->id, 'ConditionedBy ConditionDateSingle CF');
is($conditioned_by->{op}, "between", "ConditionedBy ConditionDateSingle CF and between operation");
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionDateSingle two vals');
is($conditioned_by->{vals}->[0], '2021-03-21', 'ConditionedBy ConditionDateSingle first val');
is($conditioned_by->{vals}->[1], '2021-06-21', 'ConditionedBy ConditionDateSingle second val');

# Conditioned by DateTime Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_datetime_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_datetime_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_datetime_single), 5, 'Can be conditioned with 5 operations by ConditionDateTimeSingle');
is($cf_conditioned_by_op_options_datetime_single[0]->get_value, "less than", "Less than operation for conditioned by ConditionDateTimeSingle");
is($cf_conditioned_by_op_options_datetime_single[1]->get_value, "is", "Is operation for conditioned by ConditionDateTimeSingle");
is($cf_conditioned_by_op_options_datetime_single[2]->get_value, "isn't", "Isn't operation for conditioned by ConditionDateTimeSingle");
is($cf_conditioned_by_op_options_datetime_single[3]->get_value, "greater than", "Greater than operation for conditioned by ConditionDateTimeSingle");
is($cf_conditioned_by_op_options_datetime_single[4]->get_value, "between", "Between operation for conditioned by ConditionDateTimeSingle");

my $cf_conditioned_by_op_datetime_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_datetime_single->get_value, "less than", "Less than operation selected for conditioned by ConditionDateTimeSingle");
my @cf_conditioned_by_value_datetime_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_datetime_single), 1, "One possible value for conditioned by less than ConditionDateTimeSingle");
$mjs->field($cf_conditioned_by_value_datetime_single[0], "2021-06-21 00:42:00");
my $calendar_time = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar_time->is_hidden, 'Hide Calendar/Time before clicking on date field');
$mjs->click($cf_conditioned_by_value_datetime_single[0]);
ok($calendar_time->is_displayed, 'Show Calendar/Time after clicking on date field');
my $calendar_time_year = $mjs->xpath('//select[@class="ui-datepicker-year"]/option[@value="2021"]', single => 1);
ok($calendar_time_year->is_selected, 'Chosen year in calendar');
my $calendar_time_month = $mjs->xpath('//select[@class="ui-datepicker-month"]/option[@value="5"]', single => 1);
ok($calendar_time_month->is_selected, 'Chosen month in calendar');
my $calendar_time_day = $mjs->xpath('//td[contains(@class, "ui-datepicker-current-day")]/a', single => 1);
is($calendar_time_day->get_text, '21', 'Chosen day in calendar');
my $calendar_time_time = $mjs->xpath('//dd[@class="ui_tpicker_time"]', single => 1);
is($calendar_time_time->get_text, '00:42:00', 'Chosen time in calendar');
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_datetime_single->id, 'ConditionedBy ConditionDateTimeSingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionDateTimeSingle CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateTimeSingle one val');
is($conditioned_by->{vals}->[0], '2021-06-21 00:42:00', 'ConditionedBy ConditionDateTimeSingle val');

$cf_conditioned_by_op_datetime_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_datetime_single, "is");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_datetime_single->get_value, "is", "Is operation selected for conditioned by ConditionDateTimeSingle");
@cf_conditioned_by_value_datetime_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_datetime_single), 1, "One possible value for conditioned by is ConditionDateTimeSingle");
$mjs->field($cf_conditioned_by_value_datetime_single[0], "2021-03-21 00:42:00");
$calendar_time = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar_time->is_hidden, 'Hide Calendar/Time before clicking on date field');
$mjs->click($cf_conditioned_by_value_datetime_single[0]);
ok($calendar_time->is_displayed, 'Show Calendar/Time after clicking on date field');
$calendar_time_year = $mjs->xpath('//select[@class="ui-datepicker-year"]/option[@value="2021"]', single => 1);
ok($calendar_time_year->is_selected, 'Chosen year in calendar');
$calendar_time_month = $mjs->xpath('//select[@class="ui-datepicker-month"]/option[@value="2"]', single => 1);
ok($calendar_time_month->is_selected, 'Chosen month in calendar');
$calendar_time_day = $mjs->xpath('//td[contains(@class, "ui-datepicker-current-day")]/a', single => 1);
is($calendar_time_day->get_text, '21', 'Chosen day in calendar');
$calendar_time_time = $mjs->xpath('//dd[@class="ui_tpicker_time"]', single => 1);
is($calendar_time_time->get_text, '00:42:00', 'Chosen time in calendar');
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_datetime_single->id, 'ConditionedBy ConditionDateTimeSingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionDateTimeSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateTimeSingle one val');
is($conditioned_by->{vals}->[0], '2021-03-21 00:42:00', 'ConditionedBy ConditionDateTimeSingle val');

$cf_conditioned_by_op_datetime_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_datetime_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_datetime_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionDateTimeSingle");
@cf_conditioned_by_value_datetime_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_datetime_single), 1, "One possible value for conditioned by isn't ConditionDateTimeSingle");
$mjs->field($cf_conditioned_by_value_datetime_single[0], "2021-03-21 00:42:00");
$calendar_time = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar_time->is_hidden, 'Hide Calendar/Time before clicking on date field');
$mjs->click($cf_conditioned_by_value_datetime_single[0]);
ok($calendar_time->is_displayed, 'Show Calendar/Time after clicking on date field');
$calendar_time_year = $mjs->xpath('//select[@class="ui-datepicker-year"]/option[@value="2021"]', single => 1);
ok($calendar_time_year->is_selected, 'Chosen year in calendar');
$calendar_time_month = $mjs->xpath('//select[@class="ui-datepicker-month"]/option[@value="2"]', single => 1);
ok($calendar_time_month->is_selected, 'Chosen month in calendar');
$calendar_time_day = $mjs->xpath('//td[contains(@class, "ui-datepicker-current-day")]/a', single => 1);
is($calendar_time_day->get_text, '21', 'Chosen day in calendar');
$calendar_time_time = $mjs->xpath('//dd[@class="ui_tpicker_time"]', single => 1);
is($calendar_time_time->get_text, '00:42:00', 'Chosen time in calendar');
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_datetime_single->id, 'ConditionedBy ConditionDateTimeSingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionDateTimeSingle CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateTimeSingle one val');
is($conditioned_by->{vals}->[0], '2021-03-21 00:42:00', 'ConditionedBy ConditionDateTimeSingle val');

$cf_conditioned_by_op_datetime_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_datetime_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_datetime_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionDateTimeSingle");
@cf_conditioned_by_value_datetime_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_datetime_single), 1, "One possible value for conditioned by greater than ConditionDateTimeSingle");
$mjs->field($cf_conditioned_by_value_datetime_single[0], "2021-03-21 00:42:00");
$calendar_time = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar_time->is_hidden, 'Hide Calendar/Time before clicking on date field');
$mjs->click($cf_conditioned_by_value_datetime_single[0]);
ok($calendar_time->is_displayed, 'Show Calendar/Time after clicking on date field');
$calendar_time_year = $mjs->xpath('//select[@class="ui-datepicker-year"]/option[@value="2021"]', single => 1);
ok($calendar_time_year->is_selected, 'Chosen year in calendar');
$calendar_time_month = $mjs->xpath('//select[@class="ui-datepicker-month"]/option[@value="2"]', single => 1);
ok($calendar_time_month->is_selected, 'Chosen month in calendar');
$calendar_time_day = $mjs->xpath('//td[contains(@class, "ui-datepicker-current-day")]/a', single => 1);
is($calendar_time_day->get_text, '21', 'Chosen day in calendar');
$calendar_time_time = $mjs->xpath('//dd[@class="ui_tpicker_time"]', single => 1);
is($calendar_time_time->get_text, '00:42:00', 'Chosen time in calendar');
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_datetime_single->id, 'ConditionedBy ConditionDateTimeSingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionDateTimeSingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionDateTimeSingle one val');
is($conditioned_by->{vals}->[0], '2021-03-21 00:42:00', 'ConditionedBy ConditionDateTimeSingle val');

$cf_conditioned_by_op_datetime_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_datetime_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_datetime_single->get_value, "between", "Between operation selected for conditioned by ConditionDateTimeSingle");
@cf_conditioned_by_value_datetime_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_datetime_single), 2, "Two possible values for conditioned by between ConditionDateTimeSingle");
$mjs->field($cf_conditioned_by_value_datetime_single[1], "2021-03-21 00:42:00");
$calendar_time = $mjs->xpath('//div[@id="ui-datepicker-div"]', single => 1);
ok($calendar_time->is_hidden, 'Hide first Calendar/Time before clicking on second date field');
$mjs->click($cf_conditioned_by_value_datetime_single[1]);
ok($calendar_time->is_displayed, 'Show first Calendar/Time after clicking on second date field');
$calendar_time_year = $mjs->xpath('//select[@class="ui-datepicker-year"]/option[@value="2021"]', single => 1);
ok($calendar_time_year->is_selected, 'Chosen year in calendar');
$calendar_time_month = $mjs->xpath('//select[@class="ui-datepicker-month"]/option[@value="2"]', single => 1);
ok($calendar_time_month->is_selected, 'Chosen month in calendar');
$calendar_time_day = $mjs->xpath('//td[contains(@class, "ui-datepicker-current-day")]/a', single => 1);
is($calendar_time_day->get_text, '21', 'Chosen day in calendar');
$calendar_time_time = $mjs->xpath('//dd[@class="ui_tpicker_time"]', single => 1);
is($calendar_time_time->get_text, '00:42:00', 'Chosen time in calendar');
$mjs->field($cf_conditioned_by_value_datetime_single[0], "2021-06-21 00:42:00");
$mjs->click($cf_conditioned_by_value_datetime_single[0]);
$calendar_time_year = $mjs->xpath('//select[@class="ui-datepicker-year"]/option[@value="2021"]', single => 1);
ok($calendar_time_year->is_selected, 'Chosen year in calendar');
$calendar_time_month = $mjs->xpath('//select[@class="ui-datepicker-month"]/option[@value="5"]', single => 1);
ok($calendar_time_month->is_selected, 'Chosen month in calendar');
$calendar_time_day = $mjs->xpath('//td[contains(@class, "ui-datepicker-current-day")]/a', single => 1);
is($calendar_time_day->get_text, '21', 'Chosen day in calendar');
$calendar_time_time = $mjs->xpath('//dd[@class="ui_tpicker_time"]', single => 1);
is($calendar_time_time->get_text, '00:42:00', 'Chosen time in calendar');
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_datetime_single->id, 'ConditionedBy ConditionDateTimeSingle CF');
is($conditioned_by->{op}, "between", "ConditionedBy ConditionDateTimeSingle CF and between operation");
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionDateTimeSingle two vals');
is($conditioned_by->{vals}->[0], '2021-03-21 00:42:00', 'ConditionedBy ConditionDateTimeSingle first val');
is($conditioned_by->{vals}->[1], '2021-06-21 00:42:00', 'ConditionedBy ConditionDateTimeSingle second val');

# Conditioned by IPAddress Single
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_ipaddress_single->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_ipaddress_single = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_ipaddress_single), 5, 'Can be conditioned with 5 operations by ConditionIPAddressSingle');
is($cf_conditioned_by_op_options_ipaddress_single[0]->get_value, "is", "Is operation for conditioned by ConditionIPAddressSingle");
is($cf_conditioned_by_op_options_ipaddress_single[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionIPAddressSingle");
is($cf_conditioned_by_op_options_ipaddress_single[2]->get_value, "less than", "Less than operation for conditioned by ConditionIPAddressSingle");
is($cf_conditioned_by_op_options_ipaddress_single[3]->get_value, "greater than", "Greater than operation for conditioned by ConditionIPAddressSingle");
is($cf_conditioned_by_op_options_ipaddress_single[4]->get_value, "between", "Between operation for conditioned by ConditionIPAddressSingle");

my $cf_conditioned_by_op_ipaddress_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_ipaddress_single->get_value, "is", "Is operation selected for conditioned by ConditionIPAddressSingle");
my @cf_conditioned_by_value_ipaddress_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_single), 1, "One possible value for conditioned by is ConditionIPAddressSingle");
$mjs->field($cf_conditioned_by_value_ipaddress_single[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_single->id, 'ConditionedBy ConditionIPAddressSingle CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionIPAddressSingle CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressSingle one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressSingle val');

$cf_conditioned_by_op_ipaddress_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_single, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_single->get_value, "isn't", "Isn't operation selected for conditioned by ConditionIPAddressSingle");
@cf_conditioned_by_value_ipaddress_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_single), 1, "One possible value for conditioned by isn't ConditionIPAddressSingle");
$mjs->field($cf_conditioned_by_value_ipaddress_single[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_single->id, 'ConditionedBy ConditionIPAddressSingle CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionIPAddressSingle CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressSingle one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressSingle val');

$cf_conditioned_by_op_ipaddress_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_single, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_single->get_value, "less than", "Less than operation selected for conditioned by ConditionIPAddressSingle");
@cf_conditioned_by_value_ipaddress_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_single), 1, "One possible value for conditioned by less than ConditionIPAddressSingle");
$mjs->field($cf_conditioned_by_value_ipaddress_single[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_single->id, 'ConditionedBy ConditionIPAddressSingle CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionIPAddressSingle CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressSingle one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressSingle val');

$cf_conditioned_by_op_ipaddress_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_single, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_single->get_value, "greater than", "Greater than operation selected for conditioned by ConditionIPAddressSingle");
@cf_conditioned_by_value_ipaddress_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_single), 1, "One possible value for conditioned by greater than ConditionIPAddressSingle");
$mjs->field($cf_conditioned_by_value_ipaddress_single[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_single->id, 'ConditionedBy ConditionIPAddressSingle CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionIPAddressSingle CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressSingle one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressSingle val');

$cf_conditioned_by_op_ipaddress_single = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_single, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_single->get_value, "between", "Between operation selected for conditioned by ConditionIPAddressSingle");
@cf_conditioned_by_value_ipaddress_single = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_single), 2, "Two possible values for conditioned by between ConditionIPAddressSingle");
$mjs->field($cf_conditioned_by_value_ipaddress_single[0], "192.168.1.21");
$mjs->field($cf_conditioned_by_value_ipaddress_single[1], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_single->id, 'ConditionedBy ConditionIPAddressSingle CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionIPAddressSingle CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionIPAddressSingle two vals');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressSingle first val');
is($conditioned_by->{vals}->[1], '192.168.001.021', 'ConditionedBy ConditionIPAddressSingle second val');

# Conditioned by IPAddress Multiple
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, $cf_condition_ipaddress_multiple->id);
$mjs->eval_in_page("jQuery('select[name=ConditionalCF]').trigger('change');");

my @cf_conditioned_by_op_options_ipaddress_multiple = $mjs->xpath('//select[@name="ConditionalOp"]/option');
is(scalar(@cf_conditioned_by_op_options_ipaddress_multiple), 5, 'Can be conditioned with 5 operations by ConditionIPAddressMultiple');
is($cf_conditioned_by_op_options_ipaddress_multiple[0]->get_value, "is", "Is operation for conditioned by ConditionIPAddressMultiple");
is($cf_conditioned_by_op_options_ipaddress_multiple[1]->get_value, "isn't", "Isn't operation for conditioned by ConditionIPAddressMultiple");
is($cf_conditioned_by_op_options_ipaddress_multiple[2]->get_value, "less than", "Less than operation for conditioned by ConditionIPAddressMultiple");
is($cf_conditioned_by_op_options_ipaddress_multiple[3]->get_value, "greater than", "Greater than operation for conditioned by ConditionIPAddressMultiple");
is($cf_conditioned_by_op_options_ipaddress_multiple[4]->get_value, "between", "Between operation for conditioned by ConditionIPAddressMultiple");

my $cf_conditioned_by_op_ipaddress_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
is($cf_conditioned_by_op_ipaddress_multiple->get_value, "is", "Is operation selected for conditioned by ConditionIPAddressMultiple");
my @cf_conditioned_by_value_ipaddress_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_multiple), 1, "One possible value for conditioned by is ConditionIPAddressMultiple");
$mjs->field($cf_conditioned_by_value_ipaddress_multiple[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_multiple->id, 'ConditionedBy ConditionIPAddressMultiple CF');
is($conditioned_by->{op}, "is", "ConditionedBy ConditionIPAddressMultiple CF and is operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressMultiple one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressMultiple val');

$cf_conditioned_by_op_ipaddress_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_multiple, "isn't");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_multiple->get_value, "isn't", "Isn't operation selected for conditioned by ConditionIPAddressMultiple");
@cf_conditioned_by_value_ipaddress_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_multiple), 1, "One possible value for conditioned by isn't ConditionIPAddressMultiple");
$mjs->field($cf_conditioned_by_value_ipaddress_multiple[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_multiple->id, 'ConditionedBy ConditionIPAddressMultiple CF');
is($conditioned_by->{op}, "isn't", "ConditionedBy ConditionIPAddressMultiple CF and isn't operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressMultiple one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressMultiple val');

$cf_conditioned_by_op_ipaddress_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_multiple, "less than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_multiple->get_value, "less than", "Less than operation selected for conditioned by ConditionIPAddressMultiple");
@cf_conditioned_by_value_ipaddress_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_multiple), 1, "One possible value for conditioned by less than ConditionIPAddressMultiple");
$mjs->field($cf_conditioned_by_value_ipaddress_multiple[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_multiple->id, 'ConditionedBy ConditionIPAddressMultiple CF');
is($conditioned_by->{op}, "less than", "ConditionedBy ConditionIPAddressMultiple CF and less than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressMultiple one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressMultiple val');

$cf_conditioned_by_op_ipaddress_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_multiple, "greater than");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_multiple->get_value, "greater than", "Greater than operation selected for conditioned by ConditionIPAddressMultiple");
@cf_conditioned_by_value_ipaddress_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_multiple), 1, "One possible value for conditioned by greater than ConditionIPAddressMultiple");
$mjs->field($cf_conditioned_by_value_ipaddress_multiple[0], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_multiple->id, 'ConditionedBy ConditionIPAddressMultiple CF');
is($conditioned_by->{op}, "greater than", "ConditionedBy ConditionIPAddressMultiple CF and greater than operation");
is(scalar(@{$conditioned_by->{vals}}), 1, 'ConditionedBy ConditionIPAddressMultiple one val');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressMultiple val');

$cf_conditioned_by_op_ipaddress_multiple = $mjs->xpath('//select[@name="ConditionalOp"]', single => 1);
$mjs->field($cf_conditioned_by_op_ipaddress_multiple, "between");
$mjs->eval_in_page("jQuery('select[name=ConditionalOp]').trigger('change');");
is($cf_conditioned_by_op_ipaddress_multiple->get_value, "between", "Between operation selected for conditioned by ConditionIPAddressMultiple");
@cf_conditioned_by_value_ipaddress_multiple = $mjs->xpath('//input[@name="ConditionedBy"]');
is(scalar(@cf_conditioned_by_value_ipaddress_multiple), 2, "Two possible values for conditioned by between ConditionIPAddressMultiple");
$mjs->field($cf_conditioned_by_value_ipaddress_multiple[0], "192.168.1.21");
$mjs->field($cf_conditioned_by_value_ipaddress_multiple[1], "192.168.1.6");
$mjs->click('Update');
$conditioned_by = $cf_conditioned_by->ConditionedBy;
is($conditioned_by->{CF}, $cf_condition_ipaddress_multiple->id, 'ConditionedBy ConditionIPAddressMultiple CF');
is($conditioned_by->{op}, 'between', 'ConditionedBy ConditionIPAddressMultiple CF and between operation');
is(scalar(@{$conditioned_by->{vals}}), 2, 'ConditionedBy ConditionIPAddressMultiple two vals');
is($conditioned_by->{vals}->[0], '192.168.001.006', 'ConditionedBy ConditionIPAddressMultiple first val');
is($conditioned_by->{vals}->[1], '192.168.001.021', 'ConditionedBy ConditionIPAddressMultiple second val');

# Delete conditioned by
$cf_conditioned_by_CF = $mjs->xpath('//select[@name="ConditionalCF"]', single => 1);
$mjs->field($cf_conditioned_by_CF, 0);
$mjs->eval_in_page("jQuery('.conditionedby select').trigger('change');");
$mjs->click('Update');
ok($mjs->content =~ /ConditionedBy deleted/, 'ConditionedBy deleted');
is($cf_conditioned_by->ConditionedBy, undef, 'Attribute deleted');

