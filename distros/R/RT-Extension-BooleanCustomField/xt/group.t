use strict;
use warnings;

use RT::Extension::BooleanCustomField::Test tests => 23;

use Test::WWW::Mechanize;

my ($base, $m) = RT::Extension::BooleanCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Admin/Groups/Modify.html?Create=1', 'Create group form without CF Boolean');
my $modify_form = $m->form_name('ModifyGroup');
ok($modify_form, "Create form without CF Boolean");
my @inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar(@inputs) == 1 && $inputs[0]->name eq 'Enabled', 'No checkbox without CF Boolean');

my $cf_boolean = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_boolean->Create(Name => 'Active', , LookupType => 'RT::Group', Type => 'BooleanSingle');
ok($cf_id, "CF Boolean created");
my $group = RT::Group->new(RT->SystemUser);
my $ok;
($ok, $msg) = $cf_boolean->AddToObject($group);
ok($ok, "CF Boolean added to RT::Group");

$m->get_ok($m->rt_base_url . 'Admin/Groups/Modify.html?Create=1', 'Create group form with checked CF Boolean');
$modify_form = $m->form_name('ModifyGroup');
ok($modify_form, "Create form with checked CF Boolean");
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar(@inputs) == 2 && $inputs[1]->{name} eq "Object-RT::Group--CustomField-$cf_id-Value", 'Checkbox with checked CF Boolean');

is($inputs[1]->value, undef, 'Checkbox is unchecked with checked CF Boolean');
$m->tick("Object-RT::Group--CustomField-$cf_id-Value", '1');
is($inputs[1]->value, '1', 'Checkbox is checked with checked CF Boolean');

$m->submit_form(
    form_name => "ModifyGroup",
    fields    => {
        Name => 'test_group',
    },
);
$m->content_contains("Group created", 'Group created');

$modify_form = $m->form_name('ModifyGroup');
ok($modify_form, "Modify form with unchecked CF Boolean");
my $group_id = $modify_form->value('id');
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar @inputs == 2 && $inputs[1]->{name} eq "Object-RT::Group-$group_id-CustomField-$cf_id-Value", 'Checkbox with unckecked CF Boolean');
is($inputs[1]->value, '1', 'Checkbox is checked with unchecked CF Boolean');
$m->tick("Object-RT::Group-$group_id-CustomField-$cf_id-Value", '1', undef);
is($inputs[1]->value, undef, 'Checkbox is unchecked with unchecked CF Boolean');
$m->submit_form(
    form_name => "ModifyGroup",
);
$m->content_contains("1 is no longer a value for custom field Active", 'Group modified with unchecked CF Boolean');

undef $m;
