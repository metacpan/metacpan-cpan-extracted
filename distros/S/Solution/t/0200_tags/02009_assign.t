use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;
$|++;
is( Solution::Template->parse(
        <<'INPUT')->render({values => [qw[foo bar baz]]}), <<'EXPECTED', q[assign w/ array]);
{% assign foo = values %}.{{ foo[0] }}.
INPUT
.foo.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({values => [qw[foo bar baz]]}), <<'EXPECTED', q[assign w/ array (part 2)]);
{% assign foo = values %}.{{ foo[1] }}.
INPUT
.bar.
EXPECTED
is( Solution::Template->parse(
        <<'INPUT')->render({values => 'foo,bar,baz'}), <<'EXPECTED', q[assign w/ filter]);
{% assign foo = values | split: ',' %}.{{ foo[1] }}.
INPUT
.bar.
EXPECTED

# Various condition types
is( Solution::Template->parse(
                    <<'INPUT')->render(), <<'EXPECTED', q[assign five = '5']);
{% assign five = '5' %}{% for t in (0...10) %}{% if t == five %}Five{% endif %}{% endfor %}
INPUT
Five
EXPECTED

# https://github.com/Shopify/liquid/pull/80
is( Solution::Template->parse(
        <<'INPUT')->render(), <<'EXPECTED', q[assign five = 'five' | upcase]);
{% assign five = 'five' | upcase %}{{five}}
INPUT
FIVE
EXPECTED
is( Solution::Template->parse(
              <<'INPUT')->render(), <<'EXPECTED', q[assign ... = false/true]);
{% assign four = false %}{% assign nine = false
%}{% for t in (0..5)
    %}{% if t == 4 %}{% assign four = true %}{% endif
    %}{% if t == 9 %}{% assign nine = true %}{% endif
%}{% endfor %}{%
    if four %}4{% endif %}{% if nine %}9{% endif %}
INPUT
4
EXPECTED

# I'm finished
done_testing
