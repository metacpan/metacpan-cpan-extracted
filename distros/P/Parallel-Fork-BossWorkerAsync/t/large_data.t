# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl large_data.t'

$ENV{log_level}='info';
$SIG{CHLD} = 'IGNORE';

use Test::More tests => 3;
BEGIN { use_ok('Parallel::Fork::BossWorkerAsync') };
require_ok('Parallel::Fork::BossWorkerAsync');

my $path;
if (-e "./lib/Parallel/Fork/BossWorkerAsync.pm") {
  $path = "./lib/Parallel/Fork/BossWorkerAsync.pm";
} elsif (-e "../lib/Parallel/Fork/BossWorkerAsync.pm") {
  $path = "../lib/Parallel/Fork/BossWorkerAsync.pm";
} else {
  diag("can't find large datafile: BossWorkerAsync.pm");
  fail();
}
open(F, "< $path") or die $!;
my $data = join('', <F>);
close(F);

my $bw = Parallel::Fork::BossWorkerAsync->new(
  work_handler   => \&work,
  result_handler => \&result,
);

for my $i (1..10) {
  $bw->add_work( { data => $data } );
}

my $result=0;
my $length = length($data);
while ($bw->pending()) {
  $result += $bw->get_result()->{length};
}

$bw->shut_down();

is($result, $length * 20, "large data test");

sub work {
  my ($job)=@_;
  return { data => $job->{data}, length => length($job->{data}) };
}

sub result {
  my ($r)=@_;
  return { length => ( $r->{length} + length($r->{data}) ) };
}
