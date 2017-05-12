use 5.20.0;

use Test::More;

use MoobX;

my $x :Observable = 2;
my @y :Observable = 1..3;
my %z :Observable = 'a'..'d';

my $obs = observer sub {
    $x . $y[0] . $z{a};
};

is( $obs => '21b' );

$x = 'a';
$y[0] = 'b';
$z{a} = 'c';

is( $obs => 'abc' );

done_testing;
