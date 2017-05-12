
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
  q{chmod 0200, "filename";},
  q{chmod(0200, "filename");},
  q{chmod 0000, "filename";},
  q{chmod oct(200), "filename";},
);

my @not_ok = (
# q{chmod 200, "filename";},
# q{chmod "0200", "filename";},
# q{chmod oct(0200), "filename";},
  q{$x = 0100;},
);

plan tests => @ok + @not_ok;

my $policy = 'Lax::ProhibitLeadingZeros::ExceptChmod';

for my $i (0 .. $#ok) {
  my $violation_count = pcritique($policy, \$ok[$i]);
  is($violation_count, 0, "nothing wrong with C< $ok[$i] >");
}

for my $i (0 .. $#not_ok) {
  my $violation_count = pcritique($policy, \$not_ok[$i]);
  is($violation_count, 1, "C< $not_ok[$i] > is no good");
}

