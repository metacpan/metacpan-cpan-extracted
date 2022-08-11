#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone;
use File::Temp qw/tempfile/;

use Test::More tests => 200;

# Cumulative error in PDL-to-perl-scalar conversion for long-double builds
# requires a lower tolerance.  To prevent failing builds just because of
# floating point error we define a tolerance target and use it below.  Note
# that normal perl builds work at 1e-9, and longdouble builds work at 1e-8 so
# 1e-6 should certainly be safe.
#
# See here: https://github.com/PDLPorters/pdl/issues/405
# and here: https://github.com/ebaudrez/Test-PDL/wiki/Rationale:-tolerances

my $tolerance = 1e-6;
my ($fh, $fn) = tempfile();

# This test iterates over a number of port sizes and output format types
# to make sure the resulting matrix after format conversion is the same.
# We write the original matrix in one format and read it in another format
# to make sure the sum of the errors is very small. 

my $n_freq = 10;
for my $n_ports (1,2,3,4,10)
{
	my $f1 = sequence($n_freq,1)+1;
	$f1 *= 1e6; # MHz
	my $m1 = sequence($n_ports,$n_ports,$n_freq)+1;

	$m1 = $m1 * rand() + $m1 * rand() * i();

	for my $fmt1 (qw/RI MA DB/)
	{
		#print "==== $n_ports: $fmt1 => $fmt1 === \n";
		
		# write in $fmt1
		wsnp($fn, $f1, $m1, 'S', 50, [qw/these are comments/], $fmt1);

		# re-read it and make sure it is correct:
		my ($f2, $m2, $param_type, $z0, $comments, $fmt_in, $funit, $orig_f_unit) = rsnp($fn);

		verify($n_ports, $fmt1 => $fmt1 => $fmt_in, $m1 => $m2, $f1 => $f2, $orig_f_unit);

		for my $fmt2 (qw/RI MA DB/)
		{
			next if $fmt1 eq $fmt2;

			#print "==== $n_ports: $fmt1 => $fmt2 === \n";

			# Write what we read in the outer loop in a different format:
			wsnp($fn, $f2, $m2, 'S', 50, [qw/these are comments/], $fmt2);

			# then re-read and verify the result against the original $m1 and $f1:
			my ($f3, $m3, $param_type, $z0, $comments, $fmt_in, $funit, $orig_f_unit) = rsnp($fn);
			verify($n_ports, $fmt1 => $fmt2 => $fmt_in, $m1 => $m3, $f1 => $f3, $orig_f_unit);
		}
	}
}

# validate unit conversion:
for my $hz (qw/hz khz mhz ghz thz/)
{
	my $n_ports = 7;
	my $n_freq = 10;
	my $fmt1 = 'RI';
	my $f1 = sequence($n_freq,1)+1;
	$f1 *= 1e6; # MHz
	my $m1 = sequence($n_ports,$n_ports,$n_freq)+1;

	$m1 = $m1 * rand() + $m1 * rand() * i();

	wsnp($fn, $f1, $m1, 'S', 50, [qw/these are comments/], $fmt1, 'hz', $hz);

	# re-read it and make sure it is correct:
	my ($f2, $m2, $param_type, $z0, $comments, $fmt_in, $funit, $orig_f_unit) = rsnp($fn);
	#print "$hz: ";
	verify($n_ports, $fmt1 => $fmt1 => $fmt_in, $m1 => $m2, $f1 => $f2, $orig_f_unit);
	#system("cat $fn");
}

sub verify
{
	my ($n_ports, $fmt1, $fmt2, $fmt_in, $m1, $m, $f, $f1, $orig_funit) = @_;

	ok ( $fmt2 eq $fmt_in, "n_ports=$n_ports ($orig_funit) $fmt1 => $fmt2: format is equal");
	ok ( sum($m1 - $m)->re < $tolerance, "n_ports=$n_ports ($orig_funit) $fmt1 => $fmt2: matrix real: error is < $tolerance");
	ok ( sum($m1 - $m)->im < $tolerance, "n_ports=$n_ports ($orig_funit) $fmt1 => $fmt2: matrix imag: error is < $tolerance");
	ok ( sum($f1 - $f) < $tolerance, "n_ports=$n_ports ($orig_funit) $fmt1 => $fmt2: freq: error is < $tolerance");
}

unlink($fn);
