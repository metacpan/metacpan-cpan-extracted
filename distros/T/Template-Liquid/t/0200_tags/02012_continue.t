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
my %assigns = ('array' => {'items' => [1, 2, 3, 4, 5]});
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'continue drops out of for loop');
{% for i in array.items %}{% continue %}{% endfor %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'drop out after first iteration');
{% for i in array.items %}{{ i }}{% continue %}{% endfor %}
INPUT
12345
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'skip out of loop before var is rendered');
{% for i in array.items %}{% continue %}{{ i }}{% endfor %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'skips out of the local for loop and not all of them');
{% for i in array.items %}{% if i > 3 %}{% continue %}{% endif %}{{ i }}{% endfor %}
INPUT
123
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(%assigns), <<'EXPECTED', 'continue does nothing when unreached');
{% for i in array.items %}{% if i == 3 %}{% continue %}{% else %}{{ i }}{% endif %}{% endfor %}
INPUT
1245
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(array => [[1, 2], [3, 4], [5, 6]]), <<'EXPECTED', 'ensure it only continues the local for loop and not all of them');
{% for item in array %}{% for i in item %}{% if i == 1 %}{% continue %}{% endif %}{{ i }}{% endfor %}{% endfor %}
INPUT
23456
EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(array => {items => [1, 2, 3, 4, 5]}), <<'EXPECTED', 'continue does nothing when unreached');
{% for i in array.items %}{% if i == 9999 %}{% continue %}{% endif %}{{ i }}{% endfor %}
INPUT
12345
EXPECTED

# I'm finished
done_testing();
