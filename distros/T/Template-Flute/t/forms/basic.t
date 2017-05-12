# Testing basic methods of form object
use strict;
use warnings;
use Test::More;

use Template::Flute;

my $sort_form_spec = <<EOF;
<form name="sort" link="name">
<field name="sort"/>
</form>
EOF

my $sort_form_template = <<EOF;
    Razvrsti po:
<select name="sort" class="sort" onChange="this.form.submit()">
    <option value="priority">Priljubljenosti</option>
    <option value="price">Cena</option>
</select>
</form>
EOF

my @form_att_tests = ({html => q{<form name="sort" action="/search">},
                       method => 'GET',
                       action => '/search',
                   },
                      {html => q{<form name="sort" method="get">},
                       method => 'GET',
                       action => '',
                   },
                      {html => q{<form name="sort" action="test" method="pOSt">},
                       method => 'POST',
                       action => 'test',
                   },
                  );

plan tests => 3 * scalar(@form_att_tests);

for my $test (@form_att_tests) {
    my $flute = Template::Flute->new(specification => $sort_form_spec,
                                     template => $test->{html} . $sort_form_template,
                                 );

    $flute->process_template;

    my $form = $flute->template->form('sort');

    isa_ok($form, 'Template::Flute::Form');

    my $action = $form->action;

    ok(defined $action && $action eq $test->{action}, 'Return value of action method')
        || diag "$action instead of $test->{action}";

    my $method = $form->method;

    ok(defined $method && $method eq $test->{method}, 'Return value of method method')
        || diag "$method instead of $test->{method}";
}
