#!/usr/bin/perl

use Test::More tests => 3;
use Pod::From::GoogleWiki;

my $wiki = <<'WIKI';
For now, we have several workers:
  * Foorum::TheSchwartz::Worker::DailyChart
  * Foorum::TheSchwartz::Worker::DailyReport
  * Foorum::TheSchwartz::Worker::Hit
  * Foorum::TheSchwartz::Worker::RemoveOldDataFromDB
  * Foorum::TheSchwartz::Worker::ResizeProfilePhoto
  * Foorum::TheSchwartz::Worker::SendScheduledEmail
  * Foorum::TheSchwartz::Worker::SendStarredNofication
  * etc.
WIKI

my $pod = <<'POD';
For now, we have several workers:

  * Foorum::TheSchwartz::Worker::DailyChart
  * Foorum::TheSchwartz::Worker::DailyReport
  * Foorum::TheSchwartz::Worker::Hit
  * Foorum::TheSchwartz::Worker::RemoveOldDataFromDB
  * Foorum::TheSchwartz::Worker::ResizeProfilePhoto
  * Foorum::TheSchwartz::Worker::SendScheduledEmail
  * Foorum::TheSchwartz::Worker::SendStarredNofication
  * etc.

POD

my $pfg = Pod::From::GoogleWiki->new();
my $ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'list yup!');

$wiki = <<'WIKI';
[http://search.cpan.org/perldoc?TheSchwartz TheSchwartz]
WIKI

$pod = <<'POD';
L<TheSchwartz>
POD

$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'CPAN link yup!');

$wiki = <<'WIKI';
For now, we have several workers:
  * Foorum::TheSchwartz::Worker::DailyChart
  * Foorum::TheSchwartz::Worker::DailyReport
  * Foorum::TheSchwartz::Worker::Hit
  * Foorum::TheSchwartz::Worker::RemoveOldDataFromDB
  * Foorum::TheSchwartz::Worker::ResizeProfilePhoto
  * Foorum::TheSchwartz::Worker::SendScheduledEmail
  * Foorum::TheSchwartz::Worker::SendStarredNofication
  * etc.
TODO
WIKI

$pod = <<'POD';
For now, we have several workers:

  * Foorum::TheSchwartz::Worker::DailyChart
  * Foorum::TheSchwartz::Worker::DailyReport
  * Foorum::TheSchwartz::Worker::Hit
  * Foorum::TheSchwartz::Worker::RemoveOldDataFromDB
  * Foorum::TheSchwartz::Worker::ResizeProfilePhoto
  * Foorum::TheSchwartz::Worker::SendScheduledEmail
  * Foorum::TheSchwartz::Worker::SendStarredNofication
  * etc.

TODO
POD

$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, '3 yup!');