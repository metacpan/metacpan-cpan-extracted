use strict;
use warnings;
use Test::More tests => 2;

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
	requires 'foo';
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
