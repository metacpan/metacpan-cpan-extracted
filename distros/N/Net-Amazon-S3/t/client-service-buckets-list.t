
use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep v0.111; # 0.111 => obj_isa
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ with_response_fixture ],
    qw[ expect_client_list_all_my_buckets ],
);

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

expect_client_list_all_my_buckets 'list all my buckets without displayname' => (
    with_response_fixture ('error::access_denied'),
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    throws              => qr/^AccessDenied: Access denied error message/,
);

had_no_warnings;
