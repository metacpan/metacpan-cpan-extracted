use strict;
use warnings;
use Test::More 0.96;

use Search::Binary;
use lib 't/lib';
use Search::Binary::TestUtils qw(make_numeric_array_reader);

# Tests borrowed from List::BinarySearch
# See https://metacpan.org/source/DAVIDO/List-BinarySearch-0.20/t/11-search.t

my @integers    = ( 100, 200, 300, 400, 500 );
my @even_length = ( 100, 200, 300, 400, 500, 600 );
my @non_unique  = ( 100, 200, 200, 400, 400, 400, 500, 500 );

subtest "Numeric comparator tests (odd-length list)." => sub {
    plan tests => 5;
    for my $ix ( 0 .. $#integers ) {
        is( binary_search( 0, $#integers, $integers[$ix], make_numeric_array_reader(\@integers) ),
            $ix,
            "binary_search:       Integer ($integers[$ix]) "
                . "found in position ($ix)."
        );
    }
    done_testing();
};

subtest "Even length list tests." => sub {
    plan tests => 6;
    for my $ix ( 0 .. $#even_length ) {
        is( binary_search( 0, $#even_length, $even_length[$ix], make_numeric_array_reader(\@even_length) ),
            $ix,
            "binary_search:       Even-list: ($even_length[$ix])"
                . " found at index ($ix)."
        );
    }
    done_testing();
};

subtest "Non-unique key tests (stable search guarantee)." => sub {
    plan tests => 3;
    is( binary_search( 0, $#non_unique, 200, make_numeric_array_reader(\@non_unique) ),
        1,
        "binary_search:       First non-unique key of 200 found at 1." );
    is( binary_search( 0, $#non_unique, 400, make_numeric_array_reader(\@non_unique) ),
        3,
        "binary_search:       First occurrence of 400 found at 3 "
            . "(odd index)."
    );

    is( binary_search( 0, $#non_unique, 500, make_numeric_array_reader(\@non_unique) ),
        6,
        "binary_search:       First occurrence of 500 found at 6 "
            . "(even index)."
    );

    done_testing();
};

my @new_test = ( 100, 200, 300 );
my $found_ix = binary_search 0, $#new_test, 200, make_numeric_array_reader(\@new_test);
is( $found_ix, 1, 'binary_search returns correct found index.' );
$found_ix = binary_search 0, $#new_test, 250, make_numeric_array_reader(\@new_test);
is( $found_ix, 2, 'binary_search returns correct insertion point.' );
$found_ix = binary_search 0, $#new_test, 350, make_numeric_array_reader(\@new_test);
is( $found_ix, 3, 'binary_search returns correct insertion point for value greater than all elements.' );

done_testing();
