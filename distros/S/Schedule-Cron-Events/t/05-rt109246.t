#!/usr/bin/perl
#
# https://rt.cpan.org/Public/Bug/Display.html?id=109246
#

use strict;
use warnings;

use lib './lib';
use Test::More;

use Schedule::Cron::Events;
use Data::Dumper;

plan(tests => 1);

my $obj_crontab1 = eval {
#    Schedule::Cron::Events->new(" 2 2 31 2 * ");
    Schedule::Cron::Events->new(" 2 2 31 2 * ");
};

if ($@ =~ /does not define any valid point in time/) {
    ok("detected invalid day of month: https://rt.cpan.org/Public/Bug/Display.html?id=109246");
}
else {
    fail("unexpected output: " . $@);
}
