
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
  q{use Foo; @ISA = qw(Foo);},
);

my @not_ok = (
  q{use base qw(Foo);},
  q{require base; base->import('Foo');},
);

plan tests => @ok + @not_ok;

my $policy = 'Tics::ProhibitUseBase';

for my $i (0 .. $#ok) {
  my $violation_count = pcritique($policy, \$ok[$i]);
  is($violation_count, 0, "nothing wrong with $ok[$i]");
}

for my $i (0 .. $#not_ok) {
  my $violation_count = pcritique($policy, \$not_ok[$i]);
  is($violation_count, 1, "$not_ok[$i] is no good");
}
