
use strict;
use warnings;

use Test::More tests => 1 + 6;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ expect_client_bucket_objects_list ],
);

use Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::List (
    qw[ list_bucket_objects_v1 ],
    qw[ list_bucket_objects_v1_with_filter ],
    qw[ list_bucket_objects_v1_with_delimiter ],
    qw[ list_bucket_objects_v1_with_prefix_and_delimiter ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
);

expect_client_bucket_objects_list 'list objects (version 1)' => (
    with_bucket             => 'some-bucket',
    with_response_data      => list_bucket_objects_v1,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?max-keys=1000' },
    expect_data             => methods (get_more => [
        all (
            obj_isa ('Net::Amazon::S3::Client::Object'),
            methods (bucket => methods(name => 'some-bucket')),
            methods (key => 'my-image.jpg'),
            methods (last_modified_raw => '2009-10-12T17:50:30.000Z'),
            methods (etag => 'fba9dede5f27731c9771645a39863328'),
            methods (size => 434234),
        ),
        all (
            obj_isa ('Net::Amazon::S3::Client::Object'),
            methods (bucket => methods(name => 'some-bucket')),
            methods (key => 'my-third-image.jpg'),
            methods (last_modified_raw => '2009-10-12T17:50:30.000Z'),
            methods (etag => '1b2cf535f27731c974343645a3985328'),
            methods (size => 64994),
        ),
    ]),
);

expect_client_bucket_objects_list 'list objects with filters (version 1)' => (
    with_bucket             => 'some-bucket',
    # truncated is not supported by shared examples yet (multiple requests => client reads while is truncated)
    with_response_data      => list_bucket_objects_v1_with_filter,
    with_prefix             => 'N',
    with_marker             => 'Ned',
    with_max_keys           => 40,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?max-keys=1000&prefix=N' },
    expect_data             => methods (get_more => [
        all (
            obj_isa ('Net::Amazon::S3::Client::Object'),
            methods (bucket => methods(name => 'some-bucket')),
            methods (key => 'Nelson'),
            methods (last_modified_raw => '2006-01-01T12:00:00.000Z'),
            methods (etag => '828ef3fdfa96f00ad9f27c383fc9ac7f'),
            methods (size => 5),
        ),
        all (
            obj_isa ('Net::Amazon::S3::Client::Object'),
            methods (bucket => methods(name => 'some-bucket')),
            methods (key => 'Neo'),
            methods (last_modified_raw => '2006-01-01T12:00:00.000Z'),
            methods (etag => '828ef3fdfa96f00ad9f27c383fc9ac7f'),
            methods (size => 4),
        ),
    ]),
);

# Client doesn't support common prefixes
expect_client_bucket_objects_list 'list objects with delimiter (version 1)' => (
    with_bucket             => 'some-bucket',
    with_response_data      => list_bucket_objects_v1_with_delimiter,
    with_delimiter          => '/',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?delimiter=%2F&max-keys=1000' },
    expect_data             => methods (get_more => [
        all (
            obj_isa ('Net::Amazon::S3::Client::Object'),
            methods (bucket => methods(name => 'some-bucket')),
            methods (key => 'sample.jpg'),
            methods (last_modified_raw => '2011-02-26T01:56:20.000Z'),
            methods (etag => 'bf1d737a4d46a19f3bced6905cc8b902'),
            methods (size => 142863),
        ),
    ]),
);

# Client doesn't support common prefixes
expect_client_bucket_objects_list 'list objects with prefix and delimiter (version 1)' => (
    with_bucket             => 'some-bucket',
    with_response_data      => list_bucket_objects_v1_with_prefix_and_delimiter,
    with_delimiter          => '/',
    with_prefix             => 'photos/2006/',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?delimiter=%2F&max-keys=1000&prefix=photos%2F2006%2F' },
    expect_data             => methods (get_more => undef),
);

expect_client_bucket_objects_list 'error access denied' => (
    with_bucket             => 'some-bucket',
    fixture_error_access_denied,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?max-keys=1000' },
    expect_data             => code(sub {
        return 0, "expect throw but lives" if eval { $_[0]->get_more; 1 };
        my $error = $@;

        Test::Deep::cmp_details $error, re(qr/^AccessDenied: Access denied error message/);
    }),
);

expect_client_bucket_objects_list 'error no such bucket' => (
    with_bucket             => 'some-bucket',
    fixture_error_no_such_bucket,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?max-keys=1000' },
    expect_data             => methods (get_more => undef),
    expect_data             => code(sub {
        return 0, "expect throw but lives" if eval { $_[0]->get_more; 1 };
        my $error = $@;

        Test::Deep::cmp_details $error, re(qr/^NoSuchBucket: No such bucket error message/);
    }),
);

