# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl large_return.t'

$ENV{log_level}='info';
$SIG{CHLD} = 'IGNORE';

use Test::More tests => 4;
BEGIN { use_ok('Parallel::Fork::BossWorkerAsync') };
require_ok('Parallel::Fork::BossWorkerAsync');

my ($path, $len, $data, $rlen, $rdata);
if (-e "./lib/Parallel/Fork/BossWorkerAsync.pm") {
  $path = "./lib/Parallel/Fork/BossWorkerAsync.pm";
} elsif (-e "../lib/Parallel/Fork/BossWorkerAsync.pm") {
  $path = "../lib/Parallel/Fork/BossWorkerAsync.pm";
} else {
  diag("can't find large datafile: BossWorkerAsync.pm");
  fail();
}
open(F, "< $path") or die $!;
$data  = join('', <F>);
$len   = length($data);
close(F);

my $multiplier = 256;

my $bw = Parallel::Fork::BossWorkerAsync->new(
  work_handler   => \&work,
);

for my $i (1..1) {
  $bw->add_work( { data => $data } );
}

while ($bw->pending()) {
  my $h  = $bw->get_result();
  $rlen  = $h->{length};
  $rdata = $h->{data};
}

$bw->shut_down();

is($rlen, length($rdata), "large return test 1");
is($rlen, $len * $multiplier, "large return test 2");


sub work {
  my ($job)=@_;
  my $large_return;
  for my $i (1 .. $multiplier) {
    $large_return .= $job->{data};
  }

  return { data => $large_return, length => length($large_return) };
}

