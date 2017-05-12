use Test::More tests => 4;
use MooseX::DeclareX
	keywords  => [qw( class interface )],
	plugins   => [qw( method test_case )],
	;

interface DatabaseAPI::ReadOnly
{
	test_case this_should_pass { 1 }
	requires 'select';
}

interface DatabaseAPI::ReadWrite
	extends DatabaseAPI::ReadOnly
{
	test_case this_should_fail { 0 }
	requires 'insert';
	requires 'update';
	requires 'delete';
}

class Database::MySQL
	with DatabaseAPI::ReadWrite
{
	method insert { 1 }
	method select { 1 }
	method update { 1 }
	method delete { 1 }
}

ok(
	Database::MySQL::->DOES('DatabaseAPI::ReadOnly'),	
);

ok(
	Database::MySQL::->DOES('DatabaseAPI::ReadWrite'),
);

my $x = Database::MySQL::->new;

ok(
	DatabaseAPI::ReadOnly->meta->test_implementation( $x ),
);

ok not(
	DatabaseAPI::ReadWrite->meta->test_implementation( $x ),
);
