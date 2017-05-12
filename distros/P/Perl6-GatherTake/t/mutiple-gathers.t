use strict;
use warnings;

use lib qw(lib ../lib);
use Test::More tests => 13;
use Carp qw(confess);

BEGIN {
    use_ok('Perl6::GatherTake');
}

# we don't use infinite loops here because if it doesn't work
# the test shouldn't hang
my $ia = 0;
my $a = gather { 
    while ($ia < 10) { 
        take $ia++;
    }
};

my $ib = 'a';
my $b = gather {
    while ($ib lt 'i'){
        take $ib++;
    }
};

for (0 .. 4){
    is $a->[$_],    $_,         "gather from first iterator works ($_)";
}

my $target = 'a';
for (0 .. 4){
    is $b->[$_],    $target,    "gather from second iterator works ($_)";
    $target++;
}

is $a->[5],         5,          "gather from first iterator still works";
is $b->[5],         $target,    "gather from second iterator still works";
