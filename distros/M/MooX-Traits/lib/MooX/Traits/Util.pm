use 5.006;
use strict;
use warnings;

BEGIN { if ($] < 5.010000) { require UNIVERSAL::DOES } };

package MooX::Traits::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Exporter::Shiny qw(
	new_class_with_traits
	new_class_with_traits_one_by_one
);

my @keepsies;
my $parameterize_role = sub
{
	my ($class, $trait, $params) = @_;
	return $trait unless @_ == 3;
	
	require Module::Runtime;
	Module::Runtime::use_package_optimistically($trait);
	
	if ( $INC{'MooseX/Role/Parameterized.pm'} )
	{
		require Moose::Util;
		my $meta = Moose::Util::find_meta($trait);
		if ($meta->can('generate_role'))
		{
			my $generated = $meta->generate_role(parameters => $params);
			push @keepsies, $generated; # prevent cleanup
			return $generated->name;
		}
	}
	
	if ( $trait->can("make_variant") )
	{
		require Package::Variant;
		return "Package::Variant"->build_variant_of(
			$trait,
			ref($params) eq q(ARRAY) ? @$params :
				ref($params) eq q(HASH) ? %$params :
				$$params,
		);
	}
	
	return $trait;
};

my $looks_like_params = sub
{
	my $thing = $_[0];
	return !!0 if not ref $thing;
	require Scalar::Util;
	return !!0 if Scalar::Util::blessed($thing);
	return !!1;
};

sub resolve_traits
{
	my ($class, @args) = @_;
	
	my $ns = $class->DOES('MooX::Traits') ? $class->_trait_namespace : undef;
	$ns = defined($ns) ? "$ns\::" : "";
	
	my @traits;
	while (@args)
	{
		my $trait = shift(@args);
		$trait = $trait =~ /\A\+(.+)\z/ ? $1 : "$ns$trait";
		
		push @traits => (
			$looks_like_params->($args[0])
				? $parameterize_role->($class, $trait, shift(@args))
				: $trait
		);
	}
	return @traits;
}

my $toolage = sub
{
	my $class = shift;
	
	if ($INC{"Moo.pm"} and $Moo::MAKERS{$class}{is_class})
	{
		require Moo::Role;
		return "Moo::Role";
	}
	
	if ($INC{"Moo/Role.pm"})
	{
		return "Moo::Role";
	}
	
	"Role::Tiny";
};

sub new_class_with_traits
{
	my ($class, @traits) = @_;
	$class->$toolage->create_class_with_roles(
		$class,
		resolve_traits($class, @traits),
	);
}

sub new_class_with_traits_one_by_one
{
	my ($class, @traits) = @_;
	while (@traits)
	{
		my @trait = shift(@traits);
		push @trait, shift(@traits)
			if $looks_like_params->($traits[0]);
		$class = new_class_with_traits($class, @trait);
	}
	return $class;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords MooseX MouseX prepend metaclass

=head1 NAME

MooX::Traits::Util - non-role alternative to MooX::Traits

=head1 SYNOPSIS

Given some roles:

   package Role;
   use Moo::Role;
   has foo => ( is => 'ro', required => 1 );

And a class:

   package Class;
   use Moo;

Apply the roles to the class:

   use MooX::Traits::Util -all;
   
   my $class = new_class_with_traits('Class', 'Role');

Then use your customized class:

   my $object = $class->new( foo => 42 );
   $object->isa('Class'); # true
   $object->does('Role'); # true
   $object->foo; # 42

=head1 DESCRIPTION

This module provides the functionality of L<MooX::Traits>, but it's an
exporter rather than a role.

It's inspired by, but not compatible with L<MooseX::Traits::Util>. The
latter module is undocumented, and it's not entirely clear whether it's
intended to be consumed by end-users, or is an entirely internal API.

This module exports nothing by default.

=head2 Functions

=over

=item C<< new_class_with_traits( $class, @traits ) >>

Return a new class name with the traits applied.

This function is not quite compatible with the C<new_class_with_traits>
function provided by L<MooseX::Traits::Util>, in that the latter will
return a metaclass object.

This function can be exported.

=item C<< new_class_with_traits_one_by_one( $class, @traits ) >>

Rather than applying the the traits simultaneously, the traits are
applied one at a time. It is roughly equivalent to:

   use List::Util qw(reduce);
   use MooX::Traits::Util qw( new_class_with_traits );
   
   my $class  = ...;
   my @traits = ...;
   my $new    = reduce { new_class_with_traits($a, $b) } $class, @traits;

Applying traits one by one has implications for method modifiers, and
for method conflict detection. B<< Use with caution. >>

There is no equivalent functionality in L<MooseX::Traits::Util>.

This function can be exported.

=item C<< resolve_traits( $class, @traits ) >>

This function returns a list of traits, but does not apply them to the
class. It honours the class' C<_trait_namespace> method (but only if
the class does the MooX::Traits role) and handles parameter hashrefs
for parameterizable roles. (That is, parameters are applied to the
role, and the list of traits returned by the function includes the
result of that application instead of including the original hashref.)

This function is not quite compatible with the C<resolve_traits>
function provided by L<MooseX::Traits::Util>, in that the latter will
not handle parameter hashrefs, trusting Moose to do that.

This function I<cannot> be exported.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Traits>.

=head1 SEE ALSO

L<MooX::Traits>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

