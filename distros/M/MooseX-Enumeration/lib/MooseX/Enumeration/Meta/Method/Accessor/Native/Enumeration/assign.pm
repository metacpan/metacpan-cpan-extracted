use 5.008001;
use strict;
use warnings;

package MooseX::Enumeration::Meta::Method::Accessor::Native::Enumeration::assign;
our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Moose::Role;
with 'Moose::Meta::Method::Accessor::Native::Writer';

around _minimum_arguments => sub { 1 };
around _maximum_arguments => sub { 2 };

sub _potential_value
{
	my $self = shift;
	my $type = $self->associated_attribute->type_constraint;
	
	if ($self->associated_attribute->should_coerce)
	{
		my $type = $self->associated_attribute->type_constraint;
		$self->_eval_environment->{'$type'} = $type;
		return '$type->coerce($_[0])';
	}
	
	'$_[0]';
}

around _inline_return_value => sub
{
	# Technically speaking, we can't rely on the invocant
	# being called '$self'
	'$self';
};

around _inline_process_arguments => sub
{
	my $next = shift;
	my $self = shift;
	my ($inv, $slot_access) = @_;
	
	my $orig = $self->$next(@_);
	$orig = "" unless defined $orig;
	
	$self->_inline_check_allowed_transition($slot_access, 1) . $orig;
};

sub _inline_check_allowed_transition
{
	require B;
	require match::simple;
	
	my $self = shift;
	my ($slot_access, $allow) = @_;
	
	my $die = $self->_inline_allowed_transition_exception($slot_access);
	return "\$#_ < $allow or match::simple::match($slot_access, \$_[$allow]) or $die;";
}

sub _inline_allowed_transition_exception
{
	my $self = shift;
	my ($slot_access) = @_;
	
	my $name = B::perlstring($self->name);
	my $attr = B::perlstring($self->associated_attribute->name);
	my $tmpl = '"Method %s cannot be called when attribute %s has value %s, stopped"';
	
	return "Carp::confess(sprintf($tmpl, $name, $attr, $slot_access))";
}

around _generate_method => sub
{
	my $next = shift;
	my $self = shift;
	$self->$next(@_);
	
	my $inv = '$self';
	my @curried = @{ $self->curried_arguments };
	my $type = $self->associated_attribute->type_constraint;
	my $coerce = $self->associated_attribute->should_coerce;
	
	# Optimized accessor for one curried argument
	if ( @curried==1
	and !$coerce
	and not $self->associated_attribute->is_lazy
	and $self->_maximum_arguments==2
	and $self->_minimum_arguments==1 )
	{
		$type->assert_valid($curried[0]);
		
		my $slot_access = $self->_get_value($inv);
		
		require B;
		require Moose::Util;
		return sprintf(
			'sub { my %s = shift; %s if @_ > 1; %s; %s; %s }',
			$inv,
			"Moose::Util::throw_exception('MethodExpectsFewerArgs', 'method_name', 'assign', 'maximum_args', 2)",
			$self->_inline_check_allowed_transition($slot_access, 0),
			$self->_inline_set_new_value($inv, B::perlstring($curried[0]), $slot_access),
			$self->_inline_return_value($slot_access, 'for writer'),
		);
	}
	
	# Optimized accessor for two curried arguments
	if ( @curried==2
	and !$coerce
	and not $self->associated_attribute->is_lazy
	and $self->_maximum_arguments==2
	and $self->_minimum_arguments==1 )
	{
		$type->assert_valid($curried[0]);
		
		my $slot_access = $self->_get_value($inv);
		
		if ($type->check($curried[1]))
		{
			return sprintf(
				'sub { my %s = shift; %s if @_; return %s if %s eq %s; %s eq %s or %s; %s; %s }',
				$inv,
				"Moose::Util::throw_exception('MethodExpectsFewerArgs', 'method_name', 'assign', 'maximum_args', 2)",
				$inv,
				$slot_access,
				B::perlstring($curried[0]),
				$slot_access,
				B::perlstring($curried[1]),
				$self->_inline_allowed_transition_exception($slot_access),
				$self->_inline_set_new_value($inv, B::perlstring($curried[0]), $slot_access),
				$self->_inline_return_value($slot_access, 'for writer'),
			);
		}
		
		else
		{
			require match::simple;
			
			return sprintf(
				'sub { my %s = shift; %s if @_; return %s if %s eq %s; match::simple::match(%s, $curried[1]) or %s; %s; %s }',
				$inv,
				"Moose::Util::throw_exception('MethodExpectsFewerArgs', 'method_name', 'assign', 'maximum_args', 2)",
				$inv,
				$slot_access,
				B::perlstring($curried[0]),
				$slot_access,
				$self->_inline_allowed_transition_exception($slot_access),
				$self->_inline_set_new_value($inv, B::perlstring($curried[0]), $slot_access),
				$self->_inline_return_value($slot_access, 'for writer'),
			);
		}
	}

	# Otherwise we should trust the default implementation
	# from Moose::Meta::Method::Accessor::Native::Reader.
	$self->$next(@_);
};

1;
