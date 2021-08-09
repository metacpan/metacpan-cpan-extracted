#!/usr/bin/env perl

use strict;
use warnings;
use PDL::LiteF;

my $can_use_threads = eval 'use threads; 1'; ## no critic (eval)
use Test::More;
if( ! $can_use_threads ) {
	plan skip_all => "perl does not support threads";
} else {
	plan tests => 1;
	$PDL::no_clone_skip_warning = 1;
	require PDL::FFTW3;
	PDL::FFTW3->import('rfft1');
	require Thread::Semaphore;
}

my $s = Thread::Semaphore->new();

sub run_fft {
	note "Running in thread #" . threads->self->tid;
	for my $size_factor (1..10) {
		my $xvals = sequence($size_factor * 100);
		my $x = sin( $xvals * 2.0 ) + 2.0 * cos( $xvals / 3.0 );
		my $F = rfft1( $x );
	}
	$s->down;

	return 1;
}

subtest "Running FFTW in threads" => sub {
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm 4; # timeout in 4 seconds

		my @threads;
		for (0..7) {
			push @threads, threads->create(\&run_fft);
			$s->up;
		}

		$s->down;
		for my $thr (@threads) {
			my ($return) = $thr->join;
			if( ! $return ) {
				fail "Thread #@{[ $thr->tid ]} did not complete successfully";
				return;
			}
		}

		alarm 0;
	};
	if ($@) {
		if($@ eq "alarm\n") {
			fail "Threads hanging";
		} else {
			die $@;
		}

	}

	pass "All threads returned successfully";
};

done_testing;
