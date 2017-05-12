#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;

my $cwd           = $FindBin::Bin;
my $raw_tsv       = "$cwd/../master_data/area-code-jp.tsv.raw";
my $formatted_tsv = "$cwd/../master_data/area-code-jp.tsv";

system "$cwd/numberphone_jp_generate_tsv.pl $raw_tsv";
system "$cwd/format_raw_tsv.pl $raw_tsv $formatted_tsv";
system "$cwd/generate_all.pl $formatted_tsv";
