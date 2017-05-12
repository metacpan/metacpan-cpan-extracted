
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More tests => 7;

my @ok = (
  q{ eval "require $string" },
  q{ eval "require $string; 19;" },
  q{ eval "use $module 1 qw(a b c); 1" },
);

my @not_ok = (
  q{ eval "system 'rm -rf /'" },
  q{ eval "require $string; die" },
  q{ eval 'require $string'   },
  q{ eval qq(#line 1 "code"\n1;); },
);

my $policy = 'Lax::ProhibitStringyEval::ExceptForRequire';

for my $test (@ok) {
  my $violation_count = pcritique($policy, \$test);
  is($violation_count, 0, "nothing wrong with C< $test >");
}

for my $test (@not_ok) {
  my $violation_count = pcritique($policy, \$test);
  is($violation_count, 1, "C< $test > is no good");
}
