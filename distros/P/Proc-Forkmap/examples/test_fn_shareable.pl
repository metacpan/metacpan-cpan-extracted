use lib './lib';
use Proc::Forkmap qw(forkmap);
use IPC::Shareable;

$Proc::Forkmap::MAX_PROCS = 4;

my %opts = (create => 1);
tie @sv, 'IPC::Shareable', 'data', { %opts };

sub foo {
  my $n = shift;
  sleep($n);
  print "slept for $n seconds\n";
  $sv[$n] = $n;
}

my @x = (1, 2, 3);

forkmap { foo($_) } @x;
print join ',', grep { defined } @sv;
IPC::Shareable->clean_up_all;
