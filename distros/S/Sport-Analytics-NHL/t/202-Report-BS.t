#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 5;

use Sport::Analytics::NHL::Report::BS;
use Sport::Analytics::NHL::Config qw(:basic);
use Sport::Analytics::NHL::Util qw(:file);

my $report;
$report = Sport::Analytics::NHL::Report::BS->new(
	read_file('t/data/2011/0002/0010/BS.json'),
);
isa_ok($report, 'Sport::Analytics::NHL::Report::BS');
$report->set_id_data($report->{json}{gamePk});
is($report->{season}, 2011, 'season correct');
is($report->{stage}, $REGULAR, 'stage correct');
is($report->{season_id}, '0010', 'season id correct');
is($report->{_id}, 201120010, '_id correct');

