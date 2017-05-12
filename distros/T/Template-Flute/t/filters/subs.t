#! perl
#
# Test for simple filter functions

use strict;
use warnings;

use Test::More;
use Template::Flute;

plan tests => 1;

my ($xml, $html, $flute, $ret, $sub);

$html =  <<EOF;
<div class="text">nevairbe</div>
EOF

$xml = <<EOF;
<specification name="filters">
<value name="text" filter="ucfirst"/>
</specification>
EOF

$sub = sub {ucfirst(shift)};

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {ucfirst => $sub},
			      values => {text => 'upper'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">Upper</div>%, "Output: $ret");
