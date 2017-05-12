# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl end-to-end.t'

$ENV{log_level}='info';
$SIG{CHLD} = 'IGNORE';

use Test::More tests => 3;
BEGIN { use_ok('Parallel::Fork::BossWorkerAsync') };
require_ok('Parallel::Fork::BossWorkerAsync');

my $bw = Parallel::Fork::BossWorkerAsync->new(
  work_handler   => \&work,
  result_handler => \&result,
);

# nonblocking test
$bw->add_work( { data => 1 } );
is( $bw->get_result_nb(), undef, "nonblocking");

$bw->get_result();
$bw->shut_down();

sub work {
  my ($job)=@_;
  sleep(3);
  return { result => $job->{data} };
}

sub result {
  my ($r)=@_;
  $result += $r->{result};
  return $r;
}
