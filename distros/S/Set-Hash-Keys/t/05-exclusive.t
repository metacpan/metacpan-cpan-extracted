use Test::Most;

use Set::Hash::Keys;

subtest 'Exclusive from nothing' => sub {
    plan tests => 2;
    
    my $set_t = Set::Hash::Keys::exclusive();
    
    is $set_t, undef,
        "... returns `undef`";
    
    my @set_t = Set::Hash::Keys::exclusive();
    
    is scalar @set_t, 0, "Empty list"
    
};

subtest 'Exclusive List of Sets from Sets' => sub {
    plan tests => 3;
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'C',
        bar => 'D',
        baz => 'E',
    );
    
    my $set_c = Set::Hash::Keys->new(
        qux => 'F',
    );
    
    note "'exclusive' in list context";
    my @set_x = Set::Hash::Keys::exclusive( $set_a, $set_b, $set_c );
    my $set_t;
    
    $set_t = $set_x[0];
    cmp_deeply(
        { %$set_t } => { },
        "... contains the right data: non remaining"
    );
    
    $set_t = $set_x[1];
    cmp_deeply(
        { %$set_t } => { baz => 'E' },
        "... contains the right data: one remaining"
    );
    
    $set_t = $set_x[2];
    cmp_deeply(
        { %$set_t } => { qux => 'F' },
        "... contains the right data: all remaining"
    );
    
};

subtest 'Exclusive Set from Sets' => sub {
    plan tests => 1;
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'C',
        baz => 'D',
    );
    
    my $set_c = Set::Hash::Keys->new(
        foo => 'E',
        qux => 'F',
    );
    
    my $set_t = Set::Hash::Keys::exclusive( $set_a, $set_b, $set_c );
    
    note "'exclusive' in scalar context";
    cmp_deeply(
        { %$set_t } => {
            bar => 'B', # $set_a
            baz => 'D', # $set_b
            qux => 'F', # $set_c
        },
        "... contains the right data"
    );
    
};

done_testing();
