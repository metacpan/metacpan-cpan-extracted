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
my $item = {
    user_id => $user_id,
    email => 'jdoe@example.com',
};

my %args = (
    TableName => $table_name,
    Item => $item,
);

my $output;
is(
    exception {
        $output = $dynamodb->put(%args);
    },
    undef,
    'put() lives',
);
is($output, undef, 'no output by default');

is(
    exception {
        $output = $dynamodb->put(%args, return_paws_output => 1);
    },
    undef,
    'put() lives, w/ return_paws_output set',
);

isa_ok($output, 'Paws::DynamoDB::PutItemOutput',
    'output object returned when return_paws_output is set');

is(
    exception {
        $output = $dynamodb->put(
            TableName => $table_name,
            Item => {
                %$item,
                email => 'bsmith@example.com',
            },
            ReturnValues => 'ALL_OLD',
        );
    },
    undef,
    'put() lives',
);
is_deeply(
    $output,
    $item,
    q|old item returned when ReturnValues == 'ALL_OLD'|,
);

done_testing;
