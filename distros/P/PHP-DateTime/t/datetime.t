#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use PHP::DateTime;

ok( checkdate(2,12,2001), 'Check a valid date.' );
ok( !checkdate(13,14,2002), 'Check an invalid date.' );

todo 'The date() function not fully implimented yet.' => sub{
    my $secs = mktime(10,11,12,2,3,2004);

    is(
        date('a-A-B-c-d-D-F-g-G-h-H-i-I-J-l-L-m-M-n-O-r-s-S-t-T-U-w-W-y-Y-z-Z',$secs),
        'am-AM-674-c-03-Tue-February-10-10-10-10-11-0-J-Tuesday-1-02-Feb-2--0500-Tue, 3 Feb 2004 10:11:12 -0500-12-rd-29-EST-1075821072-2-6-04-2004-33--18000',
        'All date() formattings are working correctly.'
    );
};

my $now = time;
my @ltimes = localtime($now);
my @gtimes = getdate($now);
ok(
    (
        $gtimes[0]==$ltimes[0] and 
        $gtimes[1]==$ltimes[1] and 
        $gtimes[2]==$ltimes[2] and 
        $gtimes[3]==$ltimes[3] and 
        $gtimes[5]==$ltimes[4]+1 and 
        $gtimes[6]==$ltimes[5]+1900
    ),
    'The function getdate() returns the same times as localtime().'
);

my $g = gettimeofday();
ok(
    int($g->{sec}/100)==int(time()/100),
    'The function gettimeofday() returned the right epoch.'
);

is(
    $now,
    mktime( $ltimes[2], $ltimes[1], $ltimes[0], $ltimes[4]+1, $ltimes[3], $ltimes[5]+1900 ),
    'The function mktime() returned the correct time.'
);

done_testing;
