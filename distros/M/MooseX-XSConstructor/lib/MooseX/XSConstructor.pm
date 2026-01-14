use 5.008008;
use strict;
use warnings;

package MooseX::XSConstructor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001000';

use Moose 2.2200 ();
use Moose::Util ();
use Hook::AfterRuntime;

# Options that either XSCON can handle, or have no effect on the
# constructor at all.
my $safe_spec = qr/\A(
	index |
	is | reader | writer | accessor | predicate | clearer |
	handles | handles_via | traits |
	init_arg | required | alias |
	isa | coerce |
	builder | default | lazy |
	trigger |
	weak_ref |
	auto_deref |
	definition_context | associated_class | associated_methods | insertion_order | name | type_constraint |
	documentation
)\z/x;

my $safe_traits = qr/\A(
	MooseX::StrictConstructor::Trait::Class |
	MooseX::Aliases::Meta::Trait::Class |
	MooseX::UndefTolerant::Class
)\z/x;

sub is_suitable_class {
	my ( $self, $klass ) = @_;
	
	my $metaclass = Moose::Util::find_meta( $klass );
	return unless $metaclass->constructor_class eq 'Moose::Meta::Method::Constructor';
	return unless $metaclass->destructor_class eq 'Moose::Meta::Method::Destructor';
	return unless $metaclass->instance_metaclass eq 'Moose::Meta::Instance';
	
	my @metaclass_traits =
		map { $_->name }
		eval { $metaclass->meta->calculate_all_roles };
	return if grep { $_ !~ $safe_traits } @metaclass_traits;
	
	for my $attr ( $metaclass->get_all_attributes ) {
		
		my @bad = grep { $_ !~ $safe_spec } keys %$attr;
		return if @bad;
		
		require B;
		my $generated = $attr->_inline_instance_set(q{$XXX}, q{$YYY});
		my $expected  = sprintf q{%s->{%s} = %s}, q{$XXX}, B::perlstring($attr->name), q{$YYY};
		return if $generated ne $expected;
	}
	
	return "I assume so";
}

sub setup_for {
	my ( $self, $klass ) = @_;
	
	return unless $self->is_suitable_class( $klass );
	
	my $metaclass = Moose::Util::find_meta( $klass );
	
	# Transform it into arguments which XSCON can handle
	my @args =
		map {
			my $attr = $_;
			my $slot = $attr->name;
			my %xs_spec = ();
			$xs_spec{required} = 1 if $attr->is_required;
			$xs_spec{weak_ref} = 1 if $attr->is_weak_ref;
			$xs_spec{default}  = $attr->default if $attr->has_default && !$attr->is_lazy;
			$xs_spec{builder}  = $attr->builder if $attr->has_builder && !$attr->is_lazy;
			$xs_spec{init_arg} = $attr->init_arg;
			$xs_spec{trigger}  = $attr->trigger if $attr->has_trigger;
			if ( $attr->has_type_constraint ) {
				$xs_spec{isa}      = $attr->type_constraint;
				$xs_spec{coerce}   = !!$attr->should_coerce;
			}
			$xs_spec{undef_tolerant} = 1
				if Moose::Util::does_role( $attr, 'MooseX::UndefTolerant::Attribute' );
			$xs_spec{alias} = $attr->alias
				if $attr->can('has_alias') && $attr->has_alias;
			( $slot => \%xs_spec );
		}
		$metaclass->get_all_attributes;
	
	Moose::Util::does_role( $metaclass, 'MooseX::StrictConstructor::Trait::Class' )
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
	
	require Class::XSDestructor;
	local $Class::XSDestructor::REDEFINE = !!1;
	Class::XSDestructor->import( [ $klass, 'DESTROY' ] );
	
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

MooseX::XSConstructor - glue between Moose and Class::XSConstructor

=head1 SYNOPSIS

  package Foo;
  
  use Moose;
  use MooseX::XSConstructor;
  
  ...; # Normal Moose stuff
  
  __PACKAGE__->meta->make_immutable(
    inline_constructor => 0,
    inline_destructor  => 0,
  );

=head1 DESCRIPTION

This module speeds up all your Mooses. (Meese?)

It does this by replacing the normal Perl constructor that Moose
generates for your class with a faster one written in XS.

If it detects that your class cannot be accellerated, then it will
bail out and do nothing.

Most built-in Moose features are supported though, as are a few
extensions. Namely: L<MooseX::Aliases>, L<MooseX::StrictConstructor>,
and L<MooseX::UndefTolerant>. If you're using other MooseX modules,
you probably won't get a speedup.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-moosex-xsconstructor/issues>.

=head1 SEE ALSO

L<MooX::XSConstructor>,
L<Class::XSConstructor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

