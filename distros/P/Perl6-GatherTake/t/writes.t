use strict;
use warnings;

use lib qw(lib ../lib);
use Test::More tests => 6;

BEGIN {
    use_ok('Perl6::GatherTake');
}

my $i = 0;
my $list = gather {
    for (;;){
        take $i;
        $i++;
    }
};

eval {
    $list->[2] = 10;
};

ok !$@,             'Assigning to a tied array lives';
is $list->[2],  10, 'Assigning preservese the value';
is $list->[1],  1,  'Other values remain unchanged 1';
is $list->[3],  3,  'Other values remain unchanged 2';
is $i,          3,  'Lazyness remains unaffacted';
