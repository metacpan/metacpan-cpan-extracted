package MooseX::Trait::Tag;

=head1 NAME

MooseX::Trait::Tag - Add an arbitrary tag to an attribute

=cut

use Moose::Role;
use namespace::autoclean;

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';

=head1 SYNOPSIS

This module provides a way to give a Moose attribute an arbitrary tag.
Various methods are installed into the package declaring the attribute,
allowing for actions to be taken on only the tagged attributes.
This module is inspired by L<http://search.cpan.org/~ether/Moose/lib/Moose/Cookbook/Meta/Labeled_AttributeTrait.pod>

Example usage:

	package Foo;
	use Moose;
	use MooseX::Trait::Tag qw{metadata};

	has field1 => (is => 'rw', traits => [qw{metadata}]);
	has field2 => (is => 'ro', traits => [qw{metadata}]);
	has field3 => (is => 'rw', traits => []);

	__PACKAGE__->meta->make_immutable;

	package main;

	my $foo = Foo->new;

	my @metadata_fields = sort $foo->all_metadata_attributes;
	# @metadata_fields => qw{ field1 field2 }

	print "Yes\n" if $foo->is_metadata_attribute('field1');
	print "No\n" if !$foo->is_metadata_attribute('field3');

	$foo->set_metadata(
		field1 => 6,
		field2 => 7,
		field3 => 8,
		field4 => 9,
	);
	# => only field1 is modified

	my %field_to_value = $foo->get_metadata;
	# %field_to_value => (field1 => 6, field2 => undef)

=cut

=head1 METHODS

=cut

sub import {
	my $class = shift;
	my $importing_class = caller();
	$class->register_tag(importing_class => $importing_class, tag => $_) for @_;
}

=head2 register_tag(importing_class => $importing_class, tag => $tag)

Install the methods asociated with the tag into the importing class.

=cut

sub register_tag {
	my $class = shift;
	my %args = @_;
	my ($importing_class, $tag) = @args{qw{importing_class tag}};

	#Moose magic to create a new trait bound to the label
	my $tag_class = "$class\::$tag";
	Moose::Meta::Role->create($tag_class);
	Moose::Util::meta_attribute_alias($tag, $tag_class);

=head1 INSTALLED METHODS

=cut

=head2 is_<tag>_attribute( $attribute_name )

Given an attribute name, determine if it is registered to the tag.
Requires an attribute name.

=cut

	my $importing_class_meta = $importing_class->meta;
	$importing_class_meta->add_method("is_$tag\_attribute", sub {
		my $attribute = (shift)->meta->find_attribute_by_name(@_);
		return $attribute && $attribute->does($tag);
	}) unless $importing_class_meta->has_method("is_$tag\_attribute");

=head2 all_<tag>_attributes( )

Return the names of all attributes marked with the tag.

=cut

	$importing_class_meta->add_method("all_$tag\_attributes", sub {
		map { $_->name }
		grep { $_->does($tag) }
		(shift)->meta->get_all_attributes
	}) unless $importing_class_meta->has_method("all_$tag\_attributes");

=head2 get_<tag>( )

Return all name-value pairs for each readable attribute associated with the
appropriate tag.

=cut

	$importing_class_meta->add_method("get_$tag", sub {
		my $self = shift;
		return
			map { my $reader = $_->get_read_method; ($_->name => scalar($self->$reader)) }
			grep { $_->does($tag) && $_->get_read_method }
			$self->meta->get_all_attributes
	}) unless $importing_class_meta->has_method("get_$tag");

=head2 set_<tag>( attribute1 => $new_value1, ... )

Given name-value pairs, update each writable attribute with the new value
if it is associated with the appropriate tag.

=cut

	$importing_class_meta->add_method("set_$tag", sub {
		my ($self, %args) = @_;

		for my $attribute (grep { $_->does($tag) } $self->meta->get_all_attributes) {
			next unless exists $args{$attribute->name};
			my $writer = $attribute->get_write_method;
			next unless $writer;
			$self->$writer($args{$attribute->name});
		}

		return;
	}) unless $importing_class_meta->has_method("set_$tag");
}

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-trait-tag at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-moosex-trait-tag/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Trait::Tag

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-moosex-trait-tag>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-moosex-trait-tag/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Trait-Tag>

=item * Official CPAN Page

L<http://search.cpan.org/dist/MooseX-Trait-Tag/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MooseX::Trait::Tag
