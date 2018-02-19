use strict;
use warnings;

use Test::More;

use Perl::Tidy;
use Test::Code::TidyAll;

tidyall_ok(
    verbose => ( exists $ENV{TEST_TIDYALL_VERBOSE} ? $ENV{TEST_TIDYALL_VERBOSE} : 0 ),
    jobs => ( exists $ENV{TEST_TIDYALL_JOBS} ? $ENV{TEST_TIDYALL_JOBS} : 1 ),
);

done_testing;
