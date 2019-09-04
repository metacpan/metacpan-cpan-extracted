#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin . '/../lib';

use DDP;
use Telemetry::Any '$telemetry';

$telemetry->mark('point1');

for ( 1 .. 3 ) {
    $telemetry->mark('point2');
    $telemetry->mark('point3');
}

$telemetry->mark('point4');

print "Detailed:\n";
my @detailed = $telemetry->detailed();
print np @detailed;
print "\n";

print "Collapsed:\n";
my @collapsed = $telemetry->collapsed();
print np @collapsed;
print "\n";

print "Report detailed:\n";
my $report = $telemetry->report( format => 'table' );
print $report;
print "\n";

print "Report collapsed:\n";
my $report = $telemetry->report( collapse => 1, format => 'table' );
print $report;
print "\n";
