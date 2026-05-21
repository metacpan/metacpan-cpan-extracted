#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Devel::Confess;
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Stats::LikeR;

my @tab = ([762, 327, 468], [484, 239, 477]);
my $chisq = chisq_test(\@tab);
p $chisq;

$chisq = chisq_test([10, 20, 30]);
p $chisq;
#$chisq = chisq_test( 'string' );
#p $chisq;
$chisq = chisq_test([[12, 7], [5, 14]]);
p $chisq;
