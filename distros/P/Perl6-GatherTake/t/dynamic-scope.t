use strict;
use warnings;

use lib qw(lib ../lib);
use Test::More tests => 2;

BEGIN {
    use_ok('Perl6::GatherTake');
}

sub my_take {
    take 2;
}

my $list = gather {
    my_take();
};

is $list->[0],      2,      'outer gather 1';
