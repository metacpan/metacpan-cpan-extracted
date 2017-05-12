#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

use Schedule::Poll;

my $poll = Schedule::Poll->new({
    foo => 3,
    zoo => 3,
    boo => 3,
    doo => 3,
    bat => 6,
    zat => 6
});

my $x = 0;
while ($x < 6)  {
    ok($poll->which);
    $x++;
    sleep 1;

}

    
