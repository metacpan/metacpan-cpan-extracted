use Test::More tests => 16;
use Moose::Util qw(apply_all_roles);

{
	package Local::Role1;
	use Moose::Role;
}

{
	package Local::Role2;
	use Moose::Role;
	use MooseX::RoleFor;
	role_for 'Local::Class', 'croak';
}

{
	package Local::Role3;
	use Moose::Role;
	use MooseX::RoleFor;
	role_for 'Local::Role1', 'croak';
}

{
	package Local::Class;
	use Moose;
}

{
	package Local::Class::Sub;
	use Moose;
	extends 'Local::Class';
}

{
	package Local::Other;
	use Moose;
}

{
	package Local::Another;
	use Moose;
	with 'Local::Role1';
}

sub successful
{
	my ($class, $role) = @_;
	eval { apply_all_roles($class->new, $role); 1 } or 0;
}

# 1-4
ok successful('Local::Class', 'Local::Role1');
ok successful('Local::Class', 'Local::Role2');
ok not successful('Local::Class', 'Local::Role3');
ok successful('Local::Class', 'Local::Role1', 'Local::Role3');

# 5-8
ok successful('Local::Class::Sub', 'Local::Role1');
ok successful('Local::Class::Sub', 'Local::Role2');
ok not successful('Local::Class::Sub', 'Local::Role3');
ok successful('Local::Class::Sub', 'Local::Role1', 'Local::Role3');

# 9-12
ok successful('Local::Other', 'Local::Role1');
ok not successful('Local::Other', 'Local::Role2');
ok not successful('Local::Other', 'Local::Role3');
ok successful('Local::Other', 'Local::Role1', 'Local::Role3');

# 13-16
ok successful('Local::Another', 'Local::Role1');
ok not successful('Local::Another', 'Local::Role2');
ok successful('Local::Another', 'Local::Role3');
ok successful('Local::Another', 'Local::Role1', 'Local::Role3');

