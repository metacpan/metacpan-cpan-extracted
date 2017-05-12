package MongoDBx::Class::ParsedAttribute;

# ABSTRACT: A Moose role for automatically expanded and collapsed document attributes.

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose::Role;
use namespace::autoclean;

requires 'expand';

requires 'collapse';

=head1 NAME

MongoDBx::Class::ParsedAttribute - A Moose role for automatically expanded and collapsed document attributes.

=head1 VERSION

version 1.030002

=head1 SYNOPSIS

	# in MyApp/ParsedAttribute/URI.pm
	package MyApp::ParsedAttribute::URI;

	use Moose;
	use namespace::autoclean;
	use URI;

	with 'MongoDBx::Class::ParsedAttribute';

	sub expand {
		my ($self, $uri_text) = @_;

		return URI->new($uri_text);
	}

	sub collapse {
		my ($self, $uri_obj) = @_;

		return $uri_obj->as_string;
	}

	1;

	# in MyApp/Schema/SomeDocumentClass.pm
	has 'url' => (is => 'ro', isa => 'URI', traits => ['Parsed'], parser => 'MyApp::ParsedAttribute::URI', required => 1);

=head1 DESCRIPTION

This module is a L<Moose role|Moose::Role> meant to be consumed by classes
that automatically expand (from a MongoDB database) and collapse (to a
MongoDB database) attributes of a certain type. This is similar to
L<DBIx::Class>' L<InflateColumn|DBIx::Class::InflateColumn> family of
modules that do pretty much the same thing for the SQL world.

A class implementing this role with a name such as 'URI' (full package name
MongoDBx::Class::ParsedAttribute::URI or MyApp::ParsedAttribute::URI) is
expected to expand and collapse L<URI> objects. Similarly, a class named
'NetAddr::IP' is expected to handle L<NetAddr::IP> objects.

Currently, a L<DateTime|MongoDBx::Class::ParsedAttribute::DateTime> parser
is provided with the L<MongoDBx::Class> distribution.

=head1 REQUIRES

Consuming classes must implement the following methods:

=head2 expand( $value )

Receives a raw attribute's value from a MongoDB document and returns the
appropriate object representing it. For example, supposing the value is
an epoch integer, the expand method might return a L<DateTime> object.

=head2 collapse( $object )

Receives an object representing a parsed attribute, and returns that
objects value in a form that can be saved in the database. For example,
if the object is a L<DateTime> object, this method might return the date's
epoch integer.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::ParsedAttribute

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDBx::Class::EmbeddedDocument>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
