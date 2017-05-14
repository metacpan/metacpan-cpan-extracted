#! perl
#
# Test for JSON variable filter

use strict;
use warnings;

use Test::More;
use Template::Flute;

eval "use JSON";

if ($@) {
    plan skip_all => "Missing JSON module.";
}

plan tests => 2;

my ($xml, $html, $flute, $ret);

$html =  <<EOF;
<script type="text/javascript" id="jsonvar">
</script>
EOF

# jsonvar filter
$xml = <<EOF;
<specification name="filters">
<value name="json" id="jsonvar" filter="json_var"/>
</specification>
EOF


$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {json_var => {options => {engine => 'eval'}}},
			      values => {json => {user => 'shopper@nitesi.biz'}},
);

$ret = $flute->process();

ok(index($ret, q{var json = eval('({"user":"shopper@nitesi.biz"})');}) > 0, "JSON variable filter test with eval engine")
    || diag ($ret);


$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {json_var => {options => {engine => 'jquery'}}},
			      values => {json => {user => 'shopper@nitesi.biz'}},
);

$ret = $flute->process();

ok(index($ret, q{var json = $.parseJSON('{"user":"shopper@nitesi.biz"}');}) > 0, "JSON variable filter test with jquery engine")
    || diag ($ret);
