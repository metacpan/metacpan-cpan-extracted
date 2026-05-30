#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

sub pmode {
	my (@modes, %counts, %originals);
	my ($arg_count, $max_count) = (0, 0);
	for my $i (0 .. $#_) {
		my $arg = $_[$i];

		if (ref($arg) eq 'ARRAY') {
			# Iterate through the elements of an array reference
			for my $j (0 .. $#{$arg}) {
				 my $val = $arg->[$j];
				 die "mode: undefined value at array ref index $j (argument $i)"
				     if !defined $val;

				 # Perl's auto-vivification handles ++$counts{$val} highly efficiently
				 my $cnt = ++$counts{$val};
				 
				 # Store the original SV on first encounter to preserve exact type/value
				 $originals{$val} = $val if $cnt == 1;
				 
				 $max_count = $cnt if $cnt > $max_count;
				 $arg_count++;
			}
		} else {
			# Process standard scalars
			die "mode: undefined value at argument index $i"
				 if !defined $arg;

			my $cnt = ++$counts{$arg};
			$originals{$arg} = $arg if $cnt == 1;
			$max_count = $cnt if $cnt > $max_count;
			$arg_count++;
		}
	}

	die "mode needs >= 1 element" if $arg_count == 0;

	# Extract and return the values that match the maximum count
	for my $key (keys %counts) {
	  push @modes, $originals{$key} if $counts{$key} == $max_count;
	}

	return @modes;
}

say mode(1,1,undef);
my @x = map { int $_ } @{ runif(999, 0, 99) };
my (@xs, @perl);
foreach my $run (0..999) {
	my $t0 = Time::HiRes::time();
	my @m = mode(\@x);
	my $t1 = Time::HiRes::time();
	push @xs, $t1-$t0;
	$t0 = Time::HiRes::time();
	my @n = pmode(\@x);
	$t1 = Time::HiRes::time();
	push @perl, $t1 - $t0;
}
my $tt = t_test(\@xs, \@perl, var_equal => false);
printf("Perl/XS is %lf\n", mean(\@perl) / mean(\@xs));
p $tt;
