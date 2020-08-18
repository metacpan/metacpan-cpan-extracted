
use strict;
use warnings;

use Test::More tests => 8;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3 (
    qw[ s3_api_with_signature_2 ],
);

use Shared::Examples::Net::Amazon::S3::API (
    qw[ with_response_fixture ],
    qw[ expect_api_bucket_objects_list ],
);

expect_api_bucket_objects_list 'list objects (version 1)' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('response::bucket_objects_list_v1'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => {
        bucket => 'some-bucket',
        prefix => '',
        marker => '',
        next_marker => '',
        max_keys => 1000,
        is_truncated => bool (0),
        keys => [ {
            key => 'my-image.jpg',
            last_modified => '2009-10-12T17:50:30.000Z',
            etag => 'fba9dede5f27731c9771645a39863328',
            size => 434234,
            storage_class => 'STANDARD',
            owner_id => '75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a',
            owner_displayname => 'mtd@amazon.com',
        }, {
            key => 'my-third-image.jpg',
            last_modified => '2009-10-12T17:50:30.000Z',
            etag => '1b2cf535f27731c974343645a3985328',
            size => 64994,
            storage_class => 'STANDARD_IA',
            owner_id => '75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a',
            owner_displayname => 'mtd@amazon.com',
        } ],
    },
);

expect_api_bucket_objects_list 'list objects with filters (version 1)' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('response::bucket_objects_list_v1_with_filter_truncated'),
    with_prefix             => 'N',
    with_marker             => 'Ned',
    with_max_keys           => 40,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?marker=Ned&max-keys=40&prefix=N' },
    expect_data             => {
        bucket => 'some-bucket',
        prefix => 'N',
        marker => 'Ned',
        next_marker => '',
        max_keys => 40,
        is_truncated => bool (1),
        keys => [ {
            key => 'Nelson',
            last_modified => '2006-01-01T12:00:00.000Z',
            etag => '828ef3fdfa96f00ad9f27c383fc9ac7f',
            size => 5,
            storage_class => 'STANDARD',
            owner_id => 'bcaf161ca5fb16fd081034f',
            owner_displayname => 'webfile',
        }, {
            key => 'Neo',
            last_modified => '2006-01-01T12:00:00.000Z',
            etag => '828ef3fdfa96f00ad9f27c383fc9ac7f',
            size => 4,
            storage_class => 'STANDARD',
            owner_id => 'bcaf1ffd86a5fb16fd081034f',
            owner_displayname => 'webfile',
        } ],
    },
);

expect_api_bucket_objects_list 'list objects with delimiter (version 1)' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('response::bucket_objects_list_v1_with_delimiter'),
    with_delimiter          => '/',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?delimiter=%2F' },
    expect_data             => {
        bucket => 'some-bucket',
        prefix => '',
        marker => '',
        next_marker => '',
        max_keys => 1000,
        is_truncated => bool (0),
        keys => [ {
            key => 'sample.jpg',
            last_modified => '2011-02-26T01:56:20.000Z',
            etag => 'bf1d737a4d46a19f3bced6905cc8b902',
            size => 142863,
            storage_class => 'STANDARD',
            owner_id => 'canonical-user-id',
            owner_displayname => 'display-name',
        } ],
        common_prefixes => [
            'photos',
        ],
    },
);

expect_api_bucket_objects_list 'list objects with prefix and delimiter (version 1)' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('response::bucket_objects_list_v1_with_prefix_and_delimiter'),
    with_delimiter          => '/',
    with_prefix             => 'photos/2006/',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?delimiter=%2F&prefix=photos%2F2006%2F' },
    expect_data             => {
        bucket => 'some-bucket',
        prefix => 'photos/2006/',
        marker => '',
        next_marker => '',
        max_keys => 1000,
        is_truncated => bool (0),
        keys => [],
        common_prefixes => [
            'photos/2006/February',
            'photos/2006/January',
        ],
    },
);

expect_api_bucket_objects_list 'error access denied' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::access_denied'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_objects_list 'error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchBucket',
    expect_s3_errstr        => 'No such bucket error message',
);

expect_api_bucket_objects_list 'list objects (version 1) on Google Cloud Storage' => (
    with_bucket             => 'gcs-bucket',
    with_response_fixture ('response::bucket_objects_list_v1_google_cloud_storage'),
    with_s3                 => s3_api_with_signature_2(host => 'storage.googleapis.com'),
    expect_request          => { GET => 'https://gcs-bucket.storage.googleapis.com/' },
    expect_data             => {
        bucket => 'gcs-bucket',
        prefix => '',
        marker => '',
        max_keys => '',
        next_marker => 'next/marker/is/foo',
        is_truncated => bool (1),
        keys => [ {
            key => 'path/to/value',
            last_modified => '2017-04-21T22:06:03.413Z',
            etag => '1f52bad2879ca96dacd7a40f33001230',
            size => 742213,
            storage_class => '',
            owner_id => '',
            owner_displayname => '',
        }, {
            key => 'path/to/value2',
            last_modified => '2018-04-21T22:06:03.413Z',
            etag => '1f52bad2889ca96dacd7a40f33001230',
            size => 742214,
            storage_class => '',
            owner_id => '',
            owner_displayname => '',
        } ],
    },
);

had_no_warnings;
