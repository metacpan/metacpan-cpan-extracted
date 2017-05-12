use strict;
use warnings;

use lib qw(lib ../lib);
use Test::More tests => 6;

BEGIN {
    use_ok('Perl6::GatherTake');
}

my $i = 0;
my $list = gather {
    my $sublist = gather {
        take 1, 2;

    };
    is $sublist->[0],   1,      'inner gather 1';
    is $sublist->[1],   2,      'inner gather 2';
    take 3;
    take @$sublist;
};

is $list->[0],      3,      'outer gather 1';
is $list->[1],      1,      'outer gather 2';
is $list->[2],      2,      'outer gather 3';
