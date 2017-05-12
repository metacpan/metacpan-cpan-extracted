use strictures 1;
use Test::More;
use Mojito::Page;

my ($m, $n) = (3, 0);
my $base = ('^') x $m;
my $place = ('^') x $n;

is("HEAD${base}", 'HEAD^^^', 'HEAD base');
is("HEAD${place}", 'HEAD', 'HEAD place');

done_testing();
