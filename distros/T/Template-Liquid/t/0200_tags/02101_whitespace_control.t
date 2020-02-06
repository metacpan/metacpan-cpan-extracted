use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
$|++;
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(), '  Wow,John G. Chalmers-Smith, you have a long name!', 'whitespace control');
{%- assign username = "John G. Chalmers-Smith" -%}
{%- if username and username.size > 10 -%}
  Wow, {{- username -}} , you have a long name!
{%- else -%}
  Hello there!
{%- endif -%}
TEMPLATE
is( Template::Liquid->parse(
         <<'TEMPLATE')->render(), <<'EXPECTED', 'without whitespace control');
{% assign username = "John G. Chalmers-Smith" %}
{% if username and username.size > 10 %}
  Wow, {{ username }}, you have a long name!
{% else %}
  Hello there!
{% endif %}
TEMPLATE


  Wow, John G. Chalmers-Smith, you have a long name!

EXPECTED
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(), <<'EXPECTED', 'mixed with and without whitespace control');
{%-assign username = "John G. Chalmers-Smith"-%}
{%-if username and username.size > 10 %}
  Wow, {{- username -}} , you have a long name!
  Wow, {{  username -}} , you have a long name!
  Wow, {{- username  }} , you have a long name!
  Wow, {{  username  }} , you have a long name!
{%else%}
  Hello there!
{%endif-%}
TEMPLATE

  Wow,John G. Chalmers-Smith, you have a long name!
  Wow, John G. Chalmers-Smith, you have a long name!
  Wow,John G. Chalmers-Smith , you have a long name!
  Wow, John G. Chalmers-Smith , you have a long name!
EXPECTED
done_testing();
