use v5.36;
use Test::More;
use lib 'lib';
use Peta::NN::RNG;

# The generator is what makes a training run reproducible, so its stream is
# pinned: these values must not change, on any perl.
my $rng = Peta::NN::RNG->new(42);
my @first = map { $rng->uniform; $rng->{state} } 1 .. 3;
is_deeply(\@first, [ 2027382, 1226992407, 551494037 ], 'the stream for seed 42 is pinned');

my ($one, $two) = map { Peta::NN::RNG->new(7) } 1 .. 2;
is_deeply([ map { $one->uniform } 1 .. 50 ], [ map { $two->uniform } 1 .. 50 ], 'same seed, same stream');
isnt(Peta::NN::RNG->new(1)->uniform, Peta::NN::RNG->new(2)->uniform, 'another seed, another stream');

$rng = Peta::NN::RNG->new(3);
my @u = map { $rng->uniform } 1 .. 20_000;
ok(!(grep { $_ <= 0 || $_ >= 1 } @u), 'uniform stays inside (0, 1)');
my $mean = 0;
$mean += $_ / @u for @u;
cmp_ok(abs($mean - 0.5), '<', 0.01, 'uniform has mean 0.5');

my @z = map { $rng->normal } 1 .. 20_000;
my ($m, $var) = (0, 0);
$m   += $_ / @z for @z;
$var += ($_ - $m)**2 / @z for @z;
cmp_ok(abs($m), '<', 0.03, 'normal has mean 0');
cmp_ok(abs($var - 1), '<', 0.05, 'normal has variance 1');

my %hit;
$hit{ $rng->below(6) }++ for 1 .. 6000;
is_deeply([ sort keys %hit ], [ 0 .. 5 ], 'below(6) yields exactly 0..5');

my @deck = 1 .. 100;
$rng->shuffle(\@deck);
is_deeply([ sort { $a <=> $b } @deck ], [ 1 .. 100 ], 'shuffle keeps every element');
isnt("@deck", "@{[ 1 .. 100 ]}", 'shuffle changes the order');

is(Peta::NN::RNG->new(0)->{state}, 1, 'a zero seed is replaced, it would stay zero forever');

done_testing;
