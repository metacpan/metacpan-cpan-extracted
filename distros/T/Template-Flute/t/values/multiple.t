#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 5;
use Template::Flute;
use Data::Dumper;

my ($spec, $html, $flute, $out, $expected);

$spec =<<'XML';
<specification>
<pattern name="glide" type="string">3</pattern>
<container name="glide-o-meter" value="glide_value">
<value name="glide-o-meter-link" field="glide_value" pattern="glide" target="href"/>
<value name="glide-o-meter-img"  field="glide_value" pattern="glide" target="alt"/>
<value name="glide-o-meter-img"  field="glide_value" pattern="glide" target="src"/>
<value name="glide-o-meter-img"  field="glide_value" pattern="glide" target="onmouseover"/>
<value name="glide-o-meter-img"  field="glide_value" pattern="glide" target="onmouseout"/>
</container>
</specification>
XML

$html =<<'HTML';
<html>
<head></head><body>
<p class="glide-o-meter">
<a class="glide-o-meter-link" href="/glide-o-meter?show=3">
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
                qr{href="/glide-o-meter\?show=666"},
                qr{alt="Glide-o-meter value: 666"},
                qr{src="/images/glide/sliders/200/slider666_off.jpg"},
                qr{onmouseout="this.src='/images/glide/sliders/200/slider666_off.jpg'"},
                qr{onmouseover="this.src='/images/glide/sliders/200/slider666_on.jpg'"},
               );

foreach my $exp (@expected) {
    like $out, $exp, "img tag found with pattern replaced: $exp";
}

