package MooseX::Role::UnsafeConstructable;

=head1 NAME

MooseX::Role::UnsafeConstructable - construct an object without type-checks

=cut

use strict;
use warnings;

use Class::MOP;
use Class::MOP::Attribute;
use Class::MOP::Class;
use Moose::Role;
use namespace::autoclean;

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module provides the method I<unsafe_new> which allows the caller to
construct an instance while bypassing all access controls and type constraints.
This is useful when the caller knows and trusts the source of the
initialization data and doesn't want to choose between performance in a corner
case and data integrity of the overall system.

Example usage:

	package Foo;
	use Moose;
	with 'MooseX::Role::UnsafeConstructable';

	has field => (is => 'ro', isa => 'HashRef[ArrayRef[Str]]');

	__PACKAGE__->meta->make_immutable;

	package main;

	my $foo = Foo->unsafe_new(field => {this => [qw{that and another}]});
		# => is a Foo, but instantiated faster

=cut

do {
	my $moose_meta = Moose::Meta::Class->meta;
	$moose_meta->make_mutable;
	$moose_meta->add_after_method_modifier('make_immutable', sub {
		my $meta = shift;
		$meta->name->declare_unsafe_class if $meta->name->does(__PACKAGE__);
	});
	$moose_meta->make_immutable;
};


=head1 METHODS

=cut

=head2 declare_unsafe_class

Declare the shadow class to be used for unsafe instantiation.  Any class using
MooseX::Role::UnsafeConstructable role will call declare_unsafe_class
automatically when made immutable.  Otherwise, declare_unsafe_class must be
called after the original class is fully declared to ensure all attributes are
properly shadowed.

For each attribute, the shadow class will preserve:
name, default, builder, and init_arg.  All other options will be dropped.  This
should provide behavior that mostly matches normal instantiation, with the one
caveat that any field declared uninitializable (with init_arg => undef) can now
be set.  This is considered a feature, not a bug.

=cut

sub declare_unsafe_class {
	my $class = shift;

	return if Class::MOP::class_of($class->unsafe_class);

	Class::MOP::Class->create($class->unsafe_class => (
		methods => {promote => sub { bless shift, $class }},
		attributes => [map { Class::MOP::Attribute->new(
			$_->name,
			$_->has_default  ? (default => $_->default) : (),
			$_->has_builder  ? (builder => $class . '::' . $_->builder) : (),
			$_->has_init_arg ? (init_arg => $_->init_arg) : (),
		) } $class->meta->get_all_attributes],
	));
	$class->unsafe_class->meta->make_immutable;

	return;
}

=head2 unsafe_class

Return the name of the shadow class used for unsafe instantiation.

=cut

sub unsafe_class { my $class = shift; (ref $class || $class) . '::Unsafe' }

=head2 unsafe_new

Instantiate the class, bypassing access and type constraints.

=cut

sub unsafe_new { shift->unsafe_class->new(@_)->promote }

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-MooseX-Role-UnsafeConstructable at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-moosex-role-unsafeconstructable/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Role::UnsafeConstructable

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-moosex-role-unsafeconstructable>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-moosex-role-unsafeconstructable/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-UnsafeConstructable>

=item * Official CPAN Page

L<http://search.cpan.org/dist/MooseX-Role-UnsafeConstructable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MooseX::Role::UnsafeConstructable
