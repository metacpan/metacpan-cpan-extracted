use strict;
use warnings;
use utf8;
use Test::Base::SubTest;

filters {
    input => [qw/eval/],
};

run_is;

done_testing;
__DATA__

###
    ===
    --- input   : 1+1
    --- expected: 2
### foo
    ===
    --- input   : 1+1
    --- expected: 2
### foo bar
    ===
    --- input   : 1+1
    --- expected: 2
