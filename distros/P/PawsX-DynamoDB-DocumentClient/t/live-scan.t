use Test::DescribeMe qw(author);
use Test::Deep;
use Test::Fatal;
use Test::More;
use strict;
use warnings;

use PawsX::DynamoDB::DocumentClient;
use PerlX::Maybe;
use UUID::Tiny ':std';

sub do_scans {
    my %args = @_;
    my $dynamodb = $args{dynamodb};
    my $table_name = $args{table_name};
    my $user_ids = $args{user_ids};
    my $start = $args{start};
    my $last_evaluated_key = $args{last_evaluated_key};
    my $items = $args{items} || [];
    my $elapsed_warned = $args{elapsed_warned} || 0;

    if (!$elapsed_warned && (time - $start) > 5) {
        warn "this test is taking awhile to run, you might want to truncate $table_name\n";
        $elapsed_warned = 1;
    }

    my %attr_values;
    for (my $i = 0; $i < @$user_ids; $i++) {
        $attr_values{":user_id${i}"} = $user_ids->[$i];
    }

    my $filter = join(
        ' OR ',
        (map { "user_id = $_" } keys %attr_values),
    );

    my %scan_params = (
        TableName => $table_name,
        ExpressionAttributeValues => \%attr_values,
        FilterExpression => $filter,
        Limit => 2,
        maybe ExclusiveStartKey => $last_evaluated_key,
    );

    my $results = $dynamodb->scan(%scan_params);
    push @$items, @{$results->{items}};

    if (my $key = $results->{last_evaluated_key}) {
        return do_scans(
            %args,
            last_evaluated_key => $key,
            items => $items,
            elapsed_warned => $elapsed_warned,
        );
    }

    return $items;
}

# Expected table:
#   Partition key: user_id (String)

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

my $dynamodb = PawsX::DynamoDB::DocumentClient->new();

my $user_id1 = create_uuid_as_string();
my $item1 = {
    user_id => $user_id1,
    email => 'jdoe@example.com',
};

my $user_id2 = create_uuid_as_string();
my $item2 = {
    user_id => $user_id2,
    email => 'bsmith@example.com',
};

my $user_id3 = create_uuid_as_string();
my $item3 = {
    user_id => $user_id3,
    email => 'hjohnson@example.com',
};

$dynamodb->batch_write(
    RequestItems => {
        $table_name => [
            { PutRequest => { Item => $item1 } },
            { PutRequest => { Item => $item2 } },
            { PutRequest => { Item => $item3 } },
        ],
    },
);

my $results;
is(
    exception {
        $results = do_scans(
            dynamodb => $dynamodb,
            table_name => $table_name,
            user_ids => [$user_id1, $user_id2, $user_id3],
            start => time,
        );
    },
    undef,
    'scan() lives',
);

cmp_deeply(
    $results,
    set($item1, $item2, $item3),
    'items fetched correctly',
);

done_testing;
