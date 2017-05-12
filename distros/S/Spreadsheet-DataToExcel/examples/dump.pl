#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib ../lib);

use Spreadsheet::DataToExcel;

my @data = (
    [ qw/ID Time Number/ ],
    map [ $_, time(), rand() ], 1..10,
);


my $dump = Spreadsheet::DataToExcel->new;

$dump->dump( 'dump.xls', \@data );

print "Done! See dump.xls file\n";