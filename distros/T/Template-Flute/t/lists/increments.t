# Tests for list increments

use strict;
use warnings;

use Test::More tests => 1;
use Template::Flute;

my ($spec, $html, $flute, $out, $iter);

$spec = q{<specification>
<list name="list" iterator="tokens">
<param name="pos" increment="1"/>
<param name="value"/>
</list>
</specification>
};

$html = q{<html><div class="list"><span class="pos">1</span><span class="value"></span></div></html>};

$iter = [{value => 'one'}, {value => 'two'}, {value => 'three'}];

$flute = Template::Flute->new(template => $html,
                           specification => $spec,
                           values => {tokens => $iter},
    );

$out = $flute->process();

ok($out =~ m%<span class="pos">1</span>.*?<span class="pos">2</span>.*?<span class="pos">3</span>%,
   'Basic list increment test')
    || diag "Output: $out.";

