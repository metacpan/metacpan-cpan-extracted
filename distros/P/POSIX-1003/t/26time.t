#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More;

use POSIX::1003::Time qw(CLOCKS_PER_SEC strftime localtime strptime);

# constant from POSIX.xs
ok(defined CLOCKS_PER_SEC, 'CLOCKS_PER_SEC='.CLOCKS_PER_SEC);

my $stamp = strftime "%FT%TZ", localtime;
ok(length $stamp, "strftime $stamp");

use POSIX::1003::Time;  # try load all


my $date1 = "2015-04-22T21:06:52";
my $tm = strptime $date1, "%Y-%m-%dT%H:%M:%S";
if(defined $tm)
{   is($tm->{year},'2015', 'strptime year');
    is($tm->{month},  '4', 'strptime month');
    is($tm->{day},   '22', 'strptime day');
    is($tm->{hour},  '21', 'strptime hour');
    is($tm->{min},    '6', 'strptime minute');
    is($tm->{sec},   '52', 'strptime second');
}
else
{   diag "strptime not supported";
}

my ($sec, $min, $hour, $mday, $mon, $yr) = strptime $date1, "%Y-%m-%dT%H:%M:%S";
if(defined $sec)
{   is($yr,  '115', 'strptime yr');
    is($mon,   '3', 'strptime mon');
    is($mday, '22', 'strptime mday');
    is($hour, '21', 'strptime hour');
    is($min,   '6', 'strptime minute');
    is($sec,  '52', 'strptime second');
}
else
{   diag "strptime not supported";
}

done_testing;
