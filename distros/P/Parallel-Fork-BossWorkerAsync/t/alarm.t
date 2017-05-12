# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl alarm.t'

$ENV{log_level}='info';
$SIG{CHLD} = 'IGNORE';

use Test::More tests => 3;
BEGIN { use_ok('Parallel::Fork::BossWorkerAsync') };
require_ok('Parallel::Fork::BossWorkerAsync');
my $result=0;

my $bw = Parallel::Fork::BossWorkerAsync->new(
  work_handler   => \&work,
  result_handler => \&result,
  global_timeout => 3,
  worker_count   => 1,
);

$bw->add_work( { data => 4 } );
$bw->add_work( { data => 2 } );

while ($bw->pending()) {
  $bw->get_result();
}

$bw->shut_down();
is($result, 2, "alarm");

sub work {
  my ($job)=@_;
  my $counter=0;

  for (1..$job->{data}) {
    sleep(1);
    $counter++;
  }
  return { result => $counter };
}

sub result {
  my ($r)=@_;
  
  if ($r) {
    if (exists($r->{ERROR}) && $r->{ERROR} =~ /timed out/) {
    } else {
      $result += $r->{result};
    }
  }
  return $r;
}

