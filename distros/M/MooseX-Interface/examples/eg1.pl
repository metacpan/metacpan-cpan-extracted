use 5.010;
use lib "../lib";

package DatabaseAPI::ReadOnly
{
	use MooseX::Interface;
	requires 'select';
}

package DatabaseAPI::ReadWrite
{
	use MooseX::Interface;
	extends 'DatabaseAPI::ReadOnly';
	requires 'insert';
	requires 'update';
	requires 'delete';
}

package Database::MySQL
{
	use Moose;
	with 'DatabaseAPI::ReadWrite';
	sub insert { ... }
	sub select { ... }
	sub update { ... }
	sub delete { ... }
}

say Database::MySQL::->DOES('DatabaseAPI::ReadOnly');   # true
say Database::MySQL::->DOES('DatabaseAPI::ReadWrite');  # true
