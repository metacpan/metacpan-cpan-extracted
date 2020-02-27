#!perl

use Test::More;

use Prometheus::Tiny::Shared;
use File::Temp qw(tmpnam);

my $filename = scalar tmpnam();

my $p = Prometheus::Tiny::Shared->new(filename => $filename);

# parent, mark it and start a count
$p->set('parent', 1);
$p->set('count', 1);

my $pid = fork;
if (!$pid) {
  # child, mark it too and bump the count
  $p->set('child', 1);
  $p->inc('count');
  exit 0;
}

# parent, bump the count here too
$p->inc('count');

wait();

is $p->format, <<EOF, 'correct metrics after fork';
child 1
count 3
parent 1
EOF

done_testing;
