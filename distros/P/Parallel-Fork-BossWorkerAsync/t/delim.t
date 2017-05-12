# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl delim.t'

$ENV{log_level}='info';
$SIG{CHLD} = 'IGNORE';

use Test::More tests => 3;
BEGIN { use_ok('Parallel::Fork::BossWorkerAsync') };
require_ok('Parallel::Fork::BossWorkerAsync');
my $result=0;

my $bw = Parallel::Fork::BossWorkerAsync->new(
  work_handler   => \&work,
  result_handler => \&result,
  msg_delimiter  => "xFOOx",
);

for my $i (1..10) {
  $bw->add_work( { data => 1 } );
}

while ($bw->pending()) {
  $bw->get_result();
}

$bw->shut_down();

is($result, 10, "custom delimiter test");

sub work {
  my ($job)=@_;
  return { result => $job->{data} };
}

sub result {
  my ($r)=@_;
  $result += $r->{result};
  return $r;
}
