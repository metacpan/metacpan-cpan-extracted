package Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::List;
# ABSTRACT: used for testing and as example
$Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::List::VERSION = '0.88';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

our @EXPORT_OK = (
    qw[ list_bucket_objects_v1 ],
    qw[ list_bucket_objects_v1_with_filter_truncated ],
    qw[ list_bucket_objects_v1_with_filter ],
    qw[ list_bucket_objects_v1_with_delimiter ],
    qw[ list_bucket_objects_v1_with_prefix_and_delimiter ],
    qw[ list_bucket_objects_v1_google_cloud_storage ],
);

sub list_bucket_objects_v1 {
    <<'EOXML';
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
EOXML
}

sub list_bucket_objects_v1_with_filter_truncated {
    <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>some-bucket</Name>
  <Prefix>N</Prefix>
  <Marker>Ned</Marker>
  <MaxKeys>40</MaxKeys>
  <IsTruncated>true</IsTruncated>
  <Contents>
    <Key>Nelson</Key>
    <LastModified>2006-01-01T12:00:00.000Z</LastModified>
    <ETag>&quot;828ef3fdfa96f00ad9f27c383fc9ac7f&quot;</ETag>
    <Size>5</Size>
    <StorageClass>STANDARD</StorageClass>
    <Owner>
      <ID>bcaf161ca5fb16fd081034f</ID>
      <DisplayName>webfile</DisplayName>
     </Owner>
  </Contents>
  <Contents>
    <Key>Neo</Key>
    <LastModified>2006-01-01T12:00:00.000Z</LastModified>
    <ETag>&quot;828ef3fdfa96f00ad9f27c383fc9ac7f&quot;</ETag>
    <Size>4</Size>
    <StorageClass>STANDARD</StorageClass>
     <Owner>
      <ID>bcaf1ffd86a5fb16fd081034f</ID>
      <DisplayName>webfile</DisplayName>
    </Owner>
 </Contents>
</ListBucketResult>
EOXML
}

sub list_bucket_objects_v1_with_filter {
    <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>some-bucket</Name>
  <Prefix>N</Prefix>
  <Marker>Ned</Marker>
  <MaxKeys>40</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>Nelson</Key>
    <LastModified>2006-01-01T12:00:00.000Z</LastModified>
    <ETag>&quot;828ef3fdfa96f00ad9f27c383fc9ac7f&quot;</ETag>
    <Size>5</Size>
    <StorageClass>STANDARD</StorageClass>
    <Owner>
      <ID>bcaf161ca5fb16fd081034f</ID>
      <DisplayName>webfile</DisplayName>
     </Owner>
  </Contents>
  <Contents>
    <Key>Neo</Key>
    <LastModified>2006-01-01T12:00:00.000Z</LastModified>
    <ETag>&quot;828ef3fdfa96f00ad9f27c383fc9ac7f&quot;</ETag>
    <Size>4</Size>
    <StorageClass>STANDARD</StorageClass>
     <Owner>
      <ID>bcaf1ffd86a5fb16fd081034f</ID>
      <DisplayName>webfile</DisplayName>
    </Owner>
 </Contents>
</ListBucketResult>
EOXML
}

sub list_bucket_objects_v1_with_delimiter {
    <<'EOXML';
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
EOXML
}

sub list_bucket_objects_v1_with_prefix_and_delimiter {
    <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>some-bucket</Name>
  <Prefix>photos/2006/</Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <Delimiter>/</Delimiter>
  <IsTruncated>false</IsTruncated>

  <CommonPrefixes>
    <Prefix>photos/2006/February/</Prefix>
  </CommonPrefixes>
  <CommonPrefixes>
    <Prefix>photos/2006/January/</Prefix>
  </CommonPrefixes>
</ListBucketResult>
EOXML
}

sub list_bucket_objects_v1_google_cloud_storage {
    <<'EOXML';
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
EOXML
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::List - used for testing and as example

=head1 VERSION

version 0.88

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
