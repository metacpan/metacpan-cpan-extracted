#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Module::Packaged::Report;

my %opts;
GetOptions(\%opts,
    'test',
    'real',
    'dir=s',
    'help',
) or Module::Packaged::Report::usage();

my $mpr = Module::Packaged::Report->new(%opts);
$mpr->collect_data;
$mpr->generate_html_report;

