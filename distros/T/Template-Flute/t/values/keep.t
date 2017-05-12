#! perl
#
# Test keep operation with values

use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="test" op="keep"/>
</specification>
};

$html = q{<div class="test">FOO</div>};

# keep without value

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                          );

$out = $flute->process;

like ($out, qr%<div class="test">FOO</div>%,
      "value element with op=keep without value");

# keep with value

$flute->set_values({test => 'BAR'});

$out = $flute->process;

like ($out, qr%<div class="test">BAR</div>%,
      "value element with op=keep with BAR value");

done_testing;

