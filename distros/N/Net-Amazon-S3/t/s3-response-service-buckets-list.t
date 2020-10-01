#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-s3-response.pl" }

plan tests => 3;

behaves_like_s3_response 'list all my buckets with displayname' => (
    response_class      => 'Net::Amazon::S3::Operation::Buckets::List::Response',

    with_response_fixture ('response::service_list_buckets_with_owner_displayname'),

    expect_success      => 1,
    expect_error        => 0,
    expect_data         => {
        owner_id          => 'bcaf1ffd86f461ca5fb16fd081034f',
        owner_displayname => 'webfile',
        buckets           => [{
            name          => 'quotes',
            creation_data => '2006-02-03T16:45:09.000Z',
        }, {
            name          => 'samples',
            creation_data => '2006-02-03T16:41:58.000Z',
        }],
    },
);

behaves_like_s3_response 'list all my buckets without displayname' => (
    response_class      => 'Net::Amazon::S3::Operation::Buckets::List::Response',

    with_response_fixture ('response::service_list_buckets_without_owner_displayname'),

    expect_success      => 1,
    expect_error        => 0,
    expect_data         => {
        owner_id          => 'bcaf1ffd86f461ca5fb16fd081034f',
        owner_displayname => 'webfile',
        buckets           => [{
            name          => 'quotes',
            creation_data => '2006-02-03T16:45:09.000Z',
        }, {
            name          => 'samples',
            creation_data => '2006-02-03T16:41:58.000Z',
        }],
    },
);

had_no_warnings;
