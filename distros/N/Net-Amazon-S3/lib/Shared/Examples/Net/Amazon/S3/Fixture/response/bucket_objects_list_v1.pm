# PODNAME: Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_list_v1
# ABSTRACT: Shared::Examples providing response fixture

use strict;
use warnings;

use Shared::Examples::Net::Amazon::S3::Fixture;

Shared::Examples::Net::Amazon::S3::Fixture::fixture content => <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<Name>some-bucket</Name>
	<Prefix/>
	<Marker/>
	<MaxKeys>1000</MaxKeys>
	<IsTruncated>false</IsTruncated>
	<Contents>
		<Key>my-image.jpg</Key>
		<LastModified>2009-10-12T17:50:30.000Z</LastModified>
		<ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
		<Size>434234</Size>
		<StorageClass>STANDARD</StorageClass>
		<Owner>
			<ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
			<DisplayName>mtd@amazon.com</DisplayName>
		</Owner>
	</Contents>
	<Contents>
		<Key>my-third-image.jpg</Key>
		<LastModified>2009-10-12T17:50:30.000Z</LastModified>
		<ETag>&quot;1b2cf535f27731c974343645a3985328&quot;</ETag>
		<Size>64994</Size>
		<StorageClass>STANDARD_IA</StorageClass>
		<Owner>
			<ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
			<DisplayName>mtd@amazon.com</DisplayName>
		</Owner>
	</Contents>
</ListBucketResult>
XML

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_list_v1 - Shared::Examples providing response fixture

=head1 VERSION

version 0.991

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
