use 5.010;

{
	package Example::Role;
	use Moose::Role;
	use MooseX::RoleFor;	
	role_for 'Example::Blah', 'croak';
}

{
	package Example::Class;
	use Moose;
	with 'Example::Role';
}

{
	package main;
	use Moose::Util qw/apply_all_roles/;
	my $obj = Example::Class->new;
	apply_all_roles($obj, 'Example::Role');
}
