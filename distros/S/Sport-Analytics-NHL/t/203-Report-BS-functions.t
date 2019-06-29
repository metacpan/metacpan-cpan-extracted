#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 3;
use Sport::Analytics::NHL::Vars qw($IS_AUTHOR);

$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
use Sport::Analytics::NHL::Report::BS;
use Sport::Analytics::NHL::Util qw(:file);
use Sport::Analytics::NHL::Test;

my $report;
$report = Sport::Analytics::NHL::Report::BS->new(
	read_file('t/data/2011/0002/0010/BS.json'),
);
$BOXSCORE = $report;
isa_ok($report, 'Sport::Analytics::NHL::Report::BS');
$report->set_id_data($report->{json}{gamePk});
$report->set_timestamps($report->{json});
$report->set_extra_header_data($report->{json});
$report->set_periods($report->{json});
test_header($report);
test_periods($report->{periods});
$report->set_officials($report->{json}{liveData}{boxscore}{officials});
test_officials($report->{officials});
$report->set_teams($report->{json});
test_teams($report->{teams});
$report->set_events($report->{json}{liveData}{plays}{allPlays});
test_events($report->{events});
is($TEST_COUNTER->{Curr_Test}, 4426, 'full test run');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

$BOXSCORE = undef;
