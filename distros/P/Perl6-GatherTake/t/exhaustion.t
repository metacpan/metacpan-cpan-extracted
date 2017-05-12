use strict;
use warnings;

use lib qw(lib ../lib);
use Test::More tests => 3;

BEGIN {
    use_ok('Perl6::GatherTake');
}

my $list = gather {
    for (0 .. 2){
        take $_;
    }
};

is $list->[2],      2,      'Last element accessible';
ok !exists $list->[3],      "further elements don't exists";
