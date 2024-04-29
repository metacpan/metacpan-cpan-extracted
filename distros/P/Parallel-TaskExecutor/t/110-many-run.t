use strict;
use warnings;
use utf8;

use FindBin;
use IO::Pipe;
use Parallel::TaskExecutor;
use Test2::IPC;
use Test2::V0;
use Time::HiRes 'usleep';

sub new {
  return Parallel::TaskExecutor->new(@_);
}

{
  my $e = new(max_parallel_tasks => 2);

  my @t;
  for (1..10) {
    push @t, $e->run(sub { return 5 });
  }
  my $r = 0;
  for my $t (@t) {
    $r += $t->get();
  }
  is ($r, 50, 'all data');
}

{
  my $e = new(max_parallel_tasks => 4);

  my @t;
  for (1..20) {
    push @t, $e->run(sub { usleep(1000); return 5 });
  }
  my $r = 0;
  for my $t (@t) {
    $r += $t->get();
  }
  is ($r, 100, 'all data slow');
}

done_testing;
