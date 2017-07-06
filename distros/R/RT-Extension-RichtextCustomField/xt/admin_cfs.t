use strict;
use warnings;

use RT::Extension::RichtextCustomField::Test tests => 12;

use Test::WWW::Mechanize;

my ($base, $m) = RT::Extension::RichtextCustomField::Test->started_ok;
ok($m->login, 'Logged in agent');

$m->follow_link_ok({ id => 'admin-custom-fields-create' }, 'CustomField create link');
my $cf_form = $m->form_name('ModifyCustomField');
my $cf_type_select = $cf_form->find_input('TypeComposite');
my @cf_type_values = $cf_type_select->possible_values;
ok(grep(/^Richtext-1$/, @cf_type_values), 'CF has Type Richtext');

$m->submit_form(
    form_name => "ModifyCustomField",
    fields    => {
        Name          => 'Taylor',
        TypeComposite => 'Richtext-1',
        LookupType    => 'RT::Queue-RT::Ticket',
    },
);
$m->content_contains('Object created', 'CF created');
$cf_form = $m->form_name('ModifyCustomField');
my $cf_id = $cf_form->value('id');
ok $cf_id, "found id of the CF in the form, it's #$cf_id";

$cf_type_select = $cf_form->find_input('TypeComposite');
@cf_type_values = $cf_type_select->possible_values;
ok(grep(/^Richtext-1$/, @cf_type_values), 'CF has Type Richtext');

undef;
