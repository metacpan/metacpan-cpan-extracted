use strict;
use warnings;
use Test::More 0.98 import => [qw( done_testing use_ok )];

use_ok $_ for qw(
    Namespace::Subroutines
);

done_testing;

