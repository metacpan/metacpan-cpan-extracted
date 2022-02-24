
use Test::More;

use SQL::Abstract;

my $sql = SQL::Abstract->new->plugin('+TableAlias');
	
my ($stmt, @bind) = $sql->select({
	select => [ qw/one two three/, [qw/four five/], [qw/six seven eight/] ],
	from => [
		"numbers",
		-join => [
			integers => on => { one => "one" }
		],
		-join => {
			on => { two => { ">" => "other" } },
			to => "floats",
			type => "left"
		}
	],
	where => {
		five => "A",
		six => "B",
		nine => "C"
	},
	order_by => [
		qw/one/,
		{ -asc => 'four' },
		{ -desc => [qw/three seven/] }
	],
});

my $expected = q|SELECT numbers.one, numbers.two, numbers.three, integers.four, integers.five, floats.six, floats.seven, floats.eight FROM numbers AS numbers JOIN integers AS integers ON numbers.one = integers.one LEFT JOIN floats AS floats ON integers.two > floats.other WHERE ( floats.six = ? AND integers.five = ? AND numbers.nine = ? ) ORDER BY numbers.one, integers.four ASC, numbers.three DESC, floats.seven DESC|;

is($stmt, $expected, 'expected: ' . $expected);

my ($stmt, @bind) = $sql->select({
	talias => [n, i, f],
	select => [ qw/one two three/, [qw/four five/], [qw/six seven eight/] ],
	from => [
		"numbers",
		-join => [
			integers => on => { one => "one" }
		],
		-join => {
			on => { two => { ">" => "other" } },
			to => "floats",
			type => "left"
		}
	],
	where => {
		five => "A",
		six => "B",
		nine => "C"
	},
	order_by => [
		qw/one/,
		{ -asc => 'four' },
		{ -desc => [qw/three seven/] }
	],
});

my $expected = q|SELECT n.one, n.two, n.three, i.four, i.five, f.six, f.seven, f.eight FROM numbers AS n JOIN integers AS i ON n.one = i.one LEFT JOIN floats AS f ON i.two > f.other WHERE ( f.six = ? AND i.five = ? AND n.nine = ? ) ORDER BY n.one, i.four ASC, n.three DESC, f.seven DESC|;

is($stmt, $expected, 'expected: ' . $expected);

done_testing;




