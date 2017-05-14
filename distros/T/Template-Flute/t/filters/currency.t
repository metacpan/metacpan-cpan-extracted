#! perl
#
# Test for currency filter

use strict;
use warnings;

use POSIX;
use Test::More;
use Template::Flute;

eval "use Number::Format";

if ($@) {
    plan skip_all => "Missing Number::Format module.";
}

plan tests => 3;

POSIX::setlocale(&POSIX::LC_ALL, 'C');

my ($xml, $html, $flute, %currency_options, $ret);

$html = <<EOF;
<div class="text">foo</div>
EOF

$xml = <<EOF;
<specification name="filters">
<value name="text" filter="currency"/>
</specification>
EOF

# currency filter
$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      values => {text => '30'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">USD 30.00</div>%, "Output: $ret");

# currency filter (options: int_curr_symbol)
%currency_options = (int_curr_symbol => '$');

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {currency => {options => \%currency_options}},
			      values => {text => '30'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">\$ 30.00</div>%, "Output: $ret");

# currency filter (European style of display)
%currency_options = (int_curr_symbol => 'EUR',
		     p_cs_precedes => 0,
		     mon_thousands_sep => '.',
		     mon_decimal_point => ',',
		     p_sep_by_space => 1);

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {currency => {options => \%currency_options}},
			      values => {text => '10200'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">10.200,00 EUR</div>%, "Output: $ret");
