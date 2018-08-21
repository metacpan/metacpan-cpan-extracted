use Test::Most;

use Set::Hash::Keys;

subtest 'Intersection from nothing' => sub {
    plan tests => 1;
    
    my $set_t = Set::Hash::Keys::intersection();
    
    is $set_t, undef,
        "... returns `undef`";
    
};

subtest 'Intersection from sets' => sub {
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
        bar => 'F',
    );
    
    my $set_t = Set::Hash::Keys::intersection( $set_a, $set_b, $set_c );
    
    cmp_deeply(
        { %$set_t } => {
            foo => 'E', # $set_c
        },
        "Intersection from three sets"
    );
    
};

subtest 'Intersection from HASHREFs' => sub {
    plan tests => 1;
    
    my $set_t = Set::Hash::Keys::intersection(
        { foo => 'A', bar => 'B' },
        { foo => 'C', baz => 'D' },
        { foo => 'E', bar => 'F' },
    );
    
    cmp_deeply(
        { %$set_t } => {
            foo => 'E', # $set_c
        },
        "Intersection from three HASHREFs"
    );
    
};

done_testing();
