use v5.28;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy;
use List::Util qw(sum0);

sub roll_dice
{
	my ($dnd) = @_;

	my ($number, $faces) = $dnd =~ m{ \A (\d+) k (\d+) \z }x;

	# each individual dice
	my @dice = map { superpos(1 .. $faces) } 1 .. $number;

	# a cup of dice
	my $set = sum0 @dice;

	return ($set, @dice);
}

my @throws = (
	"2k6",
	"8k12",
	"3k20",
);

for my $dnd (@throws) {

	note "Rolling $dnd...";
	my ($set, @dice) = roll_dice $dnd;

	# we roll them all at once
	my $result = $set->collapse;

	# this is how we can get each individual roll
	my @rolls = map { $_->collapse } @dice;

	note "we got $result, which consisted of rolls: " . join ", ", @rolls;
	is $result, (sum0 @rolls), "result ok";

	# ... and lets roll again
	$set->reset;
	$result = $set->collapse;
	@rolls = map { $_->collapse } @dice;

	note "this time we got $result, which consisted of rolls: " . join ", ", @rolls;
	is $result, (sum0 @rolls), "result ok";
}

done_testing;

__END__

=pod

In this example, we get the dice number and faces number in Dungeons and
Dragons notation: I<NkF>, where I<N> is the number of dice and I<F> in the
number of faces on each dice.

Each dice is held in its own superposition, we entangle them into a single
system with addition, and then we "throw" them by calling C<collapse> on the
entire system.
