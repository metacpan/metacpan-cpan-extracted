use 5.008001;
use strict;
use warnings;

package MooX::XSConstructor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003001';

use Moo 2.004000 ();
use Hook::AfterRuntime;

# Options that either XSCON can handle, or have no effect on the
# constructor at all.
my $safe_spec = qr/\A(
	index |
	is | reader | writer | accessor | predicate | clearer |
	handles | handles_via |
	init_arg | required |
	isa | coerce |
	builder | default | lazy |
	trigger |
	weak_ref |
	documentation
)\z/x;

# Options that have no effect on the constructor at all, but need
# to be deleted so they don't confuse XSCON.
my $delete_from_spec = qr/\A(
	index |
	is | reader | writer | accessor | predicate | clearer |
	handles | handles_via |
	documentation
)\z/x;

sub is_suitable_class {
	my ( $self, $klass ) = @_;
	
	return unless Moo->is_class( $klass );
	
	my $constructor_maker = Moo->_constructor_maker_for( $klass );
	do {
		# If the class's constructor generator is Method::Generate::Constructor,
		# then we can predict its behaviour. If it's something unknown, we
		# don't know what it might do internally, so cannot safely replace
		# it with XSCON.
		my @allowed_constructor_makers = (
			'Method::Generate::Constructor',
		);
		
		# This is one trait that might be applied to the constructor maker
		# which we *know* we are able to handle.
		if ( $INC{'MooX/StrictConstructor/Role/Constructor/Late.pm'} ) {
			require Role::Tiny;
			require Method::Generate::Constructor;
			my $trait = 'MooX::StrictConstructor::Role::Constructor::Late';
			push @allowed_constructor_makers, map {
				Role::Tiny->create_class_with_roles( $_, $trait );
			} @allowed_constructor_makers;
		}

		my $maker_class = ref $constructor_maker;
		return unless grep { $maker_class eq $_ } @allowed_constructor_makers;
	};
	
	# Preliminary sanity check for accessor maker, because it is
	# used by the constructor genmerator to generate attribute set
	# statements. Just check it's theoretically sound here, but we
	# still need to check it for each attribute.
	my $accessor_maker = Moo->_accessor_maker_for( $klass );
	do {
		my $generated = $accessor_maker->_generate_core_set( q{$XXX}, 'yyy', {}, q{"zzz"} );
		my $expected  = q{$XXX->{"yyy"} = "zzz"};
		return if $generated ne $expected;
	};
	
	# Loop through attributes...
	my %spec = %{ $constructor_maker->all_attribute_specs };
	my @attributes = sort { $spec{$a}{index} <=> $spec{$b}{index} } keys %spec;
	for my $attr (@attributes) {
		# Check they don't have any options we don't understand.
		if (my @unsafe = grep { $_ !~ $safe_spec } keys %{ $spec{$attr} }) {
			return;
		}
		
		# Check that the accessor maker generates a predictable
		# attribute set statement for this attribute.
		require B;
		my $generated = $accessor_maker->_generate_core_set( q{$XXX}, $attr, $spec{$attr}, q{"zzz"} );
		my $expected  = sprintf q{$XXX->{%s} = "zzz"}, B::perlstring($attr);
		return if $generated ne $expected;
	}
	
	# If we got this far, we're good.
	return "yay!";
}

# Called by the import method.
sub setup_for {
	my ( $self, $klass ) = @_;
	
	return unless $self->is_suitable_class( $klass );
	
	# Get attribute specs
	my $maker = Moo->_constructor_maker_for( $klass );
	my %spec  = %{ $maker->all_attribute_specs };
	
	# Transform it into arguments which XSCON can handle
	my @args =
		map {
			my $slot = $_;
			my %xs_spec = %{ $spec{$slot} };
			for my $k ( keys %xs_spec ) {
				delete $xs_spec{$k} if $k =~ $delete_from_spec;
			}
			if ( $xs_spec{lazy} ) {
				delete $xs_spec{$_} for qw/ lazy builder default /;
			}
			( $slot => \%xs_spec );
		}
		sort { $spec{$a}{index} <=> $spec{$b}{index} }
		keys %spec;
	
	$maker->DOES( 'MooX::StrictConstructor::Role::Constructor::Late' )
		and push @args, '!!';

	# Keep track of old constructor, just in case.
	my $old = $klass->can( 'new' );
	
	# Call XSCON to replace the existing constructor method
	my $ok = eval {
		require Class::XSConstructor;
		Class::XSConstructor->VERSION( 0.018001 );
		local $Class::XSConstructor::REDEFINE = !!1;
		Class::XSConstructor->import( [ $klass, 'new' ], @args );
		1;
	};
	
	# If there was a failure, restore old constructor.
	if ( not $ok ) {
		no strict 'refs';
		no warnings 'redefine';
		*{"${klass}::new"} = $old;
		return;
	}
	
	if ( $klass->can('DEMOLISH') ) {
		require Class::XSDestructor;
		local $Class::XSDestructor::REDEFINE = !!1;
		Class::XSDestructor->import( [ $klass, 'DESTROY' ] );
	}
	
	return $klass;
}

sub import {
	my $self = shift;
	my $caller = caller;
	after_runtime { $self->setup_for( $caller ) };
}

sub is_xs  {
	require B;
	!! B::svref_2object( shift )->XSUB;
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

MooX::XSConstructor - glue between Moo and Class::XSConstructor

=head1 SYNOPSIS

  package Foo;
  use Moo;
  use MooX::XSConstructor;
  
  # do normal Moo stuff here

=head1 DESCRIPTION

MooX::XSConstructor will look at your class attributes, and see if it
could be built using L<Class::XSConstructor>. If your class seems too
complicated, it is a no-op. If your class is simple enough, you will
hopefully get a faster constructor.

B<< Which features are too complicated for MooX::XSConstructor to handle? >>

=over

=item *

Any MooX extensions which cause your constructor generator to be changed
from the default of L<Method::Generate::Constructor>.

Luckily hardly any extensions exist which do that. L<MooX::StrictConstructor>
is one fairly popular extension that does, and we support that as a special
case, but only if you use it with the C<< -late >> option.

=item *

Any MooX extensions which cause your accessor generator to be changed
in such a way that it generates the "core set" to be different from the
standard one.

Basically what this means is that by standard, Moo attributes can be
set using C<< $object->{"attribute_name"} = VALUE >>, but if you've
got a MooX extension that changes that, MooX::StrictConstructor
will bail out.

This includes: L<MooX::InsideOut> and L<MooX::AttributeFilter>.

=item *

If any of your attributes, including inherited ones, are defined using
options other than: C<is>, C<reader>, C<writer>, C<accessor>, C<predicate>,
C<clearer>, C<handles>, C<handles_via>, C<init_arg>, C<required>, C<isa>,
C<coerce>, C<builder>, C<default>, C<lazy>, C<trigger>, C<weak_ref>, and
C<documentation>.

Certain extensions like L<MooX::Should> or L<MooX::Aliases> do define
other options for attributes, but also clean up after themselves, deleting
the additional options from the attribute spec before MooX::StrictConstructor
can see them. So they are okay!

=back

=head2 API

Normal usage is just to C<< use MooX::XSConstructor >> in your Moo class.
However, an API is provided.

=over

=item C<< MooX::XSConstructor->setup_for( $class ) >>

Run setup for the given class, replacing its constructor with a faster
XS constructor. Do not call the C<setup_for> method until you are sure
the class has finished compiling, with all attributes already having
been added (using C<has> or role composition).

Returns the class's name if it successfully replaced the constructor.
Returns undef otherwise.

=item C<< MooX::XSConstructor->is_suitable_class( $class ) >>

Checks that the class is a suitable Moo class for replacing the
constructor of. C<setup_for> calls this, so you don't actually
need to do this check yourself too.

=item C<< MooX::XSConstructor::is_xs( $coderef ) >>

Returns true if the coderef is implemented with XS. Can be used to
double-check C<setup_for> was successful if you don't trust it
for some reason.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-XSConstructor>.

=head1 SEE ALSO

L<Moo>, L<Class::XSConstructor>, L<MooseX::XSConstructor>, L<Marlin>.

You may also be interested in L<Class::XSAccessor>. Moo already includes
all the glue to interface with that, so a MooX module like this one isn't
necessary.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018, 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
