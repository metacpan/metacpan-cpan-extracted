#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 5;

use Sport::Analytics::NHL::Report;

my $report;
$report = Sport::Analytics::NHL::Report->new();
is($report, undef, 'Insufficient arguments detected');

$report = Sport::Analytics::NHL::Report->new({type => 'BS'});
is($report, undef, 'Insufficient arguments - no data or file detected');

$report = Sport::Analytics::NHL::Report->new({data => 'BS'});
is($report, undef, 'Insufficient arguments - ambiguous type detected');

$report = Sport::Analytics::NHL::Report->new({data => 'BS', file => 'BS'});
is($report, undef, 'Insufficient arguments - ambiguous data/file detected');

$report = Sport::Analytics::NHL::Report->new({data => 'BS', type => 'ZZ'});
is($report, undef, 'Invalid report type detected');