use 5.006;
use strict;
use warnings;

BEGIN { if ($] < 5.010000) { require UNIVERSAL::DOES } };

package MooX::Traits;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Role::Tiny;

sub _trait_namespace
{
	();
}

sub with_traits
{
	my $class = shift;
	return $class unless @_;
	
	require MooX::Traits::Util;
	MooX::Traits::Util::new_class_with_traits($class, @_);
}

sub new_with_traits
{
	my $class = shift;
	my (%args, $pass_as_ref);
	if (@_==1 and ref($_[0]) eq 'HASH')
	{
		%args = %{$_[0]};
		$pass_as_ref = !!1;
	}
	else
	{
		%args = @_;
		$pass_as_ref = !!0;
	}
	
	my $traits_arr = delete($args{traits}) || [];
	my @traits     = ref($traits_arr) ? @$traits_arr : $traits_arr;
	$class->with_traits(@traits)->new( $pass_as_ref ? \%args : %args );
}

1;

__END__

=pod

=encoding utf-8

=for stopwords MooseX MouseX prepend

=head1 NAME

MooX::Traits - automatically apply roles at object creation time

=head1 SYNOPSIS

Given some roles:

   package Role;
   use Moo::Role;
   has foo => ( is => 'ro', required => 1 );

And a class:

   package Class;
   use Moo;
   with 'MooX::Traits';

Apply the roles to the class:

   my $class = Class->with_traits('Role');

Then use your customized class:

   my $object = $class->new( foo => 42 );
   $object->isa('Class'); # true
   $object->does('Role'); # true
   $object->foo; # 42

=head1 DESCRIPTION

Was any of the SYNOPSIS unexpected? Basically, this module is the same
thing as L<MooseX::Traits> and L<MouseX::Traits>, only for L<Moo>.
I<Quelle surprise>, right?

=head2 Methods

=over

=item C<< $class->with_traits( @traits ) >>

Return a new class name with the traits applied.

=item C<< $class->new_with_traits(%args, traits => \@traits) >>

C<new_with_traits> can also take a hashref, e.g.:

   my $instance = $class->new_with_traits({ traits => \@traits, foo => 'bar' });

This method exists for compatibility with the MooseX and MouseX
equivalents of this module, but generally speaking you should prefer
to use C<with_traits>.

=item C<< $class->_trait_namespace >>

This returns undef, but you can override it in your class to
automatically prepend a namespace to supplied traits.

This differs slightly from the MooseX and MouseX versions of this
module which have C<_trait_namespace> as an attribute instead of
a method.

=back

=head2 Compatibility

Although called MooX::Traits, this module actually uses L<Role::Tiny>,
so doesn't really require L<Moo>. If you use it in a non-Moo class,
you should be able to safely consume any Role::Tiny-based traits.

If you use it in a Moo class, you should also be able to consume
Moo::Role-based traits and Moose::Role-based traits.

L<Package::Variant> and L<MooseX::Role::Parameterized> roles should be
usable; just provide a hashref of arguments:

   $class->with_traits( $param_role => \%args )->new( ... )

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Traits>.

=head1 SEE ALSO

L<MooX::Traits::Util>.

L<Moo::Role>,
L<Role::Tiny>.

L<MooseX::Traits>,
L<MouseX::Traits>.

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

