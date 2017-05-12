
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my %in_a_row = (
  0 => q{my %hash = (1, 2, 3, 4);},
  1 => [
    q{my %hash = (1 => 2, 3, 4);},
    q{my %hash = (1 => 2, 3 => 4);},
  ],
  2 => q{my %hash = (1 => 2 => 3, 4);},
  3 => q{%hash = (key => value => key2 => 'value2');},
  4 => q{%hash = (key => value => key2 => value2 =>);},
);

plan tests => 11; # XXX: calculate this -- rjbs, 2007-07-30

my $policy = 'Tics::ProhibitManyArrows';

my $max = (reverse sort keys %in_a_row)[0];

for my $i (0 .. $max) {
  my @tests = ref $in_a_row{$i} ? @{ $in_a_row{$i} } : $in_a_row{$i};

  for my $code (@tests) {
    my $viol_count = pcritique($policy, \$code, { max_allowed => $i });
    is($viol_count, 0, "nothing wrong with $code, max_allowed $i");

    if ($i > 0) {
      my $viol_count = pcritique($policy, \$code, { max_allowed => $i - 1});
      ok($viol_count > 0, "violations for $code, max_allowed " . ($i - 1));
    }
  }
}
