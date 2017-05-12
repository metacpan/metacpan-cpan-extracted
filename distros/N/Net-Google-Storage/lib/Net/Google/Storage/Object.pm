use strict;
use warnings;
package Net::Google::Storage::Object;
{
  $Net::Google::Storage::Object::VERSION = '0.1.2';
}

# ABSTRACT: Interface for a Google Storage Object
# https://developers.google.com/storage/docs/json_api/v1/objects#resource

use Moose;

use Net::Google::Storage::Types;


has id => (
	is => 'ro',
	isa => 'Str',
);


has selfLink => (
	is => 'ro',
	isa => 'Str'
);


has name => (
	is => 'ro',
	isa => 'Str',
);


has bucket => (
	is => 'ro',
	isa => 'Str',
);


has media => (
	is => 'ro',
	isa => 'HashRef',
);


has contentEncoding => (
	is => 'ro',
	isa => 'Str',
);


has contentDisposition => (
	is => 'ro',
	isa => 'Str',
);


has cacheControl => (
	is => 'ro',
	isa => 'Str',
);


has metadata => (
	is => 'ro',
	isa => 'HashRef[Str]',
);


has owner => (
	is => 'ro',
	isa => 'HashRef[Str]',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Net::Google::Storage::Object - Interface for a Google Storage Object

=head1 VERSION

version 0.1.2

=head1 DESCRIPTION

Object for storing the data of an object, slightly cut down from
L<https://developers.google.com/storage/docs/json_api/v1/objects#resource>.

Generally Net::Google::Storage::Object objects are acquired from a
C<get_object>, C<list_objects>, or C<insert_object> call on a
L<Net::Google::Storage> object.

=head1 ATTRIBUTES

=head2 id

The id of the object. Essentially the concatenation of the
L<bucket name|/bucket> and the L<object's name|/name>.

=head2 selfLink

The url of this object.

=head2 name

The name of the object within the bucket. B<This is what you want to adjust,
not the id.>

=head2 bucket

The name of the bucket the object resides within.

=head2 media

A hashref containing sundry information about the file itself - check out the
L<docs|https://developers.google.com/storage/docs/json_api/v1/objects#resource>.

=head2 contentEncoding

The content encoding of the object's data.

=head2 contentDisposition

The content disposition of the object's data.

=head2 cacheControl

Cache-Control directive for the object data.

=head2 metadata

Hashref containing user-defined metadata for the object.

=head2 owner

Hashref containing details for the object's owner.

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

