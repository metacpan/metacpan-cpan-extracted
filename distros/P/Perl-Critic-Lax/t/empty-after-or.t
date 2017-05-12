
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
  q{$value = $given || '';},
  q{$value = $given // '';},
  q{$value = $given || "";},
  q{$value = $given // "";},
  q{$value = $given // q();},
  q{$value = $given . q();},
);

my @not_ok = (
  q{@array = (1, 2, '', 4);},
  q{$value = $given || '  '},
  q{print ""},
  q{$value = $given . '';},
);

plan tests => @ok + @not_ok;

my $policy = 'Lax::ProhibitEmptyQuotes::ExceptAsFallback';

for my $i (0 .. $#ok) {
  my $violation_count = pcritique($policy, \$ok[$i]);
  is($violation_count, 0, "nothing wrong with $ok[$i]");
}

for my $i (0 .. $#not_ok) {
  my $violation_count = pcritique($policy, \$not_ok[$i]);
  is($violation_count, 1, "$not_ok[$i] is no good");
}
