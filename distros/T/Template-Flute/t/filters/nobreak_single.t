#! perl
#
# Test for nobreak_single filter

use strict;
use warnings;

use Test::More tests => 3;
use Template::Flute;

my ($xml, $html, $flute, $ret);

$html = <<EOF;
<div class="text">foo</div>
EOF

# nobreak_single filter (empty text)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="nobreak_single"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{}
});

$ret = $flute->process();

ok($ret =~ m%div class="text">\x{a0}</div>%, "Output: $ret");

# nobreak_single filter (white space only)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="nobreak_single"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{          }
});

$ret = $flute->process();

ok($ret =~ m%div class="text">\x{a0}</div>%, "Output: $ret");

# nobreak_single filter (text)
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="nobreak_single"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => q{ Some text }
});

$ret = $flute->process();

ok($ret =~ m%div class="text"> Some text </div>%, "Output: $ret");
