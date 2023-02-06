use Test::Instruction qw/all/;
use Terse;

instruction(
	test => 'obj',
	instance => Terse->new(),
	expected => 'Terse'
);

my $terse = Terse->new( private => 1, logger => sub { return 'okay' } );

instruction(
	test => 'obj',
	instance => $terse,
	expected => 'Terse'
);

instruction(
	test => 'code',
	instance => $terse,
	meth => 'logger'
);

instruction(
	test => 'code_execute',
	instance => $terse,
	meth => 'logger',
	expected => 'okay',
);

instruction(
	test => 'code',
	instance => $terse,
	meth => 'logger',
	args_list => 1,
	args => [ sub { return 'not_okay' } ]
);

instruction(
	test => 'code_execute',
	instance => $terse,
	meth => 'logger',
	expected => 'not_okay',
);

finish(6);
