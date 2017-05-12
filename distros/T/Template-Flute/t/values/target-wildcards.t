#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 9;
use Template::Flute;
use Data::Dumper;

my ($spec, $html, $flute, $out, $expected);

$spec =<<'XML';
<specification>
<pattern name="glide" type="string">3</pattern>
<value name="glide-o-meter-img" field="glide_value" pattern="glide" target="alt,src"/>
<value name="glide-o-meter-link" field="glide_value" target="*"/>
</specification>
XML

$html =<<'HTML';
<html>
<head></head><body>
<p class="glide-o-meter">
<a class="glide-o-meter-link" href="blabla" title="blabla">
<img class="glide-o-meter-img"
 alt="Glide-o-meter value: 3"
 src="/images/glide/sliders/200/slider3_off.jpg"
 onmouseout="this.src='/images/glide/sliders/200/slider3_off.jpg'"
 onmouseover="this.src='/images/glide/sliders/200/slider3_on.jpg'">
</a>
</p>
</body>
</html>
HTML

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         glide_value => 666,
                                        });

$out = $flute->process;

my @expected = (
                qr{href="666"},
                qr{title="666"},
                qr{class="glide-o-meter-link"},
                qr{alt="Glide-o-meter value: 666"},
                qr{src="/images/glide/sliders/200/slider666_off.jpg"},
                qr{onmouseout="this.src='/images/glide/sliders/200/slider3_off.jpg'"},
                qr{onmouseover="this.src='/images/glide/sliders/200/slider3_on.jpg'"},
               );

foreach my $exp (@expected) {
    like $out, $exp, "img tag found with pattern replaced: $exp";
}

unlike $out, qr{\*}, "No wildcards found in the output";
unlike $out, qr{alt,src}, "No comma separated attributes in the output";

