use lib './lib';
use Proc::Forkmap;
 
sub foo {
  my $x = shift;
  my $t = sprintf("%1.0f", $x + 1);
  sleep $t;
  return "slept $t seconds\n";
}
 
my @x = (rand(), rand(), rand());
my $p = Proc::Forkmap->new(ipc => 1, non_blocking => 0);
my @rs = $p->fmap(\&foo, @x);
print for @rs;
