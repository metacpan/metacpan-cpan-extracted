use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Method;

{
	package Test0;
	use Moose;
	extends 'MooseY::RemoteHelper::MessagePart';

	has attr => (
		remote_name => 'attribute',
		isa         => 'Str',
		is          => 'ro',
	);

	__PACKAGE__->meta->make_immutable;
}
{
	package Test1;
	use Moose;
	extends 'Test0';

	has other => (
		remote_name => 'otherattr',
		isa         => 'Str',
		is          => 'ro',
		required    => 1,
	);

	__PACKAGE__->meta->make_immutable;
}

my $t0 = new_ok 'Test0' => [{ attribute => 'foo' }];
my $t1 = new_ok 'Test0' => [{ attribute => undef }];
my $t2 = new_ok 'Test1' => [{ otherattr => 'foo' }];

method_ok $t0, attr  => [], 'foo';
method_ok $t1, attr  => [], undef;
method_ok $t2, other => [], 'foo';

done_testing;
