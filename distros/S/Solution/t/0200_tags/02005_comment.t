use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

#
my $solution = new_ok('Solution::Template');

#
is( Solution::Template->parse(
          <<'INPUT')->render(), <<'EXPECTED', 'Comment gulps everything [A]');
{%comment%}

Test

{%endcomment%}
INPUT

EXPECTED
is( Solution::Template->parse(
          <<'INPUT')->render(), <<'EXPECTED', 'Comment gulps everything [B]');
{%comment%}

{{ 'Hi!' }}

{%endcomment%}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Comment does not render children [A]');
{%comment%}Test{%endcomment%}[{{some_var}}]
INPUT
[]
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Comment does not render children [B]');
{%comment%}{%for x in (1..3)%}Test {%endfor%}{%endcomment%}[{{some_var}}]
INPUT
[]
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Comment does not render children [C]');
{%comment%}{%comment %}{%for x in (1..3)%}Test {%endfor%}{%endcomment%}[{{some_other_var}}]{%endcomment%}[{{some_var}}]
INPUT
[]
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Comment does not render children [D] (from pod)');
{% assign str = 'Initial value' %}
{% comment %}
    {% assign str = 'Different value' %}
{% endcomment %}
{{ str }}
INPUT


Initial value
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Comment does not render children [D] (from Liquid wiki)');
We made 1 million dollars {% comment %} in losses {% endcomment %} this year
INPUT
We made 1 million dollars  this year
EXPECTED

# I'm finished
done_testing();
