package MyTest;

use MyTest::Mite;
use Sub::HandlesVia;

has list => (
	is => 'ro',
	isa => 'ArrayRef',
	default => \ '[11]',
	handles_via => 'Array',
	handles => {
		push  => 'push',
		pop   => 'pop',
		reset => 'reset',
	},
);

1;
