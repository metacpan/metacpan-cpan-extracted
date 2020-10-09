# PODNAME: Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_list_v1_with_delimiter
# ABSTRACT: Shared::Examples providing response fixture

use strict;
use warnings;

use Shared::Examples::Net::Amazon::S3::Fixture;

Shared::Examples::Net::Amazon::S3::Fixture::fixture content => <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<Name>some-bucket</Name>
	<Prefix></Prefix>
	<Marker></Marker>
	<MaxKeys>1000</MaxKeys>
	<Delimiter>/</Delimiter>
	<IsTruncated>false</IsTruncated>
	<Contents>
		<Key>sample.jpg</Key>
		<LastModified>2011-02-26T01:56:20.000Z</LastModified>
		<ETag>&quot;bf1d737a4d46a19f3bced6905cc8b902&quot;</ETag>
		<Size>142863</Size>
		<Owner>
			<ID>canonical-user-id</ID>
			<DisplayName>display-name</DisplayName>
		</Owner>
		<StorageClass>STANDARD</StorageClass>
	</Contents>
	<CommonPrefixes>
		<Prefix>photos/</Prefix>
	</CommonPrefixes>
</ListBucketResult>
XML

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_list_v1_with_delimiter - Shared::Examples providing response fixture

=head1 VERSION

version 0.97

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
