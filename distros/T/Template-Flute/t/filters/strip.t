#! perl
#
# Test for strip filter

use strict;
use warnings;
use Test::More tests => 1;

use Template::Flute;

my ($xml, $html, $flute, $ret);

# upper filter
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="strip"/>
</specification>
EOF

$html = <<EOF;
<div class="text">foo</div>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => '  bar '});

$ret = $flute->process();

ok($ret =~ m%<div class="text">bar</div>%, "Output: $ret");
