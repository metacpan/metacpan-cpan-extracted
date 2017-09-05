##!perl -T
use 5.006;
use strict;
use warnings;
use Spp qw(spp_to_spp);
use Test::More tests => 3;

my @test_case = (
   'name = ^ to $',
   '_name = to+',
   'Name = \w \s',
);

# is( $got, $expected, "The values are the same" )'
for my $rule (@test_case) {
   is(spp_to_spp($rule), $rule, "$rule => $rule");
}
