use v5.24;
use warnings;
use Test::More;
use Mock::Sub;

##############################################################################
# This test checks if the correct class for superpositions is constructed and
# if the superpositions are able to create their basic function which is
# collapsing to a random state that they are made of.
##############################################################################

my $rand;    # mocked random sub

BEGIN {
	# mock before importing, so that we control the RNG in Q::S
	use_ok('Quantum::Superpositions::Lazy::Util');
	$rand = Mock::Sub->new->mock("Quantum::Superpositions::Lazy::Util::get_rand");
	use_ok('Quantum::Superpositions::Lazy', 'superpos', 'collapse');
}

my $pos = superpos(1);

isa_ok($pos, "Quantum::Superpositions::Lazy::Superposition", "class constructed ok");
is $pos->collapse, 1, "collapsing a single value ok";

my @data = 1 .. 100;
my $superpos = superpos(@data);
my %wanted = map { $_ => 1 } @data;

is scalar $superpos->_states->@*, scalar @data, "construction ok";

for (keys @data) {
	$rand->return_value(1 / @data * $_ + 1 / @data / 2);

	my $collapsed = $superpos->collapse;
	ok $superpos->is_collapsed, "superposition collapsed ok";

	note Quantum::Superpositions::Lazy::Util::get_rand . " - $collapsed";
	delete $wanted{$collapsed};

	$superpos->reset;
	ok !$superpos->is_collapsed, "superposition reset ok";
}

is scalar keys %wanted, 0, "superposition collapsed values ok";

my $nested = superpos($pos);
is $nested->collapse, 1, "nested superpositions ok";
$nested->reset;
ok !$pos->is_collapsed, "nested reset ok";

my $one_of = superpos(1);
is_deeply
	[collapse($one_of, superpos(2), superpos(3))],
	[1, 2, 3],
	"collapse function ok";

ok $one_of->is_collapsed, "collapsed ok";

subtest 'empty superposition' => sub {
	my $pos = superpos();
	is defined $pos->collapse, defined undef, 'result value ok';
	is defined $pos->reset->collapse, defined undef, 'reset + result value ok';
	is scalar $pos->states->@*, 0, 'states ok';
};

done_testing;

