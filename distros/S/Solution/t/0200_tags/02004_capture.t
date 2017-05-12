use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

#
my $solution = new_ok('Solution::Template');

#
is( Solution::Template->parse(
          <<'INPUT')->render(), <<'EXPECTED', 'Capture gulps everything [A]');
{%capture some_var%}

Test

{%endcapture%}
INPUT

EXPECTED
is( Solution::Template->parse(
          <<'INPUT')->render(), <<'EXPECTED', 'Capture gulps everything [B]');
{%capture some_var%}

{{ 'Hi!' }}

{%endcapture%}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Capture collects stuff into var [A]');
{%capture some_var%}Test{%endcapture%}[{{some_var}}]
INPUT
[Test]
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Capture collects stuff into var [B]');
{%capture some_var%}{%for x in (1..3)%}Test {%endfor%}{%endcapture%}[{{some_var}}]
INPUT
[Test Test Test ]
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Capture collects stuff into var [C] (even other captures o.O)');
{%capture some_var%}{%capture some_other_var%}{%for x in (1..3)%}Test {%endfor%}{%endcapture%}[{{some_other_var}}]{%endcapture%}[{{some_var}}]
INPUT
[[Test Test Test ]]
EXPECTED

# From capture_test.rb
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q[capture to var from outer scope if existing]);
{% assign first = '' %}{% assign second = '' %}{% for number in (1..3) %}{%
        capture first %}{{number}}{% endcapture
        %}{% assign second = first %}{%
 endfor %}
{{ first }}-{{ second }}
INPUT

3-3
EXPECTED
is( Solution::Template->parse(
                  <<'INPUT')->render(), <<'EXPECTED', q[assign from capture]);
{% assign var = '' %}{% if true %}{% capture var %}first-block-string{% endcapture %}{% endif %}{% if true %}{% capture var %}test-string{% endcapture %}{% endif %}
{{var}}
INPUT

test-string
EXPECTED

# I'm finished
done_testing();
