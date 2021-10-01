package Mock::Data::Generator;
use strict;
use warnings;
require MRO::Compat if "$]" < '5.009005';
require mro;
mro::set_mro(__PACKAGE__, 'c3');
require Scalar::Util;
require Carp;
our @CARP_NOT= qw( Mock::Data Mock::Data::Util );

# ABSTRACT: Utilities and optional base class for authoring generators
our $VERSION = '0.03'; # VERSION


sub generate { Carp::croak "Unimplemented" }


sub compile {
	my ($self, @default_params)= @_;
	# If no arguments, add a simple wrapper around ->generate
	return sub { $self->generate(shift) } unless @default_params > 1;
	return sub { $self->generate(shift, @default_params) };
}


our $_try_reverse;
sub combine_generator {
	# if already recursed, return the original default combination
	return Mock::Data::Set->new_uniform($_[1], $_[0]) if $_try_reverse;
	# Call the peer's combine_generator in case it is overridden
	local $_try_reverse= 1;
	return $_[1]->combine_generator($_[0]);
}


require Mock::Data::Set;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Generator - Utilities and optional base class for authoring generators

=head1 DESCRIPTION

This package provides a set of utility methods for writing generators, and an optional
abstract base class.  (a Generator does not need to inherit from this class)

=head1 GENERATORS

The most basic C<Mock::Data> generator is a simple coderef of the form

  sub ( $mockdata, \%arguments, @arguments ) { ... }

which returns a literal data item, usually a scalar.  A generator can also be any object
which has a L</generate> method.  Using an object provides more flexibility to handle
cases where a user wants to combine generators.

=head1 METHODS

=head2 generate

  my $data= $generator->generate($mockdata, \%named_params, @pos_params);

Like the coderef, this takes an instance of L<Mock::Data> as the first non-self argument,
followed by a hashref of named parameters, followed by arbitrary positional parameters after
that.

=head2 compile

  my $callable= $generator->compile(@default_params);

Return a plain coderef that most optimally performs the generation for the C<@default_params>.
This implementation just wraps C<< $self->generate(@defaults) >> in a coderef.  Subclasses
may provide more useful optimization.

The returned coderef takes one argument, of a L<Mock::Data> instance.

=head2 combine_generator

  my $new_generator= $generator->combine_generator( $peer );

The default way to combine two generators is to create a new generator that selects each
child generator 50% of the time.  For generators that define a collection of possible data,
it may be preferred to merge the collections in a manner different than a plain 50% split.
This method allows for that custom behavior.

=head2 clone

A generator that wants to perform special behavior when the C<Mock::Data> instance gets cloned
can implement this method.  I can't think of any reason a generator should ever need this,
since the L<Mock::Data/generator_state> gets cloned.  Lack of the method indicates the
generator doesn't need this feature.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.03

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
