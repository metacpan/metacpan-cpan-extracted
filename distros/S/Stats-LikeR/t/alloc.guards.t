#!/usr/bin/env perl
# Impossible allocation sizes croak instead of aborting the interpreter.
#
# Provenance: R 4.6.1 bw.SJ/bw.ucv/bw.bcv do nb <- as.integer(nb);
# if (is.na(nb) || nb <= 0L) stop("invalid 'nb'") (bandwidths.R), and
# as.integer() is NA above 2147483647, so that is the bound used here.  The
# table and pair-count guards have no R counterpart (R fails with "cannot
# allocate vector of size ..."); each case below used to exit with
# "Out of memory in perl:util:safesyscalloc" or, where size_t is 32 bits,
# wrap and write out of bounds.
#
# What a smoker can be asked.  0.3419 ran every case below everywhere, and 11
# of its 36 reports failed in this file and nowhere else: "Out of memory!" or
# "Out of memory in perl:util:safesyscalloc" after subtest 15 on Linux (gcc
# 15.2 and 16.1) and GNU/Hurd, the same after subtest 16 on aarch64-android
# (clang), and SIGKILL after subtest 15 on NetBSD and DragonFly.  Two things
# were wrong.  The probe could be compiled away (see alloc_probe_ok() in
# LikeR.xs), which the runif() case below now pins.  And three cases asked a
# real machine for 16 GB or more and assumed it would refuse: one that
# overcommits says yes and then kills the process that touches the pages,
# which no guard in this module can turn into a croak.  Those three now run
# only under EXTENDED_TESTING or AUTHOR_TESTING.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';

for my $f (qw(bw_ucv bw_bcv bw_sj)) {
	no strict 'refs';
	my $fn = \&{"Stats::LikeR::$f"};
	for my $nb (0, -1, 2**31, 2**32, 2**40) {
		throws_ok { $fn->([1 .. 20], nb => $nb) } qr/invalid 'nb'/, "$f nb => $nb";
	}
}
# The probe itself, at a size no machine has.  2**48 is SV_COUNT_MAX, the
# largest count runif() lets through to the probe, and 2**48 values need at
# least 2**48 * 40 bytes = 2**53.3, which is more address space than a process
# gets (2**47 on x86-64, 2**48 on aarch64), so malloc() refuses it whatever the
# overcommit policy.  A probe that always says yes -- 0.3419's, once a compiler
# had deleted its malloc() -- reaches av_extend() and exits with "Out of
# memory", which this file then reports as a dubious exit.  Where a size_t is
# 32 bits the count is refused before the probe, with a different message.
throws_ok { runif(2**48) } qr/cannot allocate|too large|too many/, 'runif(2**48) croaks';
throws_ok { rnorm(n => 2**48) } qr/cannot allocate|too large|too many/, 'rnorm(n => 2**48) croaks';

SKIP: {
	# These ask for 16 GB, 320 GB and 22 TB.  They croak here (15 GB of
	# RAM, vm.overcommit_memory = 0), but whether malloc() refuses is the
	# machine's decision: see the header.
	skip 'needs a machine that refuses a 16 GB malloc(); set EXTENDED_TESTING=1 to run', 3
		unless $ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING};
	# nb = INT_MAX passes R's check but needs 2 * nb * sizeof(NV) bytes: accept a
	# clean croak (probe failed) or a result (an overcommitting system), never an abort.
	my $ok = eval { Stats::LikeR::bw_sj([1 .. 20], nb => 2**31 - 1); 1 };
	ok($ok || $@ =~ /too large|cannot allocate/, 'nb => INT_MAX croaks or answers');

	my (@x, @y);
	for my $i (1 .. 200000) { push @x, "a$i"; push @y, "b$i"; }
	throws_ok { mcnemar_test(\@x, \@y) } qr/too large to allocate/, 'mcnemar_test 400000 levels';

	my (@v, @g);
	for my $i (1 .. 400000) { push @v, $i; push @g, "g$i"; }
	throws_ok { dunn_test(\@v, \@g) } qr/too many to compare/, 'dunn_test 400000 groups';
}
lives_ok { mcnemar_test([[5, 3], [1, 4]]) } 'small table still works';

no_leaks_ok { eval { Stats::LikeR::bw_sj([1 .. 20], nb => 2**32) } } 'bw_sj nb croak does not leak';
no_leaks_ok { eval { mcnemar_test([[1, 2], [3, 4], [5]]) } } 'mcnemar_test croak does not leak';
done_testing();
