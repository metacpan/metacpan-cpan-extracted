use Test::Most;

use Set::Hash::Keys;

subtest 'Union from nothing' => sub {
    plan tests => 1;
    
    my $set_t = Set::Hash::Keys::union();
    
    is $set_t, undef,
        "... returns `undef`";
    
};

subtest 'Union form sets' => sub {
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
        baz => 'E',
        qux => 'F',
    );
    
    my $set_t = Set::Hash::Keys::union( $set_a, $set_b, $set_c );
    
    cmp_deeply(
        { %$set_t } => {
            bar => 'B', # $set_a
            baz => 'E', # $set_c
            foo => 'C', # $set_b
            qux => 'F', # $set_c
        },
        "Union from three sets"
    );
    
};

subtest 'Union from HASHREFs' => sub {
    plan tests => 1;
    
    my $set_t = Set::Hash::Keys::union(
        { foo => 'A', bar => 'B' },
        { foo => 'C', baz => 'D' },
        { baz => 'E', qux => 'F' },
    );
    
    cmp_deeply(
        { %$set_t } => {
            bar => 'B', # $set_a
            baz => 'E', # $set_c
            foo => 'C', # $set_b
            qux => 'F', # $set_c
        },
        "Union from three HASHREFs"
    );
    
};

done_testing();
