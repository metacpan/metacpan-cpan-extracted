package MooseX::Role::Defaultable;

=head1 NAME

MooseX::Role::Defaultable - "factory reset" for a Moose class

=cut

use strict;
use warnings;

use Moose::Role;
use Sub::IsEqual qw{is_equal};
use namespace::autoclean;

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

This module provides methods to verify and restore default values for a
Moose object's attributes, essentially providing a "factory reset" option.

Example usage:

	package Foo;
	use Moose;
	use MooseX::Role::Defaultable;

	has field1 => (is => 'rw');
	has field2 => (is => 'rw', default => 'blah');
	has field3 => (is => 'rw', default => sub { [] });

	__PACKAGE__->meta->make_immutable;

	package main;

	my $foo = Foo->new();
	print "Yes" if $foo->is_default;
	$foo->field1('ignored');
	$foo->field2('active');
	$foo->field3(['complex']);
	print "No" unless $foo->is_default;
	print "Yes" if $foo->is_default('field1');
	$foo->restore_default;
	print "Yes" if $foo->is_default;

=cut

=head1 METHODS

=cut

=head2 is_default

Return true if an object's attributes are set to their defaults.  A list of
attribute names can be provided, restricting the check to only those
attributes.  Unknown attributes and attributes with no defaults are both
considered to be in their default states.

=cut

sub is_default {
	my $self = shift;

	my @attributes = @_
		? map { $self->meta->find_attribute_by_name($_) } @_
		: $self->meta->get_all_attributes;

	for my $attribute (grep { $_->has_default } @attributes) {
		return 0 unless is_equal($attribute->default($self), $attribute->get_value($self))
	}

	return 1;
}

=head2 restore_default

Set an object's attributes back to their defaults.  This operation bypasses the
writers so triggers, coercions, and access restrictions will not apply.  Any
attribute that does not have a default is ignored.  A list of attribute names
can be provided, restricting the reset to only those attributes.

=cut

sub restore_default {
	my $self = shift;

	my @attributes = @_
		? grep { defined $_ } map { $self->meta->find_attribute_by_name($_) } @_
		: $self->meta->get_all_attributes;

	for my $attribute (grep { $_->has_default } @attributes) {
		$attribute->clear_value($self);
		$attribute->set_value($self, $attribute->default($self));
	}

	return;
}

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-MooseX-Role-Defaultable at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-moosex-role-defaultable/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Role::Defaultable

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-moosex-role-defaultable>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-moosex-role-defaultable/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Defaultable>

=item * Official CPAN Page

L<http://search.cpan.org/dist/MooseX-Role-Defaultable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MooseX::Role::Defaultable
