use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
$|++;
is(Template::Liquid->parse(<<'INPUT')->render(), <<'EXPECTED', 'my_counter');
{% decrement my_counter %}
{% decrement my_counter %}
{% decrement my_counter %}
INPUT
-1
-2
-3
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', q[decrement var is not assign var]);
{% assign var = 10 %}
{% decrement var %}
{% decrement var %}
{% decrement var %}
{{ var }}
INPUT

-1
-2
-3
10
EXPECTED

# I'm finished
done_testing
