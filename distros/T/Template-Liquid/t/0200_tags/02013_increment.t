use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
$|++;
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', 'my_counter');
{% increment my_counter %}
{% increment my_counter %}
{% increment my_counter %}
INPUT
0
1
2
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q[increment var is not assign var]);
{% assign var = 10 %}
{% increment var %}
{% increment var %}
{% increment var %}
{{ var }}
INPUT

0
1
2
10
EXPECTED

# I'm finished
done_testing
