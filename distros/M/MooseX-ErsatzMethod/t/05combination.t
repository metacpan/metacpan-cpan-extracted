use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
	package Local::Test::Role1;
	no thanks;
	use Moose::Role;
	use MooseX::ErsatzMethod;
	ersatz foo => sub { 1 };
};

BEGIN {
	package Local::Test::Role2;
	no thanks;
	use Moose::Role;
	sub foo { 2 }
};

ok eval {
	package Local::Test::Class1;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role1
		Local::Test::Role2
	);
	1;
};

is(
	Local::Test::Class1->new->foo,
	2,
);

ok eval {
	package Local::Test::Class2;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role2
		Local::Test::Role1
	);
	1;
};

is(
	Local::Test::Class2->new->foo,
	2,
);
