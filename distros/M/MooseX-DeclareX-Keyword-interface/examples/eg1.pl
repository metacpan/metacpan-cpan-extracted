use 5.010;
use MooseX::DeclareX
	keywords  => [qw( class interface )],
	plugins   => [qw( method test_case )],
	;

interface DatabaseAPI::ReadOnly
{
	test_case silly { 1 }
	requires 'select';
}

interface DatabaseAPI::ReadWrite
	extends DatabaseAPI::ReadOnly
{
	test_case sausage { 0 }
	requires 'insert';
	requires 'update';
	requires 'delete';
}

class Database::MySQL
	with DatabaseAPI::ReadWrite
{
	method insert { ... }
	method select { ... }
	method update { ... }
	method delete { ... }
}

say Database::MySQL::->DOES('DatabaseAPI::ReadOnly');   # true
say Database::MySQL::->DOES('DatabaseAPI::ReadWrite');  # true

my $x = Database::MySQL::->new;
say DatabaseAPI::ReadOnly->meta->test_implementation( $x ); # true
say DatabaseAPI::ReadWrite->meta->test_implementation( $x ); # false
