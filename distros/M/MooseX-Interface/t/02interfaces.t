use Test::More tests => 4;

{
	package DatabaseAPI::ReadOnly;
	use MooseX::Interface;
	requires 'select';
	one;
}

{
	package DatabaseAPI::ReadWrite;
	use MooseX::Interface;
	extends 'DatabaseAPI::ReadOnly';
	requires 'insert';
	requires 'update';
	requires 'delete';
	one;
}

{
	package Database::MySQL;
	use Moose;
	with 'DatabaseAPI::ReadWrite';
	sub insert { 1 }
	sub select { 1 }
	sub update { 1 }
	sub delete { 1 }
}

is_deeply(
	[ sort map { $_->name } DatabaseAPI::ReadOnly->meta->get_required_method_list ],
	[qw( select )],
	"requires - direct",
);

is_deeply(
	[ sort map { $_->name } DatabaseAPI::ReadWrite->meta->get_required_method_list ],
	[qw( delete insert select update )],
	"requires - indirect",
);

ok(
	Database::MySQL::->DOES('DatabaseAPI::ReadWrite'),
	"DOES - direct implementation",
);

ok(
	Database::MySQL::->DOES('DatabaseAPI::ReadOnly'),
	"DOES - indirect implementation",
);
