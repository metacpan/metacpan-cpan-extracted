#!perl -w 

use strict;
use lib qw(t/lib);
use GnipTest;
use Net::Gnip;
use Net::Gnip::Activity;
use DateTime;
use Test::More;

GnipTest::plan_tests(7);

my $gnip;
ok($gnip = Net::Gnip->new($ENV{GNIP_TEST_USERNAME}, $ENV{GNIP_TEST_PASSWORD}), "Created publisher");

# Test publish()
my $activity;
my $response;
my $time = DateTime->now;
ok($activity = Net::Gnip::Activity->new('added_friend', 'me', at => $time), "Created Activity");
ok($gnip->publish($ENV{GNIP_TEST_PUBLISHER}, $activity), "Published the activity");

# Test get()
my $stream;
ok($stream = $gnip->fetch(notification => $ENV{GNIP_TEST_PUBLISHER}), "Subscriber got an activity stream");
ok(scalar($stream->activities), "Got an activity");
$activity = ($stream->activities)[-1];
ok($activity->isa('Net::Gnip::Activity'), "Activity is correct class");
is($activity->at, $time, "Got correct time from returned activity");

