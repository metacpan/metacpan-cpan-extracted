#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib ../lib);
use Spreadsheet::DataFromExcel;

die "Usage: perl $0 file_to_read.xls\n"
    unless @ARGV;

my $p = Spreadsheet::DataFromExcel->new;

my $data = $p->load(shift)
    or die $p->error;

use Data::Dumper;
print Dumper $data;