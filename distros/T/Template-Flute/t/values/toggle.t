#
# Toggle tests for values

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="test" op="toggle"/>
</specification>
};

$html = q{<html><div class="test">TEST</div></html>};

for my $value (0, 1, ' ', 'test') {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {test => $value},
    );

    $out = $flute->process();

    if ($value) {
        like ($out, qr%<div class="test">$value</div>%,
            "toggle value test with: $value")
            || diag $out;
    }
    else {
        unlike ($out, qr/div/,
            "toggle value test with: $value")
            || diag $out;
    }
}
