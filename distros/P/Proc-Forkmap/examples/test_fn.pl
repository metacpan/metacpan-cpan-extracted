use lib './lib';
use Proc::Forkmap qw(forkmap);

$Proc::Forkmap::MAX_PROC = 4;

sub foo {
  my $n = shift;
  sleep($n);
  print "slept for $n seconds\n";
}

my @x = (1, 2, 3);

forkmap { foo($_) } @x;
