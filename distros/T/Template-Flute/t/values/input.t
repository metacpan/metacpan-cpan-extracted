#
# Tests for values and HTML input elements

use strict;
use warnings;

use Test::More;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="promo_code" class="promo_code" field="promo_code" target="value"/>
</specification>
};

$html = q{<input name="promo_code" class="promo_code" value=""/>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                  promo_code => '1234',
                              });

$out = $flute->process;

ok($out =~ <input class="promo_code" name="promo_code" value="1234" />,
   "Test replacing value attribute")
    || diag "Out: $out";

done_testing;
