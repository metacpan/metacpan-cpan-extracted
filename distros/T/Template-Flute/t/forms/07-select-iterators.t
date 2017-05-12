use strict;
use warnings;
use Test::More tests => 14;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

my $xml_cut = <<EOF;
<specification name="select">
<form name="select" id="dropdown">
<field name="regions" id="regions" iterator="regions" iterator_value_key="code" iterator_name_key="name"/>
</form>
</specification>
EOF

my $xml_keep = <<EOF;
<specification name="select">
<form name="select" id="dropdown">
<field name="regions" id="regions" iterator="regions" keep="empty_value" iterator_value_key="code" iterator_name_key="name"/>
</form>
</specification>
EOF

my $xml_dup = <<EOF;
<specification name="select">
<form name="select" id="dropdown">
<field name="regions" id="regions" iterator="regions" iterator_value_key="code" iterator_name_key="name"/>
<field name="lander" id="lander" iterator="regions" iterator_value_key="code" iterator_name_key="name"/>
</form>
</specification>
EOF

my $html = <<EOF;
<form name="dropdown" id="dropdown">
<select name="regions" id="regions">
<option value="">Your Region</option>
</select>
<select name="lander" id="lander">
<option value="">Dein Bundesland</option>
</select>
</form>
EOF

# parse XML specifications
my ($spec_cut, $spec_dup, $spec_keep, $ret_cut, $ret_dup, $ret_keep);

$spec_cut = new Template::Flute::Specification::XML;

$ret_cut = $spec_cut->parse($xml_cut);

isa_ok($ret_cut, 'Template::Flute::Specification');

$spec_dup = new Template::Flute::Specification::XML;

$ret_dup = $spec_dup->parse($xml_dup);

isa_ok($ret_dup, 'Template::Flute::Specification');

$spec_keep = new Template::Flute::Specification::XML;

$spec_keep = new Template::Flute::Specification::XML;

$ret_keep = $spec_keep->parse($xml_keep);

isa_ok($ret_keep, 'Template::Flute::Specification');

# add iterator
$ret_cut->set_iterator('regions',
					   Template::Flute::Iterator->new([{
                                                        code => 'EUR',
                                                        name => 'Europe',
                                                       },
													   {
                                                        code => 'AF',
                                                        name => 'Africa',
                                                       }]));

$ret_dup->set_iterator('regions',
					   Template::Flute::Iterator->new([{
                                                        code => 'EUR',
                                                        name => 'Europe',
                                                       },
													   {
                                                        code => 'AF',
                                                        name => 'Africa',
                                                       }]));

$ret_keep->set_iterator('regions',
					   Template::Flute::Iterator->new([{
                                                        code => 'EUR',
                                                        name => 'Europe',
                                                       },
													   {
                                                        code => 'AF',
                                                        name => 'Africa',
                                                       }]));

# 1st specification (replace first select)

# parse HTML template
my ($html_object_cut, $html_object_keep, $form, $flute, $ret);

$html_object_cut = new Template::Flute::HTML;

$html_object_cut->parse($html, $ret_cut);

# locate form
$form = $html_object_cut->form('select');

isa_ok ($form, 'Template::Flute::Form');

$form->fill({});

$flute = new Template::Flute(specification => $ret_cut,
							  template => $html_object_cut,
);

eval {
	$ret = $flute->process();
};

ok($ret !~ /Your Region/, $ret);
ok($ret =~ /AF/, $ret);

# 2nd specification (replace both selects)

# parse HTML template
my ($html_object_dup);

$html_object_dup = new Template::Flute::HTML;

$html_object_dup->parse($html, $ret_dup);

# locate form
$form = $html_object_dup->form('select');

isa_ok ($form, 'Template::Flute::Form');

$form->fill({});

$flute = new Template::Flute(specification => $ret_dup,
							  template => $html_object_dup,
);

eval {
	$ret = $flute->process();
};

ok($ret !~ /Your Region/, 'Test whether first static string was replaced.')
    || diag "Output: $ret";

ok($ret =~ /AF/, 'Test for correct value of replacement')
    || diag "Output: $ret";

ok($ret !~ /Dein Bundesland/, 'Test whether second static string was replaced.')
    || diag "Output: $ret";

ok($ret =~ m%<select id="lander" name="lander"><option value="EUR">Europe</option><option value="AF">Africa</option></select>%,
   'Test for correct value of replacement.')
    || diag "Output: $ret";

# 3rd specification (keep the existing option)

$html_object_keep = new Template::Flute::HTML;

$html_object_keep->parse($html, $ret_keep);

# locate form
$form = $html_object_keep->form('select');

isa_ok ($form, 'Template::Flute::Form');

$form->fill({});

$flute = new Template::Flute(specification => $ret_keep,
							 template => $html_object_keep,
);

eval {
	$ret = $flute->process();
};

ok($ret =~ /Your Region/, $ret);
ok($ret =~ /AF/, $ret);
