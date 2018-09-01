
use strict;
use warnings;

use Test::More tests => 1 + 3;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ expect_client_list_all_my_buckets ],
);

use Shared::Examples::Net::Amazon::S3::Operation::Service::Buckets::List (
    qw[ buckets_list_with_displayname ],
    qw[ buckets_list_without_displayname ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
);

expect_client_list_all_my_buckets 'list all my buckets with displayname' => (
    with_response_data  => buckets_list_with_displayname,
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
    with_response_data  => buckets_list_without_displayname,
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
    fixture_error_access_denied,
    expect_request      => { GET => 'https://s3.amazonaws.com/' },
    throws              => qr/^AccessDenied: Access denied error message/,
);

