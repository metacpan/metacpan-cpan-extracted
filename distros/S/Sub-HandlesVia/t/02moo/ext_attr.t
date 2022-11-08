use strict;
use warnings;
use Test::More;
{ package Local::Dummy1; use Test::Requires 'Moo' };

{
	package ParentClass;
	use Moo;

	has 'test' => (
		is => 'ro',
		default => sub { [] },
	);
}

{
	package ThisFails;
	use Moo;
	use Sub::HandlesVia;

	extends 'ParentClass';

	has '+test' => (
		handles_via => 'Array',
		handles => {
			'push' => 'push...'
		}
	);
}

my $obj = ThisFails->new;
is_deeply($obj->push('a')->push('test')->test, [qw(a test)]);

done_testing;
