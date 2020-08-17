#!perl

use strict;
use warnings;
use Test::More;
use Proc::CPUUsage;

my $usage;
my $cpu = Proc::CPUUsage->new;
ok($cpu);
sleep(1);
my $little_usage = $cpu->usage;
ok($little_usage < .1, "Sleepy process, little usage ($little_usage)");

for (my $i = 0; $i < 500_000; $i++) {};
my $big_usage = $cpu->usage;
ok($big_usage > $little_usage, "Active process, big usage ($big_usage) > little usage ($little_usage)");

## No support for getrusage()
my @bad_replies = (
  [ 'no support' => [undef, undef] ],
  [ 'only utime' => [1, undef    ] ],
  [ 'only stime' => [undef, 1    ] ],
);

for my $test_case (@bad_replies) {
  {
    no warnings;
    *Proc::CPUUsage::getrusage = sub (;$) { return @{$test_case->[1]} };
  }
  my $bad_cpu = Proc::CPUUsage->new;
  ok($bad_cpu);
  ok(!defined($bad_cpu->usage), "usage() returns undef in case '$test_case->[0]'")
}

done_testing();
