use strict;
use warnings;
package Net::Google::Storage::Bucket;
$Net::Google::Storage::Bucket::VERSION = '0.2.0';
# ABSTRACT: Interface for a Google Storage Bucket
# https://developers.google.com/storage/docs/json_api/v1/buckets#resource

use Moose;

use Net::Google::Storage::Types;


has id => (
	is => 'ro',
	isa => 'Str',
);


has projectId => (
	is => 'ro',
	isa => 'Int',
);


has selfLink => (
	is => 'ro',
	isa => 'Str'
);


has timeCreated => (
	is => 'ro',
	isa => 'Str',
);


has owner => (
	is => 'ro',
	isa => 'HashRef[Str]',
);


has location => (
	is => 'rw',
	isa => 'Net::Google::Storage::Types::BucketLocation',
	default => 'US',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Google::Storage::Bucket - Interface for a Google Storage Bucket

=head1 VERSION

version 0.2.0

=head1 DESCRIPTION

Object for storing the data of a bucket, slightly cut down from
L<https://developers.google.com/storage/docs/json_api/v1/buckets#resource>.

Generally Net::Google::Storage::Bucket objects are acquired from a
C<get_bucket>, C<list_buckets>, or C<insert_bucket> call on a
L<Net::Google::Storage> object.

=head1 ATTRIBUTES

=head2 id

The name of the bucket.

=head2 projectId

The id of the project to which this bucket belongs.

=head2 selfLink

The url of this bucket.

=head2 timeCreated

The creation date of the bucket in
L<RFC3339https://tools.ietf.org/html/rfc3339> format, eg
C<2012-09-16T07:00:26.982Z>.

=head2 owner

Hashref of the owner details for the bucket - see
L<the docs|https://developers.google.com/storage/docs/json_api/v1/buckets#resource>.

=head2 location

Physical location of the servers containing this bucket, currently only C<US>
or C<EU>.

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
