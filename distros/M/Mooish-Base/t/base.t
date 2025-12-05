use Test2::V0;

################################################################################
# This tests whether class and role importers work
################################################################################

{

	package MyTestRole;

	use v5.10;
	use strict;
	use warnings;

	use Mooish::Base -role;

	requires qw(negate);

	has param 'test_req' => (
		isa => Int,
	);
}

{

	package MyTest;

	use v5.10;
	use strict;
	use warnings;

	use Mooish::Base;

	with 'MyTestRole';

	sub negate
	{
		my $self = shift;

		return -1 * $self->test_req;
	}
}

{

	package MyTestRoleStandard;

	use v5.10;
	use strict;
	use warnings;

	use Mooish::Base -role, -standard;

	requires qw(negate);

	has param 'test_req' => (
		isa => Int,
	);
}

{

	package MyTestStandard;

	use v5.10;
	use strict;
	use warnings;

	use Mooish::Base -standard;

	with 'MyTestRoleStandard';

	sub negate
	{
		my $self = shift;

		return -1 * $self->test_req;
	}
}

my $t = MyTest->new(test_req => -42);
is $t->negate, 42, 'class seems ok';

my $ts = MyTestStandard->new(test_req => -42);
is $ts->negate, 42, 'standard class seems ok';

done_testing;

