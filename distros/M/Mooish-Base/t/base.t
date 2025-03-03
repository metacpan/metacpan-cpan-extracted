use Test2::V0;

################################################################################
# This tests whether class and role importers work
################################################################################

{

	package MyTestRole;

	use v5.14;
	use warnings;

	use Mooish::Base -role;

	requires qw(negate);

	has param 'test_req' => (
		isa => Int,
	);
}

{

	package MyTest;

	use v5.14;
	use warnings;

	use Mooish::Base;

	with 'MyTestRole';

	sub negate
	{
		my $self = shift;

		return -1 * $self->test_req;
	}
}

my $t = MyTest->new(test_req => -42);
is $t->negate, 42, 'class seems ok';

done_testing;

