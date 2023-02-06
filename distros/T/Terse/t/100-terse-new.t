use Test::Instruction qw/all/;
use Terse;

instruction(
	test => 'obj',
	instance => Terse->new(),
	expected => 'Terse'
);

my $terse = Terse->new( a => 1, b => 2 );

instruction(
	test => 'obj',
	instance => $terse,
	expected => 'Terse'
);

instruction(
	test => 'hash',
	instance => $terse,
	expected => {
		a => 1,
		b => 2
	}
);

my $private = Terse->new( private => 1, a => 1, b => 2 );

instruction(
	test => 'obj',
	instance => $private,
	expected => 'Terse'
);

instruction(
	test => 'hash',
	instance => $private,
	expected => {
		'_a' => 1,
		'_b' => 2
	}
);

finish(5);
