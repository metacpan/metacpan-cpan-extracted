package MooseX::ClosedHash::Meta::Class;

BEGIN {
	$MooseX::ClosedHash::Meta::Class::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ClosedHash::Meta::Class::VERSION   = '0.003';
}

use Moose::Role;
use Moose::Util qw(does_role);

before superclasses => sub
{
	my $meta = shift;
	for (@_)
	{
		next if ref;
		confess "MooseX::ClosedHash cannot extend a non-MooseX::ClosedHash class"
			unless does_role(Class::MOP::class_of($_), __PACKAGE__);
	}
};

1;

