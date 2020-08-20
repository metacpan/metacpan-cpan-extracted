# PODNAME: Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_list_v1_google_clout_storage
# ABSTRACT: Shared::Examples providing response fixture

# Google uses different XML namespace uri
# XML namespace is treated by an XML parser as a string,
# its value is not used to fetch any data, so we need extra test

use strict;
use warnings;

use Shared::Examples::Net::Amazon::S3::Fixture;

Shared::Examples::Net::Amazon::S3::Fixture::fixture content => <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns='http://doc.s3.amazonaws.com/2006-03-01'>
  <Name>gcs-bucket</Name>
  <Prefix></Prefix>
  <Marker></Marker>
  <NextMarker>next/marker/is/foo</NextMarker>
  <IsTruncated>true</IsTruncated>
  <Contents>
    <Key>path/to/value</Key>
    <Generation>1473499153424000</Generation>
    <MetaGeneration>1</MetaGeneration>
    <LastModified>2017-04-21T22:06:03.413Z</LastModified>
    <ETag>"1f52bad2879ca96dacd7a40f33001230"</ETag>
    <Size>742213</Size>
  </Contents>
  <Contents>
    <Key>path/to/value2</Key>
    <Generation>1473499153424001</Generation>
    <MetaGeneration>1</MetaGeneration>
    <LastModified>2018-04-21T22:06:03.413Z</LastModified>
    <ETag>"1f52bad2889ca96dacd7a40f33001230"</ETag>
    <Size>742214</Size>
  </Contents>
</ListBucketResult>
XML

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Fixture::response::bucket_objects_list_v1_google_clout_storage - Shared::Examples providing response fixture

=head1 VERSION

version 0.91

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
