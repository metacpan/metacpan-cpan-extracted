use strict;
use warnings;

use RT::Extension::BooleanCustomField::Test tests => 23;

use Test::WWW::Mechanize;

my ($base, $m) = RT::Extension::BooleanCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Admin/Users/Modify.html?Create=1', 'Create user form without CF Boolean');
my $modify_form = $m->form_name('UserCreate');
ok($modify_form, "Create form without CF Boolean");
my @inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar(@inputs) == 2 && $inputs[0]->name eq 'Enabled' && $inputs[1]->name eq 'Privileged', 'No checkbox without CF Boolean');

my $cf_boolean = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_boolean->Create(Name => 'Active', , LookupType => 'RT::User', Type => 'BooleanSingle');
ok($cf_id, "CF Boolean created");
my $user = RT::User->new(RT->SystemUser);
my $ok;
($ok, $msg) = $cf_boolean->AddToObject($user);
ok($ok, "CF Boolean added to RT::User");

$m->get_ok($m->rt_base_url . 'Admin/Users/Modify.html?Create=1', 'Create user form with checked CF Boolean');
$modify_form = $m->form_name('UserCreate');
ok($modify_form, "Create form with checked CF Boolean");
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar(@inputs) == 3 && $inputs[2]->{name} eq "Object-RT::User--CustomField-$cf_id-Value", 'Checkbox with checked CF Boolean');

is($inputs[2]->value, undef, 'Checkbox is unchecked with checked CF Boolean');
$m->tick("Object-RT::User--CustomField-$cf_id-Value", '1');
is($inputs[2]->value, '1', 'Checkbox is checked with checked CF Boolean');

$m->submit_form(
    form_name => "UserCreate",
    fields    => {
        Name => 'test_user',
    },
);
$m->content_contains("User created", 'User created');

$modify_form = $m->form_name('UserModify');
ok($modify_form, "Modify form with unchecked CF Boolean");
my $user_id = $modify_form->value('id');
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar @inputs == 3 && $inputs[2]->{name} eq "Object-RT::User-$user_id-CustomField-$cf_id-Value", 'Checkbox with unckecked CF Boolean');
is($inputs[2]->value, '1', 'Checkbox is checked with unchecked CF Boolean');
$m->tick("Object-RT::User-$user_id-CustomField-$cf_id-Value", '1', undef);
is($inputs[2]->value, undef, 'Checkbox is unchecked with unchecked CF Boolean');
$m->submit_form(
    form_name => "UserModify",
);
$m->content_contains("1 is no longer a value for custom field Active", 'User modified with unchecked CF Boolean');

undef $m;
