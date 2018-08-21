use Test::Most;

use Set::Hash::Keys;

subtest 'Symmetrical from nothing' => sub {
    plan tests => 1;
    
    my $set_t = Set::Hash::Keys::symmetrical();
    
    is $set_t, undef,
        "... returns `undef`";
    
};

subtest 'Symmetrical from sets' => sub {
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
    
    my $set_t = Set::Hash::Keys::symmetrical( $set_a, $set_b, $set_c );
    
    cmp_deeply(
        { %$set_t } => {
            foo => 'E', # $set_c
            bar => 'B', # $set_a
            baz => 'D', # $set_b
            qux => 'F', # $set_c
        },
        "Symmetrical from three sets"
    );
    
};

done_testing();
