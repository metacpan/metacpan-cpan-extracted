#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 3;

use Sport::Analytics::NHL::Report::GS;

my $report;
$report = Sport::Analytics::NHL::Report::GS->new({
	file => 't/data/2011/0002/0010/GS.html',
});
isa_ok($report, 'Sport::Analytics::NHL::Report::GS');
like($report->{source}, qr'html', 'html file in source');
ok(-f 't/data/2011/0002/0010/GS.tree', 'tree file created');

