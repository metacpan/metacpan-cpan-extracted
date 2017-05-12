#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';
use Test;
use Schedule::Cron::Events;
use Time::Local;
use Data::Dumper;

# $Id: 02errs.t,v 1.1 2002/09/11 19:54:37 piers Exp $

my $obj;
my @rv;

plan tests => 12;

# check comments are not allowed
$obj = new Schedule::Cron::Events("# this is a comment\n", Date => [0, 0, 15, 14, 1, 101]);
ok(! $obj);

# no blank lines
$obj = new Schedule::Cron::Events("\n", Date => [0, 0, 15, 14, 1, 101]);
ok(! $obj);

# env var lines
$obj = new Schedule::Cron::Events("VARIABLE=value\n", Date => [0, 0, 15, 14, 1, 101]);
ok(! $obj);

# not a crontab line
$obj = new Schedule::Cron::Events("THE HOMECOMING\n", Date => [0, 0, 15, 14, 1, 101]);
ok(! $obj);

# not a crontab line either
eval {
  $obj = new Schedule::Cron::Events("As I was going to Aylesbury all on a market day,\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

# bad crontab lines
eval {
  $obj = new Schedule::Cron::Events("63 * * * * /bin/never\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

eval {
  $obj = new Schedule::Cron::Events("* 24 * * * /bin/never\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

eval {
  $obj = new Schedule::Cron::Events("* * 33 * * /bin/never\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

eval {
  $obj = new Schedule::Cron::Events("* * 0 * * /bin/never\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

eval {
  $obj = new Schedule::Cron::Events("* * * 14 * /bin/never\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

eval {
  $obj = new Schedule::Cron::Events("* * * 0 * /bin/never\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

eval {
  $obj = new Schedule::Cron::Events("* * * * 9 /bin/never\n", Date => [0, 0, 15, 14, 1, 101]);
};
ok($@ ne '');
TRACE($@);

sub TRACE {
  my $msg = shift;
# print "## $msg\n";
}
