# Test on form fields

use strict;
use warnings;
use Test::More tests => 1;

use Template::Flute;

my $sort_form_spec = <<EOF;
<form name="sort" link="name">
<field name="sort"/>
</form>
EOF

my $sort_form_template = <<EOF;
<form name="sort">
    Razvrsti po:
<select name="sort" class="sort" onChange="this.form.submit()">
    <option value="priority">Priljubljenosti</option>
    <option value="price">Cena</option>
</select>
</form>
EOF

my $flute = Template::Flute->new(specification => $sort_form_spec,
                                 template => $sort_form_template,
                          );

$flute->process_template;

my $form = $flute->template->form('sort');
my $count_fields = scalar(@{$form->fields});

ok ($count_fields == 1, 'Check number of form fields')
    || diag "Number of form fields is $count_fields instead of 1.";

