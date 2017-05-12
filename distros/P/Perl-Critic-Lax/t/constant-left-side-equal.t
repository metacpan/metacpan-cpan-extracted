
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
  q{ if( 6 == $foo ){} },
  q{ while( 6 == $foo ){} },
  q{ unless( 6 == $foo ){} },
);

my @not_ok = (
  q{ if( $foo == 6 ){} },
  q{ while( $foo == 6 ){} },
  q{ unless( $foo == 6 ){} },
);

plan tests => @ok + @not_ok;

my $policy = 'Lax::RequireConstantOnLeftSideOfEquality::ExceptEq';

for my $test (@ok) {
  my $violation_count = pcritique($policy, \$test);
  is($violation_count, 0, "nothing wrong with C< $test >");
}

for my $test (@not_ok) {
  my $violation_count = pcritique($policy, \$test);
  is($violation_count, 1, "C< $test > is no good");
}
