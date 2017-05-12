#! perl
#
# Test for container and value sharing same elements.

use strict;
use warnings;

use Test::More tests => 1;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification><container name="foo" value="bar"/><value name="foo" id="foo"/></specification>};
$html = q{<ul><li class="foo" id="foo">one</li><li class="foo" id="bar">two</li></ul>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {foo => 'three'},
    );

$out = $flute->process();

ok ($out =~ m%<ul></ul>%, 'Test whether shared elements between container and value are working.')
    || diag "Mismatch on elements: $out";


