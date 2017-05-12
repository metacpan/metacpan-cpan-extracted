use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.005 ':no_end_test', ':all';
use Test::Deep;

# Test for a warning when you make the stupid mistake I make all the time
# of saying use MooseX::Types::Common qw/NonEmptySimpleStr/;

require MooseX::Types::Common;

cmp_deeply(
    [ warnings { MooseX::Types::Common->import } ],
    [],
    'No warning if nothing imported',
);

cmp_deeply(
    [ warnings { MooseX::Types::Common->import('NonEmptySimpleStr') } ],
    [ re(qr/Did you mean.*NonEmptySimpleStr/s) ],
    'Warning mentions bad type',
);

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
