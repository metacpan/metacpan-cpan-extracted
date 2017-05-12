use Test::Most skip_all => 'third party tests';

use Net::Amazon::DynamoDB::HighlyAvailable;

my $table;
my $node   = 'boopNode';  # unique name
my $flavor = 'f';
my $cfg    = {
    super         => $node,
    flavor        => $flavor,
    region        => 'r',
    zone          => 'z',
    environment   => 'e',
    hashthing           => [{
        a           => 'firstthing',
        b           => 200,
        c           => 2000,
    }],
    domain        => 'd',
    instance_type => 'i',
    listthing     => [qw/a b c/],
};

subtest 'setup' => sub {
    $table = Net::Amazon::DynamoDB::HighlyAvailable->new(
        table    => 'test',
        hash_key => 'super',
        regions  => [qw/us-east-1 us-west-1/],
    );

    # permanently delete item from all dynamodbs
    $table->permanent_delete(super => $node);

    pass "done";
};

subtest 'sync: update old records' => sub {
    my %item = (
        super      => $node,
        flavor     => $cfg->{flavor},
        region     => $cfg->{region},
        zone       => $cfg->{zone},
    );

    # save to all dynamodbs
    $table->put(Item => \%item);
    sleep 1;

    # update one dynamodb
    $table->dynamodbs->[0]->put(Item => {
        %item, 
        zone         => 'z',
        deleted      => 0,
        last_updated => DateTime->now() . "",
    });

    # sync
    $table->sync_regions;

    # check that sync worked
    my $saved_items = {};
    for my $i (0, 1) {
        $saved_items->{$i} = $table->dynamodbs->[$i]->get(super => $node);

        cmp_deeply $saved_items->{$i}, {
            %item,
            zone         => 'z',
            deleted      => 0,
            last_updated => re(qr/^\d{4}-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}/),
        }, "saved server definition to dynamodb $i";
    }

    # cleanup: permanently delete item from all dynamodbs
    $table->permanent_delete(super => $node);
};

subtest 'sync: create new records' => sub {
    my %item = (
        super  => $node,
        flavor => $cfg->{flavor},
        region => $cfg->{region},
        zone   => $cfg->{zone},
    );

    # create item on one dynamodb
    $table->dynamodbs->[0]->put(Item => {
        %item, 
        deleted      => 0,
        last_updated => DateTime->now() . "",
    });

    # sync
    $table->sync_regions;

    # check that sync worked
    my $saved_items = {};
    for my $i (0, 1) {
        $saved_items->{$i} = $table->dynamodbs->[$i]->get(super => $node);

        cmp_deeply $saved_items->{$i}, { 
            %item,
            deleted      => 0,
            last_updated => re(qr/^\d{4}-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}/),
        }, "saved server definition to dynamodb $i";
    }

    # cleanup: permanently delete item from all dynamodbs
    $table->permanent_delete(super => $node);
};

done_testing;
