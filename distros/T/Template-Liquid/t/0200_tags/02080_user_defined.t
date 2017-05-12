use strict;
use warnings;
use lib qw[../../lib ../../blib/lib lib blib/lib ./t/0200_tags/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
use Template::LiquidX::Tag::Random;
is( Template::Liquid->parse(
                           <<'INPUT')->render(), <<'EXPECTED', 'always true');
{% random 1 %}Now, that's time{%comment%} well{%endcomment%} spent!{% endrandom %}
INPUT
Now, that's time spent!
EXPECTED
is( Template::Liquid->parse(
                     <<'INPUT')->render(), <<'EXPECTED', 'almost never true');
{% random 1000000000000000000 %}Now, that's time{%comment%} well{%endcomment%} spent!{% endrandom %}
INPUT

EXPECTED

# I'm finished
done_testing();
