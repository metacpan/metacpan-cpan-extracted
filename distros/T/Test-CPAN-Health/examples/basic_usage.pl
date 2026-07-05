#!/usr/bin/env perl
# Analyse a local distribution checkout and print a terminal health report.

use strict;
use warnings;

use lib '../lib';
use Test::CPAN::Health;

my $path = shift @ARGV // '.';

my $health = Test::CPAN::Health->new(path => $path);
my $report = $health->analyse;
print $health->report_to($report), "\n";

printf "Overall score: %d/100\n", $report->overall_score;
exit($report->overall_score < 70 ? 1 : 0);
