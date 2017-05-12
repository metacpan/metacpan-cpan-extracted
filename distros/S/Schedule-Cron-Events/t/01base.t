#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';
use Test;

BEGIN {
  $ENV{'TZ'} ||= 'GMT';
}

use Schedule::Cron::Events;
use Time::Local;
use Data::Dumper;

# $Id: 01base.t,v 1.3 2002/09/25 23:47:45 piers Exp $

#*Schedule::Cron::Events::TRACE = sub {
# my $str = shift;
# print "## $str\n";
#};

my $obj;
my @rv;

plan tests => 103;

# check comments are not allowed
$obj = new Schedule::Cron::Events('# this is a comment', Date => [0, 0, 15, 14, 1, 101]);
ok(! $obj); # object creation


# check default time setting
$obj = new Schedule::Cron::Events('* * * * * /bin/date');
ok($obj); # object creation

my $now = time();
@rv = $obj->nextEvent;
my $next = timelocal( @rv );
ok( $next - $now < 62 );  # event should occure in about a minute's time


# set to 1 day in the future - the 1 minute window is to allow boundary conditions and leap seconds
$obj->setCounterToDate( (localtime(time()+86400))[0..5] );
$next = timelocal( $obj->nextEvent );
ok($next - $now < 86462);
ok($next - $now > 86398);


# test the ...ToNow method
$obj->setCounterToNow;
$next = timelocal( $obj->nextEvent );
ok( $next - $now < 122 );


# job runs on 29th of the month, set date to february in a nonleap year
$obj = new Schedule::Cron::Events('1 1 29 * * /bin/date', Date => [0, 0, 15, 14, 1, 101]);
ok($obj); # object creation

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 29, 2, 101]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 29, 3, 101]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 29, 4, 101]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 29, 0, 101]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 29, 11, 100]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 29, 10, 100]);


# job runs on 29th of the month, set date to february in a leap year
$obj = new Schedule::Cron::Events('1 1 29 * * /bin/date', Date => [0, 0, 15, 14, 1, 96]);
ok($obj); # object creation

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 29, 1, 96]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 29, 2, 96]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 29, 3, 96]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 29, 0, 96]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 29, 11, 95]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 29, 10, 95]);


# job runs on 31st of the month, set date to february in a nonleap year
$obj = new Schedule::Cron::Events('1 1 31 * * /bin/date', Date => [0, 0, 15, 14, 1, 101]);
ok($obj); # object creation

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 31, 2, 101]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 31, 4, 101]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 31, 6, 101]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 31, 0, 101]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 31, 11, 100]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 31, 9, 100]);


# job runs on 1st of the month, set date to february in a nonleap year
$obj = new Schedule::Cron::Events('1 1 1 * * /bin/date', Date => [0, 0, 15, 14, 1, 101]);
ok($obj); # object creation

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 1, 2, 101]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 1, 3, 101]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 1, 1, 1, 4, 101]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 1, 1, 101]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 1, 0, 101]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 1, 1, 1, 11, 100]);


# job runs once a week on sunday
$obj = new Schedule::Cron::Events('12 21 * * 0 /bin/date', Date => [0, 10, 15, 9, 8, 102]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 12, 21, 15, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 12, 21, 22, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 12, 21, 29, 8, 102]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 12, 21, 8, 8, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 12, 21, 1, 8, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 12, 21, 25, 7, 102]);


# job runs once a week on sunday
$obj = new Schedule::Cron::Events('12 21 * * 7 /bin/date', Date => [0, 10, 15, 9, 8, 102]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 12, 21, 15, 8, 102]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 12, 21, 8, 8, 102]);


# job runs twice a week on tuesdays and thursdays
$obj = new Schedule::Cron::Events('12 21 * * 2,4 /bin/date', Date => [0, 10, 15, 9, 8, 102]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 12, 21, 10, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 12, 21, 12, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 12, 21, 17, 8, 102]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 12, 21, 5, 8, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 12, 21, 3, 8, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 12, 21, 29, 7, 102]);


# job runs once a week on fridays and every 5 days (vixie cron notation)
$obj = new Schedule::Cron::Events('30 10 */5 * 5 /bin/date', Date => [0, 10, 5, 9, 8, 102]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 30, 10, 10, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 30, 10, 13, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 30, 10, 15, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 30, 10, 20, 8, 102]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 30, 10, 25, 8, 102]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 30, 10, 6, 8, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 30, 10, 5, 8, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 30, 10, 30, 7, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 30, 10, 25, 7, 102]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 30, 10, 23, 7, 102]);


# job runs every hour
$obj = new Schedule::Cron::Events('42 * * * * /bin/date', Date => [0, 51, 9, 21, 5, 87]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 42, 10, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 42, 11, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 42, 12, 21, 5, 87]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 42, 9, 21, 5, 87]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 42, 8, 21, 5, 87]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 42, 7, 21, 5, 87]);


# job runs assorted hours
$obj = new Schedule::Cron::Events('42 13,15,22,23 * * * /bin/date', Date => [0, 51, 17, 21, 5, 87]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 42, 22, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 42, 23, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 42, 13, 22, 5, 87]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 42, 15, 21, 5, 87]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 42, 13, 21, 5, 87]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 42, 23, 20, 5, 87]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 42, 22, 20, 5, 87]);


# job runs every minute of the current hour
$obj = new Schedule::Cron::Events('* 17 * * * /bin/date', Date => [59, 57, 17, 21, 5, 87]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 58, 17, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 59, 17, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 17, 22, 5, 87]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 57, 17, 21, 5, 87]);


# job runs specified minutes
$obj = new Schedule::Cron::Events('2,32 * * * * /bin/date', Date => [59, 57, 17, 21, 5, 87]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 2, 18, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 32, 18, 21, 5, 87]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 2, 19, 21, 5, 87]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 32, 17, 21, 5, 87]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 2, 17, 21, 5, 87]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 32, 16, 21, 5, 87]);


# job runs at a particularly well specified time, relative to precisely 1:20am on saturday 26th October, 1985
# on sundays and tuesdays, or on the 11th, in March and November.
# every 37 minutes past 19 hours
$obj = new Schedule::Cron::Events('*/37 19 11 3,11 0,2 /dev/flux/capacitor', Date => [0, 20, 1, 26, 9, 85]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 19, 3, 10, 85]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 37, 19, 3, 10, 85]); # nov 3 sunday

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 19, 5, 10, 85]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 37, 19, 5, 10, 85]); # nov 5 tuesday

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 19, 10, 10, 85]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 37, 19, 10, 10, 85]);  # nov 10 sunday

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 19, 11, 10, 85]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 37, 19, 11, 10, 85]);  # nov 11 monday

for (1..10) { $obj->nextEvent; }
# skip nov 12, 17, 19, 24, 26

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 19, 2, 2, 86]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 37, 19, 2, 2, 86]);  # mar 2 sunday

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 19, 4, 2, 86]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 37, 19, 4, 2, 86]);  # mar 4 tuesday

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 37, 19, 31, 2, 85]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 0, 19, 31, 2, 85]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 37, 19, 26, 2, 85]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 0, 19, 26, 2, 85]);


# a very infrequent cron job
$obj = new Schedule::Cron::Events('0 13 29 2 * /usr/bin/make propose', Date => [0, 30, 5, 12, 3, 95]);

@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 13, 29, 1, 96]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 13, 29, 1, 100]);
@rv = $obj->nextEvent;
cmpd(\@rv, [0, 0, 13, 29, 1, 104]);

$obj->resetCounter;

@rv = $obj->previousEvent;
cmpd(\@rv, [0, 0, 13, 29, 1, 92]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 0, 13, 29, 1, 88]);
@rv = $obj->previousEvent;
cmpd(\@rv, [0, 0, 13, 29, 1, 84]);

# end of routine tests

sub cmpd {
  my @got = @{ $_[0] };
  my @exp = @{ $_[1] };
  if (@got == @exp) {
    my $flag = 0;
    for (0 .. $#got) {
      $flag++ unless ($got[$_] == $exp[$_]);
    }
    if ($flag) {
      warn "Comparing Got <" . join('><', @got) . "> and Expected <" . join('><', @exp) . "> failed";
      ok(0);      
    } else {
      ok(1);
    }
  } else {
    warn "Comparing Got <" . join('><', @got) . "> and Expected <" . join('><', @exp) . "> failed";
    ok(0);
  }
}
