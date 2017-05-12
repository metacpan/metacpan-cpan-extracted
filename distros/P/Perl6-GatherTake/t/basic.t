use strict;
use warnings;

use lib qw(lib ../lib);
use Test::More tests => 6;

BEGIN {
    use_ok('Perl6::GatherTake');
}

my $i = 0;
my $list = gather { 
    while ($i < 10) { 
        take $i++;
    }
};

$Coro::idle = sub { die "Internal Error!\n"; };

is $i,              0,      'iterator not yet started';
is $list->[0],      0,      'first value correct'; 
is $i,              1,      'take() only called ones';
is $list->[2],      2,      'Third element correct';
ok exists $list->[0],       'exists()';
