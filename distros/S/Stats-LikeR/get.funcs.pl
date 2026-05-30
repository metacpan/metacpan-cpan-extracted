#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Util;

my $xs = file2string('LikeR.xs');
my @xs = split "\n", $xs;


