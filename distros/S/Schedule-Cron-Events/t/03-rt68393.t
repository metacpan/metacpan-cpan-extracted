#!/usr/bin/perl
#
# Unit test for https://rt.cpan.org/Ticket/Display.html?id=68393
#
# Handy calendar: http://www.timeanddate.com/calendar/?year=2011
#


use strict;
use warnings;

use lib './lib';
use Test::More 'no_plan';

my $have_test_deep = 1;
eval {
    require Test::Deep;
};
if ($@) {
    $have_test_deep = 0;
}

use Schedule::Cron::Events;

use Data::Dumper;

#              field          allowed values
#              -----          --------------
#              minute         0-59
#              hour           0-23
#              day of month   1-31
#              month          1-12 (or names, see below)
#              day of week    0-7 (0 or 7 is Sun, or use names)

# 14:00 on Monday or Thursday
my $crontime = "00 14 * * 1,4"; # 1,4

#                                                                 12:45, 23 of May, 2011
if ($have_test_deep) {
    my $obj_crontab = Schedule::Cron::Events->new( $crontime, Date => [ 10, 45, 12, 23, 4, 111 ] );
    Test::Deep::cmp_deeply([$obj_crontab->nextEvent()], [0, 0, 14, 23, 4, 111], "23 of May, 2011");
    Test::Deep::cmp_deeply([$obj_crontab->nextEvent()], [0, 0, 14, 26, 4, 111], "26 of May, 2011");
    Test::Deep::cmp_deeply([$obj_crontab->nextEvent()], [0, 0, 14, 30, 4, 111], "30 of May, 2011");
    Test::Deep::cmp_deeply([$obj_crontab->nextEvent()], [0, 0, 14, 2, 5, 111],  "02 of June, 2011");
    Test::Deep::cmp_deeply([$obj_crontab->nextEvent()], [0, 0, 14, 6, 5, 111],  "06 of June, 2011");
    Test::Deep::cmp_deeply([$obj_crontab->nextEvent()], [0, 0, 14, 9, 5, 111],  "09 of June, 2011");
}

my $r = eval {
    my $obj_crontab1 = Schedule::Cron::Events->new( $crontime, Date => [ 10, 45, 12, 23, 4, 2013 ] );
};
if (time() < 2**31 && $@ =~ /Year must be less/) {
    pass("invalid year");
}
else {
    fail("invalid year");
}
