use strict;
use warnings;
use Test::More tests => 2; # 1 in agg test, 1 subtest
use lib 't/lib';
use AggTestTester;

my $args = {
  tests => [catfile(qw(aggtests-extras fork_and_exit.t))],
};

Test::Aggregate->new({%$args})->run;

SKIP: {

  # The nested fork test crashes on windows.
  # I have no idea why and I don't care enough
  # to spend any more time trying to figure it out.
  # If you know or care, patches are most welcome.
  skip('Skip nested fork test on windows', 1)
    if $^O eq 'MSWin32';

only_with_nested {
  subtest nested => sub {
    Test::Aggregate::Nested->new({%$args})->run;
  };
};

}
