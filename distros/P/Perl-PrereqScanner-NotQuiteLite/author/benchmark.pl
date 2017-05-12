#!perl

use strict;
use warnings;
use author::Util;
use Benchmark qw/cmpthese/;

my $target = shift || 'lib/Perl/PrereqScanner/NotQuiteLite.pm';

say "Target: $target";

cmpthese(-5 => setup_benchmarkers($target));
