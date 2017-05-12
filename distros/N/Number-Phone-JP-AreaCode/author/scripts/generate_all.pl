#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;

my $tsv_file = $ARGV[0];

system "$FindBin::Bin/generators/generate_address2areacode.pl $tsv_file 1";
system "$FindBin::Bin/generators/generate_areacode2address.pl $tsv_file 1";
