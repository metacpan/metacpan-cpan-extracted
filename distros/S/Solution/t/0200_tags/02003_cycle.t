use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

#
is( Solution::Template->parse(
                         <<'INPUT')->render(), <<'EXPECTED', 'Simple syntax');
{% cycle 'one', 'two', 'three' %}
{% cycle 'one', 'two', 'three' %}
{% cycle 'one', 'two', 'three' %}
{% cycle 'one', 'two', 'three' %}
INPUT
one
two
three
one
EXPECTED
is( Solution::Template->parse(
                          <<'INPUT')->render(), <<'EXPECTED', 'Named syntax');
{% cycle 'group 1': 'one', 'two', 'three' %}
{% cycle 'group 1': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
INPUT
one
two
one
two
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({items => [qw[one two three four five]]}), <<'EXPECTED', 'Real world use [A]');
{% for item in items %}
   <div class="{%cycle 'red', 'green', 'blue' %}"> Item {{ item }} </div>{% endfor %}
INPUT

   <div class="red"> Item one </div>
   <div class="green"> Item two </div>
   <div class="blue"> Item three </div>
   <div class="red"> Item four </div>
   <div class="green"> Item five </div>
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({items => [qw[one two three four five]]}), <<'EXPECTED', 'Real world use [A.2]');
{% for item in items %}
   <div class="{%cycle 'red', 'green', 'blue' %}"> Item {{ item }} </div>{% endfor %}
INPUT

   <div class="red"> Item one </div>
   <div class="green"> Item two </div>
   <div class="blue"> Item three </div>
   <div class="red"> Item four </div>
   <div class="green"> Item five </div>
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({grp_one => 'group 1'}), <<'EXPECTED', 'variable as cycle name');
{% cycle  grp_one : 'one', 'two', 'three' %}
{% cycle 'group 1': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
INPUT
one
two
one
two
EXPECTED

# Stored context between renderings
my $solution = new_ok('Solution::Template');
is( $solution->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Stored context between renderings [A]');
{% cycle 'group 1': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
{% cycle 'group 1': 'one', 'two', 'three' %}
INPUT
one
one
two
EXPECTED
is($solution->render(),
    <<'EXPECTED', 'Stored context between renderings [B]');
three
two
one
EXPECTED

# I'm finished
done_testing();
