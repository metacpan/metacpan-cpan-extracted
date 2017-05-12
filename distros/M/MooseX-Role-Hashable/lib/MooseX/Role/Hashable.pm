package MooseX::Role::Hashable;

=head1 NAME

MooseX::Role::Hashable - Transform the object into a hash

=cut

use strict;
use warnings;

use Moose::Role;
use Set::Functional qw{difference_by setify_by};
use namespace::autoclean;

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';

=head1 SYNOPSIS

This module adds a single method to an object to convert it into a simple hash.
This is meant to act as the inverse function of I<new>, provided nothing too
crazy is going on during initialization.  If the class is made immutable, the
optimizer will precalculate the extracted attributes for a signifcant speed up.

Example usage:

	package Foo;
	use Moose;
	use MooseX::Role::Hashable;

	has field1 => (is => 'rw');
	has field2 => (is => 'ro');
	has field3 => (is => 'bare');
	has _field4 => (is => 'rw', init_arg => 'field4');

	__PACKAGE__->meta->make_immutable;

	package main;

	my $foo = Foo->new(field1 => 'val1', field2 => 'val2', field3 => 'val3', field4 => 'val4');
	$foo->as_hash;
	# => {field1 => 'val1', field2 => 'val2', field3 => 'val3', field4 => 'val4'}

=cut

do {
	my $package = __PACKAGE__;
	package
		Moose::Meta::Class;

	use Class::Method::Modifiers ();

	Class::Method::Modifiers::after(make_immutable => sub {
		my $meta = shift;
		my $class = $meta->name;
		$class->optimize_as_hash
			if $class->can('does')
			&& $class->does($package);
	});

	Class::Method::Modifiers::before(make_mutable => sub {
		my $meta = shift;
		my $class = $meta->name;
		$class->deoptimize_as_hash
			if $class->can('does')
			&& $class->does($package);
	});
};

=head1 METHODS

=cut

=head2 as_hash

Transform the object into a hash of attribute-value pairs.  All attributes,
including those without a reader, are extracted.  Attributes whose initial
arguments differ from their name will appear using the initialization argument.
Attributes which can' be initialized will be ignored.  Reference values will
perform a shallow copy.

=cut

my %CLASS_TO_ATTRIBUTES;
my $extract_attributes_ref = sub {
	return
		#We only want one copy of each attribute
		setify_by { $_->name }
		#Manually taverse all attributes, get_all_attributes doesn't update
		#with superclass changes afte subclass immutability
		map { my $meta = $_->meta; map { $meta->get_attribute($_) } $meta->get_attribute_list }
		#Make sure attribute overrides take precedence
		reverse $_[0]->meta->linearized_isa;
};
my $extract_ignored_ref = sub { grep { ! $_->has_init_arg } @_ };
my $extract_translated_ref = sub { map { ($_->name => $_->init_arg) } grep { $_->has_init_arg && $_->init_arg ne  $_->name } @_ };
my $extract_uninitialized_ref = sub { grep { ! ($_->is_required || ! $_->is_lazy && ($_->has_builder || $_->has_default)) } @_ };
my $prepare_attributes_ref = sub {
	my @ignored = $extract_ignored_ref->(@_);
	my %translated = $extract_translated_ref->(@_);
	my @uninitialized = $extract_uninitialized_ref->(@_);
	return (
		[map { $_->name } @ignored],
		\%translated,
		[difference_by { $_->name } \@uninitialized, \@ignored],
	)
};

sub as_hash {
	my $self = shift;

	my $cached_attributes = $CLASS_TO_ATTRIBUTES{ref $self};
	my ($ignored_attributes, $translated_attributes, $uninitialized_attributes) = $cached_attributes
		? @{$cached_attributes}{qw{ignored translated uninitialized}}
		: $prepare_attributes_ref->($extract_attributes_ref->($self))
		;

	my %copy = %$self;
	$copy{$_->name} = $_->get_value($self)
		for grep { ! exists $copy{$_->name} } @$uninitialized_attributes;
	@copy{values %$translated_attributes} = delete @copy{keys %$translated_attributes};
	delete @copy{@$ignored_attributes};

	return \%copy;
}

sub optimize_as_hash {
	my $class = shift;

	#Precalculate the attributes
	@{$CLASS_TO_ATTRIBUTES{$class}}{qw{ ignored translated uninitialized }} =
		$prepare_attributes_ref->($extract_attributes_ref->($class));

	$_->optimize_as_hash for $class->meta->direct_subclasses;

	return;
}

sub deoptimize_as_hash {
	my $class = shift;

	delete $CLASS_TO_ATTRIBUTES{$class};

	$_->deoptimize_as_hash for $class->meta->direct_subclasses;

	return;
}

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

Special thanks to:
L<Dibin Pookombil|https://github.com/dibinp>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-MooseX-Role-Hashable at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-moosex-role-hashable/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Role::Hashable

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-moosex-role-hashable>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-moosex-role-hashable/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Hashable>

=item * Official CPAN Page

L<http://search.cpan.org/dist/MooseX-Role-Hashable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013,2014 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MooseX::Role::Hashable
