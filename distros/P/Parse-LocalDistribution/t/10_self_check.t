use strict;
use warnings;
use Test::More;
use FindBin;
use Parse::LocalDistribution;

for my $fork (0..1) {
  my $p = Parse::LocalDistribution->new({FORK => $fork});
  my $provides = $p->parse("$FindBin::Bin/../");

  ok $provides && $provides->{'Parse::LocalDistribution'}{version} eq $Parse::LocalDistribution::VERSION, "version is correct";

  note explain $provides;
}

done_testing;
