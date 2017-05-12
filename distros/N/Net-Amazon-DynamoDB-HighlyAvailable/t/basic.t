use Test::Most skip_all => 'third party tests';

use Net::Amazon::DynamoDB::HighlyAvailable;

my $ha = Net::Amazon::DynamoDB::HighlyAvailable->new(
    table    => 'server_definitions',
    hash_key => 'node',
    regions  => [qw/us-east-1 us-west-1/],
);

my $node = 'highlyavailable';
my $server_definition = {
    node      => $node,
    flavor    => 'highlyavailable',
    region    => 'highlyavailable',
    zone      => 'highlyavailable',
    hashthing => [{
        a     => 'firstthing',
        b     => 2000,  
        c     => 200,
    }],
};
my $expected_item = {
    %$server_definition,
    last_updated => re(qr/^\d{4}-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}/),
    deleted      => bool(),
};

subtest 'put' => sub {
    $ha->put(Item => $server_definition);

    my $ddbs = $ha->dynamodbs;

    for my $ddb (@$ddbs) {
        my $item = $ddb->get(node => $node);
        cmp_deeply 
            $item,
            $expected_item,
            "item created in " . $ddb->region;
    }
};

subtest 'get' => sub {
    my $item = $ha->get(node => $node);
    cmp_deeply $item, $expected_item, 'got item';

    # update item in one region
    my $ddb = $ha->dynamodbs->[1];
    $item = {
        %$server_definition,
        flavor       => 'highlyavailable2',
        deleted      => 0,
        last_updated => DateTime->now . ""
    };
    $ddb->put(Item => $item);

    $item = $ha->get(node => $node);
    is $item->{flavor}, 'highlyavailable2', 'got most recent item';
};

subtest 'delete' => sub {
    $ha->delete(node => 'boopx1234567890unique');
    $ha->delete(node => $node);

    my $ddbs = $ha->dynamodbs;

    for my $ddb (@$ddbs) {
        my $item = $ddb->get(node => $node );
        ok $item->{deleted}, 'item deleted from all locations';
    }
};

done_testing;
