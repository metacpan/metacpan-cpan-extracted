use 5.008001;
use strict;
use warnings;

package MooseX::Enumeration::Meta::Attribute::Native::Trait::Enumeration;
our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Moose::Role;
with 'Moose::Meta::Attribute::Native::Trait';

use Module::Runtime qw( use_package_optimistically );

before _process_isa_option => sub
{
	my $class = shift;
	my ($name, $options) = @_;
	
	if ($options->{enum})
	{
		confess "Cannot supply both the 'isa' and 'enum' options"
			if $options->{isa};
		require MooseX::Enumeration;
		$options->{isa} = 'MooseX::Enumeration'
			-> _enum_type_implementation
			-> new( values => $options->{enum} );
	}
};

sub _helper_type { 'Str' }

around _check_helper_type => sub { 1 };

has enum => (is => 'ro', lazy => 1, builder => '_build_enum');

sub _build_enum
{
	my $meta = shift;
	
	my $enum;
	my $type = $meta->type_constraint;
	while (defined $type)
	{
		if ($type->isa('Type::Tiny::Enum')
		or  $type->isa('Moose::Meta::TypeConstraint::Enum'))
		{
			return $type->values;
		}
		$type = $type->parent;
	}
	
	confess "could not find values for enumeration";
}

around _canonicalize_handles => sub
{
	my $next = shift;
	my $self = shift;
	my $handles = $self->handles;
	
	return unless $handles;
	
	if (!ref $handles and $handles eq 1)
	{
		return map +("is_$_" => ["is", $_]), @{ $self->enum };
	}
	
	if (ref $handles eq 'ARRAY')
	{
		return map +($_ => [split /_/, $_, 2]), @$handles;
	}
	
	my %handles = $self->$next(@_);
	for my $h (values %handles)
	{
		next unless $h->[0] =~ /^(is|assign)_(\w+)$/;
		
		my @s = split /_/, shift(@$h), 2;
		unshift @$h, @s;
	}
	return %handles;
};

around _native_accessor_class_for => sub
{
	my $next = shift;
	my $self = shift;
	my ($suffix) = @_;
	
	my $role
		= 'MooseX::Enumeration::Meta::Method::Accessor::Native::'
		. $self->_native_type . '::'
		. $suffix;
	
	return Moose::Meta::Class->create_anon_class(
		superclasses => [ $self->accessor_metaclass, $self->delegation_metaclass ],
		roles        => [ use_package_optimistically($role) ],
		cache        => 1,
	 )->name;
};

1;
