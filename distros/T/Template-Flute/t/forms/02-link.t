#!perl

use strict;
use warnings;
use Test::More tests => 5;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

my $xml = <<EOF;
<specification name="test">
<form name="linktest" link="name">
<field name="content"/>
</form>
</specification>
EOF

my $html = <<EOF;
<form name="linktest" id="test">
<textarea name="content">
</textarea>
</form>
EOF

# parse XML specification
my ($spec, $ret);

$spec = new Template::Flute::Specification::XML;

$ret = $spec->parse($xml);

isa_ok($ret, 'Template::Flute::Specification');

# parse HTML template
my ($html_object);

$html_object = new Template::Flute::HTML;

$html_object->parse($html, $ret);

# locate form
my ($form);

$form = $html_object->form('linktest');

isa_ok ($form, 'Template::Flute::Form');

# check form name
ok ($form->name eq 'linktest', 'form name');

# check field count
ok (scalar(@{$form->fields}) == 1, 'form field count');

# check field name
ok ($form->fields->[0]->{name} eq 'content', 'form field name')
   || diag "field name: " . $form->fields->[0]->{name};
