use Test::More tests => 10;
use Pointy::Counter;

my $i = counter;
my $j = 0;
while($i --> 5)
{
	$j++;
	is($i, $j);
}
$i->continue;
while($i --> 10)
{
	$j++;
	is($i, $j);
}
