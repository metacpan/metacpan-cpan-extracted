use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN {
    use_ok('MooseX::ConfigFromFile');
}

done_testing;
