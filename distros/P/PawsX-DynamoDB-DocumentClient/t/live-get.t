use Test::DescribeMe qw(author);
use Test::Fatal;
use Test::More;
use strict;
use warnings;

use PawsX::DynamoDB::DocumentClient;
use UUID::Tiny ':std';

# Expected table:
#   Partition key: user_id (String)

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

my $dynamodb = PawsX::DynamoDB::DocumentClient->new();

my $user_id = create_uuid_as_string();
$dynamodb->put(
    TableName => $table_name,
    Item => {
        user_id => $user_id,
        email => 'jdoe@example.com',
    },
);

my %get_args = (
    TableName => $table_name,
    Key => {
        user_id => $user_id,
    },
    ConsistentRead => 1,
);

my $output;
is(
    exception {
        $output = $dynamodb->get(%get_args);
    },
    undef,
    'get() lives',
);
is_deeply(
    $output,
    {
        user_id => $user_id,
        email => 'jdoe@example.com',
    },
    'item returned',
);

is(
    exception {
        $output = $dynamodb->get(
            %get_args,
            Key => {
                %{$get_args{Key}},
                user_id => create_uuid_as_string(),
            },
        );
    },
    undef,
    'get() lives on missing item',
);
is(
    $output,
    undef,
    'undef returned on missing item',
);

done_testing;
