use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
is( Template::Liquid->parse(
                    <<'INPUT')->render(), <<'EXPECTED', 'Falls back to else');
{% case condition %}
{% when 1 %}
    One
        {% else %}
    Else
{% endcase %}
INPUT

    Else

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'No match and no fallback else [A]');
{% case condition %}
{% when 1 %}
    One
{% endcase %}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(eval <<'ARGS'), <<'EXPECTED', 'No match and no fallback else [B]');
{% case condition %}
{% when 1 %}
    One
{% when 2 or 3 %}
    Two or Three
{% endcase %}
TEMPLATE
condition => 12
ARGS

EXPECTED
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(eval <<'ARGS'), <<'EXPECTED', 'Simple condition [A]');
{% case condition %}
{% when 1 %}
        One
{% endcase %}
TEMPLATE
condition => 1
ARGS

        One

EXPECTED
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(eval <<'ARGS'), <<'EXPECTED', 'Simple condition [B]');
{% case condition %}
{% when 1 %}
        One
{% when 3 %}
        Three
{% endcase %}
TEMPLATE
condition => 3
ARGS

        Three

EXPECTED
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(eval <<'ARGS'), <<'EXPECTED', 'Compound condition [C]');
{% case condition %}
{% when 1 %}
        One
{% when 2 or 3 %}
        Two or Three
{% endcase %}
TEMPLATE
condition => 2
ARGS

        Two or Three

EXPECTED
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(eval <<'ARGS'), <<'EXPECTED', 'Compound condition [D]');
{% case condition %}
{% when 1 %}
    One
{% when 2 or 3 %}
    Two or Three
{% endcase %}
TEMPLATE
condition => 100
ARGS

EXPECTED
is( Template::Liquid->parse(
        <<'TEMPLATE')->render(eval <<'ARGS'), <<'EXPECTED', 'Non-numeric condition [A]');
{% case condition %}
{% when "Alpha" %}
    A
{% when "Beta" or "Gamma" %}
    B or C
{% endcase %}
TEMPLATE
condition => 'Alpha'
ARGS

    A

EXPECTED
is( Template::Liquid->parse(
          <<'TEMPLATE')->render(), <<'EXPECTED', 'Non-numeric condition [B]');
{% case "Gamma" %}
{% when "Alpha" %}
        A
{% when "Beta" %}
        B
{% when "Gamma" %}
        C
{% endcase %}
TEMPLATE

        C

EXPECTED

# I'm finished
done_testing();
