use lib './lib';
use Proc::Forkmap;
 
sub foo {
  my $x = shift;
  my $t = sprintf("%1.0f", $x + 1);
  sleep $t;
  print "slept $t seconds\n";
}
 
my @x = (rand(), rand(), rand());
my $p = Proc::Forkmap->new;
$p->fmap(\&foo, @x);
