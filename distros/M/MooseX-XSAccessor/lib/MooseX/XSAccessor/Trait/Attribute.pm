package MooseX::XSAccessor::Trait::Attribute;

use 5.008;
use strict;
use warnings;

use Class::XSAccessor 1.09 ();
use Scalar::Util qw(reftype);
use B qw(perlstring);

BEGIN {
	$MooseX::XSAccessor::Trait::Attribute::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::XSAccessor::Trait::Attribute::VERSION   = '0.009';
}

# Map Moose terminology to Class::XSAccessor options.
my %cxsa_opt = (
	accessor   => "accessors",
	reader     => "getters",
	writer     => "setters",
);

$cxsa_opt{predicate} = "exists_predicates"
	if Class::XSAccessor->VERSION > 1.16;

use Moose::Role;

sub accessor_is_simple
{
	my $self = shift;
	return !!0 if $self->has_type_constraint && $self->type_constraint ne "Any";
	return !!0 if $self->should_coerce;
	return !!0 if $self->has_trigger;
	return !!0 if $self->is_weak_ref;
	return !!0 if $self->is_lazy;
	return !!0 if $self->should_auto_deref;
	!!1;
}

sub reader_is_simple
{
	my $self = shift;
	return !!0 if $self->is_lazy;
	return !!0 if $self->should_auto_deref;
	!!1;
}

sub writer_is_simple
{
	my $self = shift;
	return !!0 if $self->has_type_constraint && $self->type_constraint ne "Any";
	return !!0 if $self->should_coerce;
	return !!0 if $self->has_trigger;
	return !!0 if $self->is_weak_ref;
	!!1;
}

sub predicate_is_simple
{
	my $self = shift;
	!!1;
}

# Class::XSAccessor doesn't do clearers
sub clearer_is_simple
{
	!!0;
}

after install_accessors => sub {
	my $self = shift;
	
	my $slot      = $self->name;
	my $class     = $self->associated_class;
	my $classname = $class->name;
	
	# Don't attempt to do anything with instances that are not blessed hashes.
	my $is_hash = reftype($class->get_meta_instance->create_instance) eq q(HASH);
	return unless $is_hash && $class->get_meta_instance->is_inlinable;
	
	# Use inlined get method as a heuristic to detect weird shit.
	my $inline_get = $self->_inline_instance_get('$X');
	return unless $inline_get eq sprintf('$X->{%s}', perlstring $slot);
	
	# Detect use of MooseX::Attribute::Chained
	my $is_chained = $self->does('MooseX::Traits::Attribute::Chained');
	
	# Detect use of MooseX::LvalueAttribute
	my $is_lvalue = $self->does('MooseX::LvalueAttribute::Trait::Attribute');
	
	for my $type (qw/ accessor reader writer predicate clearer /)
	{
		# Only accelerate methods if CXSA can deal with them
		next unless exists $cxsa_opt{$type};
		
		# Only accelerate methods that exist!
		next unless $self->${\"has_$type"};
		
		# Check to see they're simple (no type constraint checks, etc)
		next unless $self->${\"$type\_is_simple"};
		
		my $methodname = $self->$type;
		my $metamethod = $class->get_method($methodname);
		
		# Perform the actual acceleration
		if ($type eq 'accessor' and $is_lvalue)
		{
			next if $is_chained;
			next if !$MooseX::XSAccessor::LVALUE;
			
			"Class::XSAccessor"->import(
				class             => $classname,
				replace           => 1,
				lvalue_accessors  => +{ $methodname => $slot },
			);
		}
		else
		{
			"Class::XSAccessor"->import(
				class             => $classname,
				replace           => 1,
				chained           => $is_chained,
				$cxsa_opt{$type}  => +{ $methodname => $slot },
			);
		}
		
		# Naughty stuff!!!
		# We've overwritten a Moose-generated accessor, so now we need to
		# inform Moose's metathingies about the new coderef.
		# $metamethod->body is read-only, so dive straight into the blessed
		# hash.
		no strict "refs";
		$metamethod->{"body"} = \&{"$classname\::$methodname"};
	}
	
	return;
};

1;

__END__

=pod

=for stopwords booleans

=encoding utf-8

=head1 NAME

MooseX::XSAccessor::Trait::Attribute - get the Class::XSAccessor effect for a single attribute

=head1 SYNOPSIS

   package MyClass;
   
   use Moose;
   
   has foo => (
      traits => ["MooseX::XSAccessor::Trait::Attribute"],
      ...,
   );
   
   say __PACKAGE__->meta->get_attribute("foo")->accessor_is_simple;

=head1 DESCRIPTION

Attributes with this trait have the following additional methods, which
each return booleans:

=over

=item C<< accessor_is_simple >>

=item C<< reader_is_simple >>

=item C<< writer_is_simple >>

=item C<< predicate_is_simple >>

=item C<< clearer_is_simple >>

=back

What is meant by simple? Simple enough for L<Class::XSAccessor> to take
over the accessor's duties.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-XSAccessor>.

=head1 SEE ALSO

L<MooseX::XSAccessor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

