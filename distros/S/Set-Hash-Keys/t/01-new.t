use Test::Most;

use Set::Hash::Keys;

subtest 'Constructing' => sub {
    plan tests => 7;
    
    my $set_0;
    lives_ok {
        $set_0 = Set::Hash::Keys->new();
    }
    "Can create an object from nothing";
    isa_ok $set_0, 'Set::Hash::Keys';
    cmp_deeply(
        { %$set_0 } => { },
        "... and is empty"
    );
    
    my $set_1;
    lives_ok {
        $set_1 = Set::Hash::Keys->new(
            foo => 1,
        );
    }
    "Can create an object from 1 key/value pair";
    cmp_deeply(
        { %$set_1 } => {
            foo => 1,
        },
        "... and looks like a hashref"
    );
    
    my $set_2;
    lives_ok {
        $set_2 = Set::Hash::Keys->new(
            bar => 1,
            buz => 2,
        );
    }
    "Can create an object from 2 key/value pairs";
    cmp_deeply(
        { %$set_2 } => {
            bar => 1,
            buz => 2,
        },
        "... and contains the correct data"
    );
    
};

subtest 'Keys and Values' => sub {
    plan tests => 2;
    
    my $set_x = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
    );
    my @keys = keys %$set_x;
    cmp_bag(
        \@keys => [
            'bar',
            'foo',
        ],
        "Set allows function 'keys'"
    );
    my @vals = values %$set_x;
    cmp_bag(
        \@vals => [
            'B',
            'A',
        ],
        "Set allows function 'values'"
    );
    
};

done_testing();
