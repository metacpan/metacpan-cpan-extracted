use 5.008001;
use strict;
use warnings;

package MooseX::Enumeration::Meta::Method::Accessor::Native::Enumeration::is;
our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Moose::Role;
with 'Moose::Meta::Method::Accessor::Native::Reader';

around _minimum_arguments => sub { 1 };
around _maximum_arguments => sub { 1 };

sub _return_value
{
	require match::simple;
	
	my $self = shift;
	my ($slot_access) = @_;
	# Note that $_[0] comes from @curried which has been closed over
	# and contains the string we need to compare against.
	return "match::simple::match($slot_access, \$_[0])";
}

around _generate_method => sub
{
	my $next = shift;
	my $self = shift;
	
	my @curried = @{ $self->curried_arguments };
	
	# If everything is as expected...
	if ( @curried==1
	and defined $curried[0]
	and not ref $curried[0]
	and not $self->associated_attribute->is_lazy
	and $self->_maximum_arguments==1
	and $self->_minimum_arguments==1 )
	{
		my $type = $self->associated_attribute->type_constraint;
		$type->assert_valid($curried[0]);
		
		# ... then provide a highly optimized accessor.
		require B;
		require Moose::Util;
		return sprintf(
			'sub { %s if @_ > 1; no warnings qw(uninitialized); %s eq %s }',
			"Moose::Util::throw_exception('MethodExpectsFewerArgs', 'method_name', 'is', 'maximum_args', 1)",
			$self->_get_value('$_[0]'),
			B::perlstring($curried[0]),
		);
	}
	
	# Otherwise we should trust the default implementation
	# from Moose::Meta::Method::Accessor::Native::Reader.
	$self->$next(@_);
};

1;
