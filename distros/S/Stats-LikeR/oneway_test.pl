#!/usr/bin/perl
use 5.042.2;
no source::encoding;
use warnings;
use Stats::LikeR;
use DDP;
# ══════════════════════════════════════════════════════════════════════════
# MODE 1 – hash of groups (original behaviour)
#
# Keys   = group labels
# Values = array refs of numeric observations
# ══════════════════════════════════════════════════════════════════════════

my %groups = (
	yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
	ctrl  => [1,     1,   1,   0,   0,   0]
);

my $r1 = oneway_test(\%groups);                    # Welch (default)
p $r1;
my $r2 = oneway_test(\%groups, var_equal => 1);    # classic ANOVA
#p $r2;
my @a = (
	[5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
	[1,     1,   1,   0,   0,   0]
);
#p @a;
my $owt = oneway_test(\@a);
p $owt;
