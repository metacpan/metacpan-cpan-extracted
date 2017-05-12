#
# Test for values and HTML img elements

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="promo_pic" class="promo_pic" field="promo_pic"/>
</specification>
};

$html = q{<img src="promo.jpg" class="promo_pic"/>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                  promo_pic => 'ad.png',
                              });

$out = $flute->process;

ok($out =~ <img src="ad.png" class="promo_pic"/>,
   "Test replacing src attribute")
    || diag "Out: $out";

done_testing;
