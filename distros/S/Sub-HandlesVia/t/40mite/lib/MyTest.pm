package MyTest;

use MyTest::Mite;
use Sub::HandlesVia;

has list => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { [] },
	handles_via => 'Array',
	handles => {
		push => 'push',
		pop  => 'pop',
	},
);

1;
