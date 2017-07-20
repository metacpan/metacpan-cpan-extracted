use Test::DescribeMe qw(author);
use Test::Fatal;
use Test::More;
use strict;
use warnings;

use PawsX::DynamoDB::DocumentClient;
use Time::HiRes qw(gettimeofday);
use UUID::Tiny ':std';

sub make_run_update {
    my ($dynamodb, $table_name, $user_id) = @_;
    return sub {
        my %args = @_;
        my $time = gettimeofday;
        my %update_args = (
            TableName => $table_name,
            Key => {
                user_id => $user_id,
            },
            ExpressionAttributeValues => {
                ':update_time' => $time,
            },
            UpdateExpression => 'SET update_time = :update_time',
            %args,
        );
        my $result = $dynamodb->update(%update_args);
        return ($result, $time);
    };
}

# Expected table:
#   Partition key: user_id (String)

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

my $dynamodb = PawsX::DynamoDB::DocumentClient->new();

my $user_id = create_uuid_as_string();
my $item = {
    user_id => $user_id,
    email => 'jdoe@example.com',
};

my $run_update = make_run_update($dynamodb, $table_name, $user_id);

$dynamodb->put(
    TableName => $table_name,
    Item => $item,
);

my ($output, $first_update_time);
is(
    exception {
        ($output, $first_update_time) = $run_update->();
    },
    undef,
    'update() lives',
);
is($output, undef, 'no output by default');
ok($first_update_time, 'test method returns update time');

my $second_update_time;
is(
    exception {
        ($output, $second_update_time) = $run_update->(
            ReturnValues => 'UPDATED_OLD',
        );
    },
    undef,
    'update() lives',
);
is_deeply(
    $output,
    {
        update_time => $first_update_time,
    },
    'old update_time returned when ReturnValues == "UPDATED_OLD"',
);

isnt($first_update_time, $second_update_time, 'test is generating new update times');

my $fetched = $dynamodb->get(
    TableName => $table_name,
    Key => {
        user_id => $user_id,
    },
    ConsistentRead => 1,
);

is($fetched->{update_time}, $second_update_time, 'item updated');

done_testing;
