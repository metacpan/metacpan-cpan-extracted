
use strict;
use warnings;

use Test::More tests => 1 + 3;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::API (
    qw[ expect_api_list_all_my_buckets ],
);

use Shared::Examples::Net::Amazon::S3::Operation::Service::Buckets::List (
    qw[ buckets_list_with_displayname ],
    qw[ buckets_list_without_displayname ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
);

expect_api_list_all_my_buckets 'list all my buckets with displayname' => (
    with_response_data  => buckets_list_with_displayname,
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    expect_data         => {
        owner_id => 'bcaf1ffd86f461ca5fb16fd081034f',
        owner_displayname => 'webfile',
        buckets => [
            all (
                obj_isa ('Net::Amazon::S3::Bucket'),
                methods (bucket => 'quotes'),
            ),
            all (
                obj_isa ('Net::Amazon::S3::Bucket'),
                methods (bucket => 'samples'),
            ),
        ],
    },
);

expect_api_list_all_my_buckets 'list all my buckets without displayname' => (
    with_response_data  => buckets_list_without_displayname,
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    expect_data         => {
        owner_id => 'bcaf1ffd86f461ca5fb16fd081034f',
        owner_displayname => '',
        buckets => [
            all (
                obj_isa ('Net::Amazon::S3::Bucket'),
                methods (bucket => 'quotes'),
            ),
            all (
                obj_isa ('Net::Amazon::S3::Bucket'),
                methods (bucket => 'samples'),
            ),
        ],
    },
);

expect_api_list_all_my_buckets 'list all my buckets without displayname' => (
    fixture_error_access_denied,
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    expect_data         => bool (0),
    expect_s3_err       => 'AccessDenied',
    expect_s3_errstr    => 'Access denied error message',
);

