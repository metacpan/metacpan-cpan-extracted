#!perl

use strict;
use warnings;
use Test::More tests => 2;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

my $xml = <<EOF;
<specification name="helloworld">
<value name="hello"/>
</specification>
EOF

my $html = <<EOF;
<span class="hello">TEXT</span>
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

my $flute = new Template::Flute(specification => $ret,
							  template => $html_object,
							  values => {hello => 'Hello World'},
);

eval {
	$ret = $flute->process();
};

ok($ret =~ /Hello World/);


