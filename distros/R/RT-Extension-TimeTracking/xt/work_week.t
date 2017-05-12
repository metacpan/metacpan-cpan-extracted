use strict;
use warnings;

use RT::Extension::TimeTracking::Test tests => undef;
use Test::Warn;

use_ok('RT::Extension::TimeTracking');

my $user = RT::User->new(RT->SystemUser);
$user->Load(RT->SystemUser);

my $date = RT::Date->new(RT->SystemUser);
$date->SetToNow;

warning_like { RT::Extension::TimeTracking::WeekStartDate($user, $date, 'foo') }
    qr/Invalid TimeTrackingFirstDayOfWeek value/i, "Incorrect day of week";

$date->Set(Format => 'unknown', Value => '2014-01-12 00:00:00', Timezone => 'user' );
my ($ret, $start) = RT::Extension::TimeTracking::WeekStartDate($user, $date, 'Monday');
is( $start->ISO( Timezone => 'user'), '2014-01-06 00:00:00', "Got the previous Monday when passing Sunday");

$date->Set(Format => 'unknown', Value => '2014-01-13 00:00:00', Timezone => 'user' );
($ret, $start) = RT::Extension::TimeTracking::WeekStartDate($user, $date, 'Monday');
is( $start->ISO( Timezone => 'user'), '2014-01-13 00:00:00', "Got Monday when passing Monday");

$date->Set(Format => 'unknown', Value => '2014-01-14 00:00:00', Timezone => 'user' );
($ret, $start) = RT::Extension::TimeTracking::WeekStartDate($user, $date, 'Monday');
is( $start->ISO( Timezone => 'user'), '2014-01-13 00:00:00', "Got Monday when passing Tuesday");

$date->Set(Format => 'unknown', Value => '2014-01-14 00:00:00', Timezone => 'user' );
($ret, $start) = RT::Extension::TimeTracking::WeekStartDate($user, $date);
is( $start->ISO( Timezone => 'user'), '2014-01-13 00:00:00', "Got Monday as default when passing Tuesday");

done_testing();
