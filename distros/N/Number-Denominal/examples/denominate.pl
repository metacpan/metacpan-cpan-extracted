#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(../lib  lib);

# VERSION

use Number::Denominal;

my $seconds = (localtime)[2]*3600 + (localtime)[1]*60 + (localtime)[2];

local $\ = "\n";
print 'So far today you lived for ',
    denominal($seconds,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/hour hours/ ]
    );

print 'If there were 100 seconds in a minute, and 100 minutes in an hour,',
    ' then you would have lived today for ',
    denominal(
        # This is a shortcut for units that pluralize by adding "s"
        $seconds, second => 100 => minute => 100 => 'hour',
    );

print 'And if we called seconds "foos," minutes "bars," and hours "bers"',
    ' then you would have lived today for ',
    denominal(
        $seconds, foo => 100 => bar => 100 => 'ber',
    );

