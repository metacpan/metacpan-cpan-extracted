use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
	package Local::Test::Role;
	no thanks;
	use Moose::Role;
	use MooseX::ErsatzMethod;
	ersatz foo => sub { +__PACKAGE__ };
}

BEGIN {
	package Local::Test::Class::NoImplementation;
	no thanks;
	use Moose;
	with qw(Local::Test::Role);
}

BEGIN {
	package Local::Test::Class::WithImplementation;
	no thanks;
	use Moose;
	with qw(Local::Test::Role);
	sub foo { +__PACKAGE__ }
}

BEGIN {
	package Local::Test::Class::BaseClass;
	no thanks;
	use Moose;
	sub foo { +__PACKAGE__ }
}

BEGIN {
	package Local::Test::Class::InheritedImplementation;
	no thanks;
	use Moose;
	extends qw(Local::Test::Class::BaseClass);
	with qw(Local::Test::Role);
}

is(
	Local::Test::Class::NoImplementation->new->foo,
	'Local::Test::Role',
	'class which provides no implementation gets ersatz implementation',
);

is(
	Local::Test::Class::WithImplementation->new->foo,
	'Local::Test::Class::WithImplementation',
	'class which provides an implementation keeps it',
);

is(
	Local::Test::Class::InheritedImplementation->new->foo,
	'Local::Test::Class::BaseClass',
	'class which inherits an implementation keeps it',
);
