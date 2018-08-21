use Test::Most;

use Set::Hash::Keys;

subtest 'Overloading for Union' => sub {
    plan tests => 4;
    
    my $set_t = Set::Hash::Keys->new();
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'C',
        baz => 'D',
    );
    
    $set_t = $set_a + $set_b;
    cmp_deeply(
        { %$set_t } => {
            foo => 'C',
            bar => 'B',
            baz => 'D',
        },
        "... contains the right data: of two sets"
    );
    
    $set_t = $set_a + { bar => 'E', baz => 'F' };
    cmp_deeply(
        { %$set_t } => {
            foo => 'A',
            bar => 'E',
            baz => 'F',
        },
        "... contains the right data: of a set and a hashref"
    );

    $set_t = { bar => 'E', baz => 'F' } + $set_a;
    cmp_deeply(
        { %$set_t } => {
            foo => 'A',
            bar => 'B',
            baz => 'F',
        },
        "... contains the right data: of a hashref and a set"
    );
    
    $set_t += { foo => 'G', qux => 'H'};
    cmp_deeply(
        { %$set_t } => {
            foo => 'G',
            bar => 'B',
            baz => 'F',
            qux => 'H',
        },
        "... contains the right data: assignment"
    );
};

subtest 'Overloading for Difference' => sub {
    plan tests => 4;
    
    my $set_t = Set::Hash::Keys->new();
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'C',
        baz => 'D',
    );
    
    $set_t = $set_a - $set_b;
    cmp_deeply(
        { %$set_t } => {
            bar => 'B',
        },
        "... contains the right data: of two sets"
    );
    
    $set_t = $set_a - { bar => 'E', baz => 'F' };
    cmp_deeply(
        { %$set_t } => {
            foo => 'A',
        },
        "... contains the right data: of a set and a hashref"
    );

    $set_t = { bar => 'E', baz => 'F', qux => 'G' } - $set_a;
    cmp_deeply(
        { %$set_t } => {
            baz => 'F',
            qux => 'G',
        },
        "... contains the right data: of a hashref and a set"
    );
    
    $set_t -= { foo => 'H', qux => 'I'};
    cmp_deeply(
        { %$set_t } => {
            baz => 'F',
        },
        "... contains the right data: assignment"
    );
};

subtest 'Overloading for Intersection' => sub {
    plan tests => 4;
    
    my $set_t = Set::Hash::Keys->new();
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'C',
        baz => 'D',
    );
    
    $set_t = $set_a * $set_b;
    cmp_deeply(
        { %$set_t } => {
            foo => 'C',
        },
        "... contains the right data: of two sets"
    );
    
    $set_t = $set_a * { bar => 'E', baz => 'F' };
    cmp_deeply(
        { %$set_t } => {
            bar => 'E',
        },
        "... contains the right data: of a set and a hashref"
    );

    $set_t = { bar => 'E', baz => 'F' } * $set_a;
    cmp_deeply(
        { %$set_t } => {
            bar => 'B',
        },
        "... contains the right data: of a hashref and a set"
    );
    
    $set_t *= { bar => 'G', qux => 'H'};
    cmp_deeply(
        { %$set_t } => {
            bar => 'G',
        },
        "... contains the right data: assignment"
    );
};

subtest 'Overloading for Symmetrical' => sub {
    plan tests => 4;
    
    my $set_t = Set::Hash::Keys->new();
    
    my $set_a = Set::Hash::Keys->new(
        foo => 'A',
        bar => 'B',
    );
    
    my $set_b = Set::Hash::Keys->new(
        foo => 'C',
        baz => 'D',
    );
    
    $set_t = $set_a % $set_b;
    cmp_deeply(
        { %$set_t } => {
            bar => 'B',
            baz => 'D',
        },
        "... contains the right data: of two sets"
    );
    
    $set_t = $set_a % { bar => 'E', baz => 'F' };
    cmp_deeply(
        { %$set_t } => {
            foo => 'A',
            baz => 'F',
        },
        "... contains the right data: of a set and a hashref"
    );

    $set_t = { bar => 'E', baz => 'F' } % $set_a;
    cmp_deeply(
        { %$set_t } => {
            foo => 'A',
            baz => 'F',
        },
        "... contains the right data: of a hashref and a set"
    );
    
    $set_t %= { baz => 'G', qux => 'H'};
    cmp_deeply(
        { %$set_t } => {
            foo => 'A',
            qux => 'H',
        },
        "... contains the right data: assignment"
    );
};

done_testing();
