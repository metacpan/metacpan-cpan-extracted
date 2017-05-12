#! perl
#
# Test for multiple filters

use strict;
use warnings;
use Test::More tests => 1;

use Template::Flute;

my ($xml, $html, $flute, $ret);

# upper filter
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="upper eol"/>
</specification>
EOF

$html = <<EOF;
<div class="text">foo</div>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => 'foo
bar'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">FOO<br />BAR</div>%, "Output: $ret");
