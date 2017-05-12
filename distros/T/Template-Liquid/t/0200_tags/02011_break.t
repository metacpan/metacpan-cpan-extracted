use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
is( Template::Liquid->parse(
                       <<'INPUT')->render(), <<'EXPECTED', 'no-op on render');
{% continue %}
INPUT

EXPECTED
#
my %assigns = (array => {items => [1 .. 10]});
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'break drops out of for loop');
{% for i in array.items %}{% break %}{% endfor %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'drop out after first iteration (before end of block)');
{% for i in array.items %}{% break %}{{ i }}{% endfor %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'drop out after 4th iteration');
{% for i in array.items %}{{ i }}{% if i > 3 %}{% break %}{% endif %}{% endfor %}
INPUT
1234
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(array => [[1, 2], [3, 4], [5, 6]]), <<'EXPECTED', 'breaks out of the local for loop and not all of them');
{% for item in array %}{% for i in item %}{% if i == 1 %}{% break %}{% endif %}{{ i }}{% endfor %}{% endfor %}
INPUT
3456
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render('array' => {'items' => [1, 2, 3, 4, 5]}), <<'EXPECTED', 'break does nothing when unreached');
{% for i in array.items %}{% if i == 9999 %}{% break %}{% endif %}{{ i }}{% endfor %}
INPUT
12345
EXPECTED

# I'm finished
done_testing();
