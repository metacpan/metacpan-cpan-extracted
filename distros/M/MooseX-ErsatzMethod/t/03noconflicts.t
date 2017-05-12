use strict;
use warnings;
use Test::More tests => 6;

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
	use MooseX::ErsatzMethod;
	ersatz foo => sub { 2 };
}

BEGIN {
	package Local::Test::Role3;
	no thanks;
	use Moose::Role;
	with qw(
		Local::Test::Role1
		Local::Test::Role2
	);
}

BEGIN {
	package Local::Test::Class::WithRole1;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role1
	);
}

BEGIN {
	package Local::Test::Class::WithRole1AndRole2;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role1
		Local::Test::Role2
	);
}

BEGIN {
	package Local::Test::Class::WithRole1ThenRole2;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role1
	);
	with qw(
		Local::Test::Role2
	);
}

BEGIN {
	package Local::Test::Class::WithRole3;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role3
	);
}

BEGIN {
	package Local::Test::Class::WithRole1AndRole3;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role1
		Local::Test::Role3
	);
}

BEGIN {
	package Local::Test::Class::WithRole1ThenRole3;
	no thanks;
	use Moose;
	with qw(
		Local::Test::Role1
	);
	with qw(
		Local::Test::Role3
	);
}

ok(
	$_->new->foo == 1,
	$_,
) for qw(
	Local::Test::Class::WithRole1
);

ok(
	$_->new->foo == 1 || $_->new->foo == 2,
	$_,
) for qw(
	Local::Test::Class::WithRole1AndRole2
	Local::Test::Class::WithRole1ThenRole2
	Local::Test::Class::WithRole3
	Local::Test::Class::WithRole1AndRole3
	Local::Test::Class::WithRole1ThenRole3
);