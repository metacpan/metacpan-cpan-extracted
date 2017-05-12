#! perl
#
# Test for container with dotted values.

use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Template::Flute;

my ($spec, $html, $flute, $out);

# dotted values without input
$spec = q{<specification><container name="foo" value="foo.bar"/><value name="foo" field="foo.bar" id="foo"/></specification>};
$html = q{<ul><li class="foo" id="foo">one</li><li class="foo" id="bar">two</li></ul>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
    );

$out = $flute->process();

ok ($out =~ m%<ul></ul>%, 'Dotted values in container without input')
    || diag "Mismatch on elements: $out";

# reverse dotted values without input
$spec = q{<specification><container name="foo" value="!foo.bar"/><value name="foo" field="foo.bar" id="foo"/></specification>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
    );

$out = $flute->process();

ok ($out =~ m%<ul><li class="foo" id="foo"></li><li class="foo" id="bar">two</li></ul>%, 'Dotted values in container without input (reverse)')
    || diag "Mismatch on elements: $out";

# dotted values with input
$spec = q{<specification><container name="foo" value="foo.bar"/><value name="foo" field="foo.bar" id="foo"/></specification>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {foo => {bar => 'three'}},
    );

$out = $flute->process();

ok ($out =~ m%<ul><li class="foo" id="foo">three</li><li class="foo" id="bar">two</li></ul>%, 'Dotted values in container with input.')
    || diag "Mismatch on elements: $out";

# reverse dotted values with input
$spec = q{<specification><container name="foo" value="!foo.bar"/><value name="foo" field="foo.bar" id="foo"/></specification>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {foo => {bar => 'three'}},
    );

$out = $flute->process();

ok ($out =~ m%<ul></ul>%, 'Dotted values in container with input (reverse).')
    || diag "Mismatch on elements: $out";

# dotted values in container with three level input
$spec = q{<specification><container name="foo" value="foo.bar"/><value name="foo" field="foo.bar.baz" id="foo"/></specification>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {foo => {bar => {baz => 'three'}}},
    );

$out = $flute->process();

ok ($out =~ m%<ul><li class="foo" id="foo">three</li><li class="foo" id="bar">two</li></ul>%, 'Dotted values in container with three level input.')
    || diag "Mismatch on elements: $out";

# reverse dotted values in container with three level input
$spec = q{<specification><container name="foo" value="!foo.bar"/><value name="foo" field="foo.bar.baz" id="foo"/></specification>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {foo => {bar => {baz => 'three'}}},
    );

$out = $flute->process();

ok ($out =~ m%<ul></ul>%, 'Dotted values in container with three level input (reverse).')
    || diag "Mismatch on elements: $out";

done_testing;
