use Test::DescribeMe qw(author);
use Test::Fatal;
use Test::More;
use strict;
use warnings;

use PawsX::DynamoDB::DocumentClient;
use PerlX::Maybe qw(provided);
use UUID::Tiny ':std';

# Expected table:
#   Partition key: user_id (String)
#   GSI "team_id-create_time-index":
#     Partition key: team_id (String)

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

my $dynamodb = PawsX::DynamoDB::DocumentClient->new();

my $item1 = {
    user_id => create_uuid_as_string(),
    team_id => create_uuid_as_string(),
};

my $item2 = {
    user_id => int(rand(100000)),
    team_id => create_uuid_as_string(),
};

my $item3 = {
    user_id => create_uuid_as_string(),
    team_id => int(rand(100000)),
};

my $item4 = {
    user_id => create_uuid_as_string(),
    team_id => undef,
};

my $force_type = {
    user_id => 'S',
    team_id => 'S',
};

my $do_put = sub {
    my ($item, $do_force_type) = @_;
    return $dynamodb->put(
        TableName => $table_name,
        Item      => $item,
        provided $do_force_type, force_type => $force_type,
    );
};

is(
    exception { $do_put->($item1, 0) },
    undef,
    'put() lives for item w/o force_type and all-string data',
);

like(
    exception { $do_put->($item2, 0) },
    qr/Type mismatch for key user_id/,
    'put() dies for item w/o force_type and numeric user_id',
);

like(
    exception { $do_put->($item3, 0) },
    qr/Type mismatch for Index Key team_id/,
    'put() dies for item w/o force_type and numeric team_id',
);

like(
    exception { $do_put->($item4, 0) },
    qr/Type mismatch for Index Key team_id/,
    'put() dies for item w/o force_type and undef team_id',
);

is(
    exception { $do_put->($item2, 1) },
    undef,
    'put() lives for item w/ force_type and numeric user_id',
);

is(
    exception { $do_put->($item3, 1) },
    undef,
    'put() lives for item w/ force_type and numeric team_id',
);

is(
    exception { $do_put->($item4, 1) },
    undef,
    'put() lives for item w/ force_type and undef team_id',
);

done_testing;
