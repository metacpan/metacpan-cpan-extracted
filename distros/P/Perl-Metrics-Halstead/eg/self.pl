#!/usr/bin/env perl
use strict;
use warnings;

use Perl::Metrics::Halstead ();

my $pmh = Perl::Metrics::Halstead->new(file => 'lib/Perl/Metrics/Halstead.pm');

$pmh->report;
