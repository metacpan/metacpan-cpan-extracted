use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

#
is( Solution::Template->parse(
              <<'INPUT')->render(), <<'EXPECTED', 'raw gulps everything [A]');
{%raw%}Test{%endraw%}
INPUT
Test
EXPECTED
is( Solution::Template->parse(
              <<'INPUT')->render(), <<'EXPECTED', 'raw gulps everything [B]');
{%raw%}{{ 'Hi!' }}{%endraw%}
INPUT
{{ 'Hi!' }}
EXPECTED
is( Solution::Template->parse(
              <<'INPUT')->render(), <<'EXPECTED', 'raw gulps everything [C]');
{% raw %}
In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
{% endraw %}
INPUT

In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.

EXPECTED

# I'm finished
done_testing();
