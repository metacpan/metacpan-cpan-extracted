
use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep v0.111; # 0.111 => obj_isa
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::API (
    qw[ with_response_fixture ],
    qw[ expect_api_list_all_my_buckets ],
);

expect_api_list_all_my_buckets 'list all my buckets with displayname' => (
    with_response_fixture ('response::service_list_buckets_with_owner_displayname'),
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
    with_response_fixture ('response::service_list_buckets_without_owner_displayname'),
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
    with_response_fixture ('error::access_denied'),
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    expect_data         => bool (0),
    expect_s3_err       => 'AccessDenied',
    expect_s3_errstr    => 'Access denied error message',
);

had_no_warnings;
