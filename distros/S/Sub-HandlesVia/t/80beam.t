use strict;
use warnings;
use Test::More;

use Test::Requires 'Beam::Wire';
{ package Local::Dummy1; use Test::Requires 'Moose::Role' };


package ThisFailsRole {
	use Moose::Role;
	use Sub::HandlesVia;

	has 'test' => (
		is => 'rw',
		default => sub { [] },
		handles_via => 'Array',
		handles => {
			'add_test' => 'push',
		}
	);
}

pass;
done_testing;
