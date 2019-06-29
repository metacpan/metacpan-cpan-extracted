#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 3;

use Sport::Analytics::NHL::Report::BH;

my $report;
$report = Sport::Analytics::NHL::Report::BH->new({
	file => 't/data/2011/0002/0010/BH.html',
});
isa_ok($report, 'Sport::Analytics::NHL::Report::BH');
like($report->{source}, qr'html', 'html file in source');
ok(-f 't/data/2011/0002/0010/BH.tree', 'tree file created');

