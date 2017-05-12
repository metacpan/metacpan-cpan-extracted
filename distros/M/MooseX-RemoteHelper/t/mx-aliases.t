use strict;
use warnings;
use Test::More;
use Test::Requires qw( MooseX::Aliases );

{
	package Test0;
	use Moose;
	use MooseX::RemoteHelper;
	use MooseX::Aliases;

	has attr => (
		isa         => 'Str',
		is          => 'ro',
		remote_name => 'Attribute',
		alias       => 'attribute',
		required    => 1,
	);
}
{
	package Test1;
	use Moose;
	extends 'Test0';
}

new_ok 'Test0' => [{ Attribute => 1 }];
new_ok 'Test0' => [{ attribute => 1 }];
new_ok 'Test1' => [{ Attribute => 1 }];
new_ok 'Test1' => [{ attribute => 1 }];

done_testing;
