#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 9;

use Sport::Analytics::NHL::Report::TI;
use Sport::Analytics::NHL::Report::TV;
use Sport::Analytics::NHL::Report::TH;

my $report;
$report = Sport::Analytics::NHL::Report::TI->new({
	file => 't/data/2011/0002/0010/TV.html',
});
isa_ok($report, 'Sport::Analytics::NHL::Report::TI');
like($report->{source}, qr'html', 'html file in source');
ok(-f 't/data/2011/0002/0010/TV.tree', 'tree file created');

$report = Sport::Analytics::NHL::Report::TV->new({
	file => 't/data/2011/0002/0010/TV.html',
});
isa_ok($report, 'Sport::Analytics::NHL::Report::TV');
like($report->{source}, qr'html', 'html file in source');
ok(-f 't/data/2011/0002/0010/TV.tree', 'tree file created');

$report = Sport::Analytics::NHL::Report::TH->new({
	file => 't/data/2011/0002/0010/TH.html',
});
isa_ok($report, 'Sport::Analytics::NHL::Report::TH');
like($report->{source}, qr'html', 'html file in source');
ok(-f 't/data/2011/0002/0010/TH.tree', 'tree file created');

