use Test::Most;

use Set::Hash::Keys;

subtest 'Difference from nothing' => sub {
    plan tests => 2;
    
    my $set_t = Set::Hash::Keys::difference();
    
    is $set_t, undef,
        "... returns `undef`";
    
    my @set_t = Set::Hash::Keys::difference();
    
    is scalar @set_t, 0, "Empty list"
    
};

subtest 'Difference Set from Sets' => sub {
    plan tests => 1;
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
        qux => 'C',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'D',
        baz => 'E',
    );
    
    my $set_c = Set::Hash::Keys->new(
        qux => 'F',
    );
    
    my $set_t = Set::Hash::Keys::difference( $set_a, $set_b, $set_c );
    
    note "'difference' in scalar context";
    cmp_deeply(
        { %$set_t } => {
            bar => 'B', # $set_c
        },
        "... contains the right data"
    );
    
};

subtest 'Difference List of Sets from Sets' => sub {
    plan tests => 3;
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
        qux => 'C',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'D',
        baz => 'E',
    );
    
    my $set_c = Set::Hash::Keys->new(
        qux => 'F',
    );
    
    my @set_x = Set::Hash::Keys::difference( $set_a, $set_b, $set_c );
    my $set_t;
    
    $set_t = $set_x[0];
    cmp_deeply(
        { %$set_t } => { bar => 'B' },
        "... contains the right data: one remaining"
    );
    
    $set_t = $set_x[1];
    cmp_deeply(
        { %$set_t } => { baz => 'E' },
        "... contains the right data: one remaining"
    );
    
    $set_t = $set_x[2];
    cmp_deeply(
        { %$set_t } => { },
        "... contains the right data: nil remaining"
    );
    
};

subtest 'Difference Set from HASHREFs' => sub {
    plan tests => 1;
    
    my $set_t = Set::Hash::Keys::difference(
        { foo => 'A', bar => 'B', qux => 'C' },
        { foo => 'D', baz => 'E' },
        { qux => 'E' },
    );
    
    cmp_deeply(
        { %$set_t } => {
            bar => 'B', # $set_a
        },
        "... contains the right data: from three HASHREFs"
    );
    
};

done_testing();
