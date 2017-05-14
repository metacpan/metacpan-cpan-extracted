#!perl

use strict;
use warnings;
use Template::Flute;
use Test::More tests => 8;
use Data::Dumper;

my ($spec, $html, $flute, $out, $expected);

$spec =<<'SPEC';
<specification>
<pattern name="pxt" type="string">123</pattern>
<list name="items" iterator="items">
  <param name="number"/>
  <param name="category" pattern="pxt"/>
</list>
<value name="cartline" pattern="pxt"/>
</specification>
SPEC

# here we use the same 123 pattern to interpolate two unrelated things
$html =<<'HTML';
<p class="cartline">There are 123 items in your shopping cart.</p>
<ul>
  <li class="items">
    <span class="number">1</span>
    <span class="category">in category 123</span>
  </li>
</ul>
HTML

my $iterator = [
                { number => 1,
                  category => "tofu" },
                { number => 2,
                  category => "pizza" },
               ];

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         items => $iterator,
                                         cartline => "42",
                                        });

$out = $flute->process;

$expected =<<'EXPECTED';
<p class="cartline">There are 42 items in your shopping cart.</p>
EXPECTED

$expected =~ s/\n//g;
like $out, qr/\Q$expected\E/, "Interpolation value by pattern";

$expected =<<'EXPECTED';
<ul>
<li class="items">
<span class="number">1</span>
<span class="category">in category tofu</span>
</li>
<li class="items">
<span class="number">2</span>
<span class="category">in category pizza</span>
</li>
</ul>
EXPECTED

$expected =~ s/\n//g;
like $out, qr/\Q$expected\E/, "Interpolation param by pattern";

# pattern with Perly false value
$spec =<<'SPEC';
<specification>
<pattern name="pxt" type="string">0</pattern>
<value name="cartline" pattern="pxt"/>
</specification>
SPEC

my $html_false =<<'HTML';
<p class="cartline">There are 0 items in your shopping cart.</p>
<ul>
  <li class="items">
    <span class="number">1</span>
    <span class="category">in category 123</span>
  </li>
</ul>
HTML

$flute = Template::Flute->new(template => $html_false,
                              specification => $spec,
                              values => {
                                         cartline => "42",
                                        });

$out = $flute->process;

$expected =<<'EXPECTED';
<p class="cartline">There are 42 items in your shopping cart.</p>
EXPECTED

$expected =~ s/\n//g;
like $out, qr/\Q$expected\E/, "Interpolation value by pattern with false value";

# multiple patterns

$spec =<<'SPEC';
<specification>
<pattern name="pxtcat" type="string">123</pattern>
<pattern name="pxtline" type="regexp">123</pattern>
<list name="items" iterator="items">
  <param name="number"/>
  <param name="category" pattern="pxt"/>
</list>
<value name="cartline" pattern="pxt"/>
</specification>
SPEC

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         items => $iterator,
                                         cartline => "42",
                                        });

eval { $out = $flute->process; };
like $@, qr/o pattern named pxt/, "Wrong pattern name raises an exception";

$spec =<<'SPEC';
<specification>
<pattern>123</pattern>
<pattern name="pxtline" type="regexp">123</pattern>
<list name="items" iterator="items">
  <param name="number"/>
  <param name="category" pattern="pxtcat"/>
</list>
<value name="cartline" pattern="pxtline"/>
</specification>
SPEC

eval {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {
                                             items => $iterator,
                                             cartline => "42",
                                            });
};

like $@, qr/Missing name for pattern/, "Missing attributes raise an exception";

$spec =<<'SPEC';
<specification>
<pattern name="pxtcat" type="dummy">123</pattern>
<pattern name="pxtline" type="regexp">123</pattern>
<list name="items" iterator="items">
  <param name="number"/>
  <param name="category" pattern="pxtcat"/>
</list>
<value name="cartline" pattern="pxtline"/>
</specification>
SPEC

eval {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {
                                             items => $iterator,
                                             cartline => "42",
                                            });
};

like $@, qr/Wrong pattern type dummy/, "Wrong type raises an exception";


$spec =<<'SPEC';
<specification>
<pattern name="pxtcat" type="regexp">^in category</pattern>
<pattern name="pxtline" type="regexp">There.*123</pattern>
<list name="items" iterator="items">
  <param name="number"/>
  <param name="category" pattern="pxtcat"/>
</list>
<value name="cartline" pattern="pxtline"/>
</specification>
SPEC

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         items => $iterator,
                                         cartline => "42",
                                        });

$out = $flute->process;

$expected =<<'EXPECTED';
<p class="cartline">42 items in your shopping cart.</p>
EXPECTED

$expected =~ s/\n//g;
like $out, qr/\Q$expected\E/, "Interpolation value by pattern";

$expected =<<'EXPECTED';
<ul>
<li class="items">
<span class="number">1</span>
<span class="category">tofu 123</span>
</li>
<li class="items">
<span class="number">2</span>
<span class="category">pizza 123</span>
</li>
</ul>
EXPECTED

$expected =~ s/\n//g;
like $out, qr/\Q$expected\E/, "Interpolation param by pattern";
