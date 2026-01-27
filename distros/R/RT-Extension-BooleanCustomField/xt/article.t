use strict;
use warnings;

use RT::Extension::BooleanCustomField::Test tests => 27;

use Test::WWW::Mechanize;

my $class = RT::Class->new(RT->SystemUser);
$class->Load('General');

my ($base, $m) = RT::Extension::BooleanCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->get_ok($m->rt_base_url . 'Articles/Article/Edit.html?Class=' . $class->id, 'Create article form');
my $edit_form = $m->form_name('EditArticle');
ok($edit_form, "Create form without CF Boolean");
my @inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar(@inputs) == 1 && $inputs[0]->name eq 'Enabled', 'No checkbox without CF Boolean');

my $cf_boolean = RT::CustomField->new(RT->SystemUser);
my ($cf_id, $msg) = $cf_boolean->Create(Name => 'Active', LookupType => 'RT::Class-RT::Article', Type => 'BooleanSingle');
ok($cf_id, "CF Boolean created");
my $ok;
($ok, $msg) = $cf_boolean->AddToObject($class);
ok($ok, "CF Boolean added to General class");

$m->get_ok($m->rt_base_url . 'Articles/Article/Edit.html?Class=' . $class->id, 'Create article form');
$edit_form = $m->form_name('EditArticle');
ok($edit_form, "Create form with checked CF Boolean");
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar(@inputs) == 2 && $inputs[1]->{name} eq "Object-RT::Article--CustomField-$cf_id-Value", 'Checkbox with checked CF Boolean');

is($inputs[1]->value, undef, 'Checkbox is unchecked with checked CF Boolean');
$m->tick("Object-RT::Article--CustomField-$cf_id-Value", '1');
is($inputs[1]->value, '1', 'Checkbox is checked with checked CF Boolean');

$m->submit_form(
    form_name => "EditArticle",
    fields    => {
        Name => 'test_article',
    },
);
my $article_id = $m->form_name('EditArticle')->value('id');
$m->content_contains("Article $article_id created", 'Article created');

$m->follow_link_ok({ id => 'page-display' }, 'Article display link');
if (RT::Handle::cmp_version($RT::VERSION, '6.0.0') >= 0) {
    $m->content_like(qr{<div class="rt-label">\s*<span[^>]*>Active</span><svg[^>]*><path[^>]*><path[^>]*></svg>\s*</div>\s*<div class="rt-value ">\s*<span[^>]*>\s*&\#10004;\s*</span>\s*</div>}, 'Checked CF Boolean displayed in HTML');
} elsif (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $m->content_like(qr{<td class="label">Active:</td>\s*<td class="value">\s*&\#10004;\s*</td>}, 'Checked CF Boolean displayed in HTML');
} else {
    $m->content_like(qr{<div class="label col-\d+">\s*<span class="prev-icon-helper">Active:</span><span class="far fa-question-circle icon-helper" data-toggle="tooltip" data-placement="top" data-original-title="Check/Uncheck"></span>\s*</div>\s*<div class="value col-\d+\s*">\s*<span class="current-value">\s*&\#10004;\s*</span>\s*</div>}, 'Checked CF Boolean displayed in HTML');
}

$m->follow_link_ok({ id => 'page-modify' }, 'Article modify link');
$edit_form = $m->form_name('EditArticle');
@inputs = $m->find_all_inputs(type => 'checkbox');
ok(scalar @inputs == 2 && $inputs[1]->{name} eq "Object-RT::Article-$article_id-CustomField-$cf_id-Value", 'Checkbox with unckecked CF Boolean');
is($inputs[1]->value, '1', 'Checkbox is checked with unchecked CF Boolean');
$m->tick("Object-RT::Article-$article_id-CustomField-$cf_id-Value", '1', undef);
is($inputs[1]->value, undef, 'Checkbox is unchecked with unchecked CF Boolean');
$m->submit_form(
    form_name => "EditArticle",
);
$m->content_contains("1 is no longer a value for custom field Active", 'Article modified with unchecked CF Boolean');
$m->follow_link_ok({ id => 'page-display' }, 'Article display link');
if (RT::Handle::cmp_version($RT::VERSION, '6.0.0') >= 0) {
    $m->content_like(qr{<div class="rt-label">\s*<span[^>]*>Active</span><svg[^>]*><path[^>]*><path[^>]*></svg>\s*</div>\s*<div class="rt-value  no-value">\s*<span[^>]*>\s*\(no value\)\s*</span>\s*</div>}, 'Unchecked CF Boolean displayed in HTML');
} elsif (RT::Handle::cmp_version($RT::VERSION, '5.0.0') < 0) {
    $m->content_like(qr{<td class="label">Active:</td>\s*<td class="value no-value">\s*\(no value\)\s*</td>}, 'Unchecked CF Boolean displayed in HTML');
} else {
    $m->content_like(qr{<div class="label col-\d+">\s*<span class="prev-icon-helper">Active:</span><span class="far fa-question-circle icon-helper" data-toggle="tooltip" data-placement="top" data-original-title="Check/Uncheck"></span>\s*</div>\s*<div class="value col-\d+\s* no-value">\s*<span class="current-value">\s*\(no value\)\s*</span>\s*</div>}, 'Unchecked CF Boolean displayed in HTML');
}

undef $m;
