
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-client.pl" }

plan tests => 5;

use Shared::Examples::Net::Amazon::S3::Client qw[ expect_client_list_all_my_buckets ];

expect_client_list_all_my_buckets 'list all my buckets with displayname' => (
    with_response_fixture ('response::service_list_buckets_with_owner_displayname'),
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    expect_data         => [
        all (
            obj_isa ('Net::Amazon::S3::Client::Bucket'),
            methods (name => 'quotes'),
            methods (owner_id => 'bcaf1ffd86f461ca5fb16fd081034f'),
            methods (owner_display_name => 'webfile'),
        ),
        all (
            obj_isa ('Net::Amazon::S3::Client::Bucket'),
            methods (name => 'samples'),
            methods (owner_id => 'bcaf1ffd86f461ca5fb16fd081034f'),
            methods (owner_display_name => 'webfile'),
        ),
    ],
);

expect_client_list_all_my_buckets 'list all my buckets without displayname' => (
    with_response_fixture ('response::service_list_buckets_without_owner_displayname'),
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    expect_data         => [
        all (
            obj_isa ('Net::Amazon::S3::Client::Bucket'),
            methods (name => 'quotes'),
            methods (owner_id => 'bcaf1ffd86f461ca5fb16fd081034f'),
            methods (owner_display_name => ''),
        ),
        all (
            obj_isa ('Net::Amazon::S3::Client::Bucket'),
            methods (name => 'samples'),
            methods (owner_id => 'bcaf1ffd86f461ca5fb16fd081034f'),
            methods (owner_display_name => ''),
        ),
    ],
);

expect_client_list_all_my_buckets 'S3 error - Access Denied' => (
    with_response_fixture ('error::access_denied'),
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    throws              => qr/^AccessDenied: Access denied error message/,
);

expect_client_list_all_my_buckets 'HTTP error - 400 Bad Request' => (
    with_response_fixture ('error::http_bad_request'),
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    throws                  => qr/^400: Bad Request/,
);

had_no_warnings;

done_testing;
