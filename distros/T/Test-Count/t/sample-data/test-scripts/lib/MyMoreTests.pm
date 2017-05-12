package MyMoreTests;

use strict;
use warnings;

# TEST:$cnt=0;
sub my_more_test
{
    # TEST:$cnt++;
    ok (1, "Hello");

    # TEST:$cnt++;
    is ("SampleStr", "SampleStr", "String compare");
}

# TEST:$my_more_tests_number=$cnt;

1;

