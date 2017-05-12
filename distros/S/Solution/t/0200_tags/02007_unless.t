use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;

# Various condition types
is(Solution::Template->parse(<<'INPUT')->render(), <<'EXPECTED', '1 == 1');
{% unless 1 == 1 %}One equals one{% endunless %}
INPUT

EXPECTED
is(Solution::Template->parse(<<'INPUT')->render(), <<'EXPECTED', '1 != 1');
{% unless 1 != 1 %}One does not equal one{% endunless %}
INPUT
One does not equal one
EXPECTED
is(Solution::Template->parse(<<'INPUT')->render(), <<'EXPECTED', q[1 < 2]);
{% unless 1 < 2 %}Yep.{% endunless %}
INPUT

EXPECTED
is(Solution::Template->parse(<<'INPUT')->render(), <<'EXPECTED', q[1 > 2]);
{% unless 1 > 2 %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' contains 'string']);
{% unless 'This string' contains 'string' %}Yep.{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' contains 'some other string']);
{% unless 'This string' contains 'some other string' %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' == 'This string']);
{% unless 'This string' == 'This string' %}Yep.{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' == 'some other string']);
{% unless 'This string' == 'some other string' %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' != 'some other string']);
{% unless 'This string' != 'some other string' %}Yep.{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q['This string' != 'This string']);
{% unless 'This string' != 'This string' %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({list => [qw[some other value]]}), <<'EXPECTED', q[list contains 'other']);
{% unless list contains 'other' %}Yep.{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({list => [qw[some other value]]}), <<'EXPECTED', q[list contains 'missing element']);
{% unless list contains 'missing element' %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({list_one => [qw[a b c d]], list_two => [qw[a b c d]]}), <<'EXPECTED', q[list_one == list_two [A]]);
{% unless list_one == list_two %}Yep.{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({list_one => [qw[a b c d]], list_two => [qw[a b c d e]]}), <<'EXPECTED', q[list_one == list_two [B]]);
{% unless list_one == list_two %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({list_one => [qw[a b c d]], list_two => [qw[a b c e]]}), <<'EXPECTED', q[list_one == list_two [C]]);
{% unless list_one == list_two %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({hash_one => {key => 'value'}, hash_two => {key => 'value'}}), <<'EXPECTED', q[hash_one == hash_two [A]]);
{% unless hash_one == hash_two %}Yep.{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({hash_one => {key => 'value'}, hash_two => {key => 'wrong value'}}), <<'EXPECTED', q[hash_one == hash_two [B]]);
{% unless hash_one == hash_two %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({hash_one => {key => 'value'}, hash_two => {other_key => 'value'}}), <<'EXPECTED', q[hash_one == hash_two [C]]);
{% unless hash_one == hash_two %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({hash => {key => 'value'}, list => [qw[key value]]}), <<'EXPECTED', q[hash == list]);
{% unless hash == list %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({hash => {key => 'value'}}), <<'EXPECTED', q[hash contains 'key']);
{% unless hash contains 'key' %}Yep.{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({hash => {key => 'value'}}), <<'EXPECTED', q[hash contains 'missing key']);
{% unless hash contains 'missing key' %}Yep.{% endunless %}
INPUT
Yep.
EXPECTED
is( Solution::Template->parse(
                         <<'INPUT')->render(), <<'EXPECTED', 'else fallback');
{% unless 1 != 1 %}One does not equal one{% else %}else{% endunless %}
INPUT
One does not equal one
EXPECTED
is(Solution::Template->parse(<<'INPUT')->render(), <<'EXPECTED', '5 = 5');
{% unless 1 != 1 %}One does not equal one{% elsif 5 == 5 %}Five equals five{% endunless %}
INPUT
One does not equal one
EXPECTED
is( Solution::Template->parse(
                      <<'INPUT')->render(), <<'EXPECTED', 'no fallback else');
{% unless 1 != 1 %}One does not equal one{% elsif 5 == 50 %}Five equals fifty{% endunless %}
INPUT
One does not equal one
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound unless [A] (1 != 1 or 1 < 5)');
{% unless 1 != 1 or 1 < 5 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 %}
    Five equals fifty
{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound unless [B] (1 != 1 and 1 < 5)');
{% unless 1 != 1 and 1 < 5 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 %}
    Five equals fifty
{% endunless %}
INPUT

    One does not equal one or one is less than five.

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound else?if [A] (elsif 5 == 50 or 3 > 1)');
{% unless 0 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 or 3 > 1 %}
    Five equals fifty
{% endunless %}
INPUT

    One does not equal one or one is less than five.

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound else?if [B] (elsif 5 == 50 and 3 > 1)');
{% unless 1 %}
    One does not equal one or one is less than five.
{% elsif 5 == 50 and 3 > 1 %}
    Five equals fifty
{% endunless %}
INPUT

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound else?if [A] (elseif 5 == 50 or 3 > 1)');
{% unless 1 %}
    One does not equal one or one is less than five.
{% elseif 5 == 50 or 3 > 1 %}
    Five equals fifty
{% endunless %}
INPUT

    Five equals fifty

EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'compound elsif [B] (else?if 5 == 50 and 3 > 1)');
{% unless 1 %}
    One does not equal one or one is less than five.
{% elseif 5 == 50 and 3 > 1 %}
    Five equals fifty
{% endunless %}
INPUT

EXPECTED

# I'm finished
done_testing();
