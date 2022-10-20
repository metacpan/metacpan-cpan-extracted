#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Library General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  Copyright (C) 2022- eWheeler, Inc. L<https://www.linuxglobal.com/>
#  Originally written by Eric Wheeler, KJ7LNW
#  All rights reserved.
#
#  All tradmarks, product names, logos, and brands are property of their
#  respective owners and no grant or license is provided thereof.

package PDL::IO::Touchstone;
$VERSION = 1.008;

use 5.010;
use strict;
use warnings;

use Carp;

use PDL;
use PDL::LinearAlgebra;
use PDL::Constants qw(PI);

use constant RAD2DEG => 180/PI;
use constant DEG2RAD => PI/180;

BEGIN {
	use Exporter;
	our @ISA = ( @ISA, qw(Exporter) );
	our @EXPORT = qw/rsnp wsnp/;
	our @EXPORT_OK = qw/
		n_ports
		m_interpolate
		f_uniformity
		f_is_uniform

		s_to_y
		y_to_s

		s_to_z
		z_to_s

		s_to_abcd
		abcd_to_s

		s_port_z

		y_inductance
		y_ind_nH
		y_resistance
		y_esr
		y_capacitance
		y_cap_pF
		y_qfactor_l
		y_qfactor_c
		y_reactance_l
		y_reactance_c
		y_reactance
		y_srf
		y_srf_ideal
		y_parallel
		abcd_series
		abcd_is_lossless
		abcd_is_symmetrical
		abcd_is_reciprocal
		abcd_is_open_circuit
		abcd_is_short_circuit

		pos_vec
		m_to_pos_vecs
		pos_vecs_to_m
		/;

	our %EXPORT_TAGS = (ALL => [ @EXPORT, @EXPORT_OK ]);
}

sub rsnp
{
	my ($fn, $args) = @_;

	my $class;
	my $comments = '';
	my ($orig_funit, $param_type, $fmt, $R, $z0);
	my $n_ports;

	# Try to enforce the number of ports based on the filename extension.
	$n_ports = $1 if ($fn =~ /s(\d+)p/i);

	open(my $in, $fn) or croak "$fn: $!";

	my $n = 0;
	my $line;

	# start at -1 because it increments when a frequency is found.
	my $row_idx = -1;
	my $col_idx = 0;
	my @comments;
	my @cols;
	my @f;
	while (defined($line = <$in>))
	{
		chomp($line);
		$n++;

		$line =~ s/^\s+|\s+$//g;

		next if !length($line);

		# Strip leading space so split() will work properly.
		$line =~ s/^\s+//;

		if ($line =~ /^!/)
		{
			push @comments, $line;
			next;
		}

		# Strip any inline comments:
		$line =~ s/!.*$//;

		if ($line =~ s/^#\s*//)
		{
			($orig_funit, $param_type, $fmt, $R, $z0) = split /\s+/, $line;

			$param_type = uc($param_type);
			if ($param_type !~ /^[SYZTAGH]$/) {
				croak "$fn:$n: $param_type-parameter type is not implemented.";
			}

			croak "$fn:$n: expected 'R' before z0, but found: $R" if $R ne 'R';
			next;
		}

		if ($line !~ /^[0-9.+-]/)
		{
			die "$fn:$n: unexpected line $n: $line\n";
			next;
		}

		my @params = split(/\s+/, $line);

		# If the line has an odd number of elements then the first is the frequency
		# because data lines are always in pairs:
		if (scalar(@params) % 2)
		{
			$row_idx++;

			if ($row_idx > 0)
			{
				# We want the possibly multi-line row that was
				# just completed, not the new one that was just
				# read in.  $col_idx currently holds the number
				# of columns from the previous frequency.
				my $sqrt_n_params = sqrt($col_idx);
				if (!defined($n_ports))
				{
					$n_ports = $sqrt_n_params;
				}

				if ($sqrt_n_params != $n_ports)
				{
					croak "$fn:$n: expected $n_ports fields of port data but found $sqrt_n_params: $n_ports != $sqrt_n_params";
				}
			}

			# Read the frequency off the front.
			$f[$row_idx] = shift(@params);
			$col_idx=0;
		}

		my @params_cx;

		for (my $i = 0; $i < @params; $i += 2)
		{
			# The data format could be ri, ma, or db but there is
			# always a pair of data.  Please each in its own array
			# and we will convert the format below.
			push @{ $cols[$col_idx]->[0] }, $params[$i];
			push @{ $cols[$col_idx]->[1] }, $params[$i+1];

			$col_idx++;
		}

	}

	# The 2-port versions need to be turned into a row-major format.
	# All other port counts _are_ row-major (including the 1-port, I
	# suppose).
	if (@cols == 4)
	{
		my $t = $cols[2];
		$cols[2] = $cols[1];
		$cols[1] = $t;
	}

	# Convert input columns to PDLs
	foreach my $c (@cols)
	{
		$c->[0] = pdl $c->[0];
		$c->[1] = pdl $c->[1];
	}

	# Convert from R/I formats to native complex:
	my @cx_cols = _cols_to_complex_cols($fmt, \@cols);

	# Scale frequency unit:
	my $funit = $args->{units} || 'Hz';
	my $f = _si_scale_hz($orig_funit, $funit, pdl \@f);

	my $m = _complex_cols_to_matrix(@cx_cols);

	($f, $m) = m_interpolate($f, $m, $args);

	# Make z0 an n-vector:
	$z0 = zeroes($n_ports) + $z0;

	return ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_funit);
}

sub wsnp
{
	my @opts = @_;
	my $fn = shift(@opts);

	croak "filename must be defined" if !defined $fn;

	open(my $out, '>', $fn) or croak "$fn: $!";

	my $ret = wsnp_fh($out, @opts);

	close($out);

	return $ret;
}

sub wsnp_fh
{
	my ($fd, $f, $m, $param_type, $z0, $comments, $fmt, $from_hz, $to_hz) = @_;

	my $n_ports = n_ports($m);
	my $n_freqs = $f->nelem;

	if (ref($z0) eq 'PDL')
	{
		my $numz = $z0->nelem;

		if ($numz > 1 && $numz != $n_ports)
		{
			croak("\$z0: must be single valued, or a vector of one z0 value per port: n_ports=$n_ports, z0=$z0");
		}
		elsif ($numz == $n_ports)
		{
			my $z01 = $z0->slice(0)->sclr;

			my $zx = zeroes($numz)+$z01;
			if (any $zx != $z0)
			{
				croak("All port impedances must be identical when writing Touchstone files: z0=$z0");
			}
		}

		$z0 = $z0->slice(0)->sclr;
	}

	# Assume $f frequencies are in Hz if from_hz is not defined
	# and always default writing in MHz if the user does not specify.
	# This is consistent with rsnp() and common industry practice:
	$from_hz //= 'Hz';
	$to_hz //= 'MHz';

	$fmt = lc $fmt;

	# 2-port matrixes are column-major:
	$m = $m->transpose if ($n_ports == 2);

	# Big thanks to mohawk and sivoais for helping figure out the reshape here.
	# $d is arranged so real and imag parts can be separated into their own
	# columns with clump() for writing to the sNp file:
	my $d = $m->dummy(0,1);
	

	# $real and $imag are the real and imag parts:
	my ($real, $imag);
	if ($fmt eq 'ri')
	{
		$real = $d->re;
		$imag = $d->im;
	}
	elsif ($fmt eq 'ma')
	{
		$real = $d->abs;
		$imag = $d->carg * RAD2DEG;
	}
	elsif ($fmt eq 'db')
	{
		$real = 20*log($d->abs)/log(10);
		$imag = $d->carg * RAD2DEG;
	}

	# Prepare real/imag values for interleaving:
	my $ri = $real->append($imag);

	# Create one row per frequency: (n_ports*2, n_freqs):
	my $out = $ri->clump(0..2);

	# Scale the input/output frequency:
	$f = _si_scale_hz($from_hz, $to_hz, $f);

	# Fix capitalization to meet Touchstone spec:
	$param_type = uc($param_type); # S, Y, Z, T, G, H, A
	$fmt = uc($fmt); # RI, MA, DB
	$to_hz =~ s!^([kmgtpe]?)hz$!uc($1 // '') . "Hz"!ie;

	# Format header and comments:
	print $fd join("\n", map { "! $_" } @$comments) . "\n" if ($comments && @$comments);
	print $fd "# $to_hz $param_type $fmt R $z0\n";

	# $out is in touchstone-formated order for each frequency with frequency as the first element:
	# ie: [freq s11 21 s12 s11] < transposed for only for 2-port models.
	
	for (my $i = 0; $i < $n_freqs; $i++)
	{
		# matrix at frequency $i:
		my $fm = $out->slice(":,$i");
		my $freq = $f->slice("$i")->sclr;

		# More than 2 ports are printed on multiple lines,
		# at least one line for each port.
		if ($n_ports > 2)
		{
			$fm = $fm->reshape($n_ports*2,$n_ports);
		}

		print $fd $freq;

		# foreach matrix row:
		foreach my $row ($fm->dog)
		{
			# No more than four data samples are allowed per line,
			# so 4 RI pairs max.  If there are 3 or 4 ports then
			# break at the port count so the matrix is visible in
			# the file.  Iterate over the data in the row and put
			# line breaks in the appropriate place:
			my @data = $row->dog;
			while (@data)
			{
				my $count = @data;
				$count = $n_ports * 2 if $count > $n_ports * 2;
				$count = 8 if $count > 8 || $n_ports == 2;

				my @line;
				push @line, shift @data while ($count--);

				print $fd "\t" . join("\t", @line) . "\n";
			}

		}
	}

	# we don't close the file descriptor here, the caller (or `wsnp`) will.
}

# https://physics.stackexchange.com/questions/398988/converting-magnitude-ratio-to-complex-form
sub _cols_to_complex_cols
{
	my ($fmt, $cols) = @_;

	$fmt = lc $fmt;
	my @cx;

	foreach my $c (@$cols)
	{
		my $r = $c->[0];
		my $i = $c->[1];
		if ($fmt eq 'ri')
		{
			push @cx, $r + $i*i();
		}
		elsif ($fmt eq 'ma')
		{
			push @cx, $r*exp(i()*$i*DEG2RAD);
		}
		elsif ($fmt eq 'db')
		{
			my $r = 10**($r/20);
			push @cx, $r*exp(i()*$i*DEG2RAD);
		}
		else
		{
			croak "Unknown s-parameter format: $fmt";
		}
	}

	return @cx;
}

sub _complex_cols_to_matrix
{
	my @cx = @_;

	my $n = $cx[0]->nelem;
	my $n_ports = sqrt(scalar @cx);

	my $m = pdl \@cx;
	$m = $m->mv(0, -1)->reshape($n_ports,$n_ports,$n);
}

sub _si_scale_hz
{
	my ($from, $to, $n) = @_;

	$from = lc $from;
	$to = lc $to;

	return $n if $from eq $to;

	my %scale =
	(
		hz => 1,
		khz => 1e3,
		mhz => 1e6,
		ghz => 1e9,
		thz => 1e12,
	);

	$from = $scale{$from};
	$to = $scale{$to};

	my $fscale = $from/$to;

	croak "Unknown frequency scale: $fscale" if !$fscale;

	return $n*$fscale;
}

# http://qucs.sourceforge.net/tech/node98.html
sub s_to_y
{
	my ($S, $z0) = @_;

	my $n_ports = n_ports($S);

	$z0 = pdl $z0 if (!ref($z0));

	my $Z_ref = _to_diagonal($z0, $n_ports);
	my $G_ref = _to_diagonal(1/sqrt($z0->re), $n_ports);
	my $E = identity($n_ports);

	my $Y = $G_ref->minv x ($S x $Z_ref + $Z_ref)->minv x ($E-$S) x $G_ref;

	# Alternate conversion, not sure which is faster, both have the same
	# number of matrix multiplications:
	#my $Y = $G_ref->minv x $Z_ref->minv x ($S + $E)->minv x ($E-$S) x $G_ref;
	#my $Y = $G_ref->minv x $Z_ref->minv x ($E-$S) x ($S + $E)->minv x $G_ref;

	return $Y;
}

sub y_to_s
{
	my ($Y, $z0) = @_;

	my $n_ports = n_ports($Y);

	$z0 = pdl $z0 if (!ref($z0));

	my $Z_ref = _to_diagonal($z0, $n_ports);
	my $G_ref = _to_diagonal(1/sqrt($z0->re), $n_ports);
	my $E = identity($n_ports);

	my $S = $G_ref  x  ($E - $Z_ref  x  $Y)  x  ($E + $Z_ref  x  $Y)->minv()  x  $G_ref->minv();

	return $S;
}

# This could result in singularities:
sub s_to_z
{
	my ($S, $z0) = @_;

	# This tries to avoid a singularity, but not so successfully.
	#my $Y = s_to_y($S, $z0);
	#my $Z;
	#eval {$Z = $Y->minv };
	#return $Z;

	my $n_ports = n_ports($S);

	$z0 = pdl $z0 if (!ref($z0));

	my $Z_ref = _to_diagonal($z0, $n_ports);
	my $G_ref = _to_diagonal(1/sqrt($z0->re), $n_ports);
	my $E = identity($n_ports);

	# These are equivalent, the second one has a smaller error:
	#my $Z = $G_ref->minv() x ($E - $S)->minv x ($S x $Z_ref + $Z_ref) x $G_ref;
	my $Z = $G_ref->minv() x ($E - $S)->minv x ($S + $E) x $Z_ref x $G_ref;

	return $Z;
}

sub z_to_s
{
	my ($Z, $z0) = @_;

	my $n_ports = n_ports($Z);

	$z0 = pdl $z0 if (!ref($z0));

	my $Z_ref = _to_diagonal($z0, $n_ports);
	my $G_ref = _to_diagonal(1/sqrt($z0->re), $n_ports);
	my $E = identity($n_ports);

	my $S = $G_ref x ($Z - $Z_ref) x ($Z + $Z_ref)->minv x $G_ref->minv;
	return $S;

	# This is equivalent but can result in singularities:
	# minv needs scalar context for return, so assign temp value
	# for clarity as to what is happening:
	#my $Y = $Z->minv;
	#return y_to_s($Y, $z0);
}

sub s_to_abcd
{
	my ($S, $z0) = @_;

	my $n_ports = n_ports($S);

	croak "A-matrix transforms only work with 2-port matrices" if $n_ports != 2;

	# We don't really need it diagonal, but it makes the call compatable with other
	# conversions if the caller has different impedances per port:
	my $Z_ref = _to_diagonal($z0, $n_ports);
	my $z01 = $Z_ref->slice(0,0)->reshape(1);
	my $z02 = $Z_ref->slice(1,1)->reshape(1);

	my $z01_conj = $z01->conj;
	my $z02_conj = $z02->conj;

	my ($S11, $S12, $S21, $S22) = m_to_pos_vecs($S);

	# https://www.researchgate.net/publication/3118645
	# "Conversions Between S, Z, Y, h, ABCD, and T Parameters
	#   which are Valid for Complex Source and Load Impedances"
	# March 1994 IEEE Transactions on Microwave Theory and Techniques 42(2):205 - 211

	# If this needs to be optimized in the future then:
	# 	1. Factor out the divisor
	# 	2. Separate each segment into its multiplicative or additive term
	# 	3. Use PDL magic to compose elements with multiplication and addition.
	#
	# 	For example, the first multiplicative term (I think) becomes:
	# 		$ABCD_part_1 = (
	# 		    pdl([ [$z01_conj, $z01_conj],
	# 			  [1        , 1] ])
	# 			+ $S->slice(0,0) * pdl( [ [$z01, $z01],
	# 			                            [-1, -1] ])
	#		)
	#
	#	see https://m.perl.bot/p/qycs8z
	return pos_vecs_to_m(
			# A
			(($z01_conj + $S11*$z01) * (1 - $S22) + $S12*$S21*$z01)
				/ # over
			(2*$S21*sqrt($z01->re * $z02->re)),

			# B
			(($z01_conj + $S11*$z01)*($z02_conj+$S22*$z02) - $S12*$S21*$z01*$z02)
				/ # over
			(2*$S21*sqrt($z01->re * $z02->re)),

			# C
			(( 1 - $S11 )*( 1 - $S22 ) - $S12*$S21)
				/ # over
			(2*$S21*sqrt($z01->re * $z02->re)),

			# D
			((1-$S11)*($z02_conj+$S22*$z02) + $S12*$S21*$z02)
				/ # over
			(2*$S21*sqrt($z01->re * $z02->re)),
		);
}

sub abcd_to_s
{
	my ($ABCD, $z0) = @_;

	my $n_ports = n_ports($ABCD);

	croak "A-matrix transforms only work with 2-port matrices" if $n_ports != 2;

	# We don't really need it diagonal, but it makes the call compatable with other
	# conversions if the caller has different impedances per port:
	my $Z_ref = _to_diagonal($z0, $n_ports);
	my $z01 = $Z_ref->slice(0,0)->reshape(1);
	my $z02 = $Z_ref->slice(1,1)->reshape(1);

	my $z01_conj = $z01->conj;
	my $z02_conj = $z02->conj;

	my ($A, $B, $C, $D) = m_to_pos_vecs($ABCD);

	return pos_vecs_to_m(
			# S11
			($A*$z02 + $B - $C*$z01_conj*$z02 - $D*$z01_conj)
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01),

			# S12
			(2*($A*$D-$B*$C)*sqrt($z01->re * $z02->re))
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01),

			# S21
			(2*sqrt($z01->re * $z02->re))
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01),

			# S22
			(-$A*$z02_conj + $B - $C*$z01*$z02_conj + $D*$z01)
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01)
		);
}

###############################################################################
#                                                      S-Parameter Calculations

# Return the complex port impedance vector for all frequencies given:
#   - $S: S paramter matrix
#   - $z0: vector impedances at each port
#   - $port: the port we want.
#
# In a 2-port, this will provide the input or output impedance as follows:
#   $z_in  = s_port_z($S, 50, 1);
#   $z_out = s_port_z($S, 50, 2);
sub s_port_z
{
	my ($S, $z0, $port) = @_;

	my $n_ports = n_ports($S);

	$z0 = _to_diagonal($z0, $n_ports);

	my $z_port = pos_vec($z0, $port, $port);
	my $s_port = pos_vec($S, $port, $port);

	return $z_port * ( (1+$s_port) / (1-$s_port) );
}

###############################################################################
#                                                      Y-Parameter Calculations

# Return a vector of inductance for each frequency in Henrys (H):
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
sub y_inductance
{
	my ($Y, $f_hz) = @_;

	my $y12 = pos_vec($Y, 1, 2);

	return -(1/$y12)->im / (2*PI*$f_hz);
}

# Return a vector of inductance for each frequency in nH:
sub y_ind_nH { return y_inductance(@_) * 1e9; }

# Return ESR in Ohms:
# $Y - the Y parameter matrix (N,N,M)
# Equation from here:
#   https://mdpi-res.com/d_attachment/electronics/electronics-11-02029/article_deploy/electronics-11-02029.pdf
#   "Analytic Design of on-Chip Spiral Inductor with Variable Line Width"
# See also:
#   https://electronics.stackexchange.com/q/637472/256265
sub y_resistance
{
	my ($Y) = @_;

	my $y12 = pos_vec($Y, 1, 2);

	return (-1/$y12)->re;
}

sub y_esr { return y_resistance(@_) }


# Return a vector of capacitance for each frequency in Farads (F):
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
sub y_capacitance
{
	my ($Y, $f_hz) = @_;

	my $y11 = pos_vec($Y, 1, 1);

	return $y11->im / (2*PI*$f_hz);
}

# Return a vector of capacitance it each frequency in picofarads (pF):
sub y_cap_pF { return y_capacitance(@_) * 1e12; }

# Return the inductive Q-factor vector for each frequency.
# All capacitive values are zeroed.
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
#
# $Ql = y_qfactor_l($Y, $f_hz)
sub y_qfactor_l
{
	my ($Y, $f_hz) = @_;

	my $Xl = y_reactance_l($Y, $f_hz);

	my $is_l = ($Xl > 0);

	my $esr = y_resistance($Y);
	my $Ql = ($is_l*$Xl)/$esr;

	return $Ql;
}

# Return the capacitive Q-factor vector for each frequency.
# All inductive values are zeroed.
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
#
# $Qc = y_qfactor_c($Y, $f_hz)
sub y_qfactor_c
{
	my ($Y, $f_hz) = @_;

	my $Xc = y_reactance_c($Y, $f_hz);

	my $is_c = ($Xc > 0);

	my $esr = y_resistance($Y);
	my $Qc = ($is_c*$Xc)/$esr;

	return $Qc;
}

# Return a vector of inductive reactance for each frequency:
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
sub y_reactance_l
{
	my ($Y, $f_hz) = @_;

	return 2*PI*$f_hz*y_inductance($Y, $f_hz);
}

# Return a vector of capacitive reactance for each frequency:
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
sub y_reactance_c
{
	my ($Y, $f_hz) = @_;

	return 1.0/(2*PI*$f_hz*y_capacitance($Y, $f_hz));
}

# Return a vector of total reactance for each frequency:
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
sub y_reactance
{
	my ($Y, $f_hz) = @_;

	return y_reactance_l($Y, $f_hz) - y_reactance_c($Y, $f_hz);
}

# Return an array of PDLs, each representing a resonant frequency.
sub y_srf
{
	my ($Y, $f_hz) = @_;

	my $X = y_reactance($Y, $f_hz);

	my ($counts, $vals) = ($X <=> 0)->rle;

	my $f_idx = 0;
	my @ret;
	my $nelem = $X->nelem;

	foreach my $c ($counts->dog)
	{
		$f_idx += $c;
		push @ret, $f_hz->slice($f_idx-1) if $f_idx < $nelem;
	}

	if (wantarray)
	{
		return @ret;
	}
	else
	{
		return $ret[0];
	}
}


# srf: Self-resonating frequency.
#
# This may not be accurate.  While the equation is a classic
# SRF calculation (1/(2*pi*sqrt(LC)), srf should scan the frequency lines as follows:
#    "The SRF is determined to be the frequency at which the insertion (S21)
#    phase changes from negative through zero to positive."
#    [ https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363_measuringsrf.pdf ]
#
# $Y - the Y parameter matrix (N,N,M)
# $f_hz - a vector of frequencies (M)
sub y_srf_ideal
{
	my ($Y, $f_hz) = @_;

	return 1/sqrt( abs 2*PI*y_inductance($Y, $f_hz)*y_capacitance($Y, $f_hz));
}

# Return a parallel representation from a list of (N,N,M) Y-Parameters
#
# @yparams: a list of (N,N,M) piddles
#
# Note: each yparam must be compatible in that:
#   1. The number of frequencies of each must be the same
#   2. The frequency values must correspond because inter-frequency
#      interpolation is _not_ performed.
#
# For example, if you have the Y parameters for two capacitors $C1_y and $C2_y
# at 100pF then in parallel you will get a 200pF capacitor:
#
#   $C_parallel_y = y_parallel($C1_y, $C2_y);
# and thus:
#   200 == y_cap_pF($C_parallel_y)
sub y_parallel
{
	my @yparams = @_;

	my $ret;
	foreach my $y (@yparams)
	{
		if (!defined $ret)
		{
			$ret = $y;
		}
		else
		{
			$ret += $y;
		}
	}

	return $ret;
}

###############################################################################
#                                                   ABCD-Parameter Calculations

# Return a series representation from a list of (N,N,M) ABCD-Parameters
#
# @abcd_params: a list of (N,N,M) piddles
#
# Note: each abcd_param must be compatible in that:
#   1. The number of frequencies of each must be the same
#   2. The frequency values must correspond because inter-frequency
#      interpolation is _not_ performed.
#
# For example, if you have the ABCD parameters for two capacitors $C1_y and
# $C2_y at 100pF then in series you will get a 50pF capacitor:
#
#   $C_series_abcd = abcd_series($C1_abcd, $C2_abcd);
# and thus:
#   50 == y_cap_pF($C_series_abcd)
sub abcd_series
{
	my @abcd_params = @_;

	my $ret;
	foreach my $abcd (@abcd_params)
	{
		if (!defined $ret)
		{
			$ret = $abcd
		}
		else
		{
			$ret = $ret x $abcd;
		}
	}

	return $ret;
}

sub abcd_is_lossless
{
	my ($ABCD, $tolerance) = @_;

	my ($A, $B, $C, $D) = m_to_pos_vecs($ABCD);

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# Lossless when diagonal elements are purely Real and off-diagonal are
	# purely imaginary: https://youtu.be/rfbvmGwN_8o
	return (all(abs($A->im) < $tolerance) && all(abs($D->im) < $tolerance)
		&& all(abs($B->re) < $tolerance) && all(abs($C->re) < $tolerance));
}

# See reference for symmetrical, reciprocal, open_circuit, short_circuit:
# https://resources.system-analysis.cadence.com/blog/msa2021-abcd-parameters-of-transmission-lines
sub abcd_is_symmetrical
{
	my ($ABCD, $tolerance) = @_;

	my ($A, $B, $C, $D) = m_to_pos_vecs($ABCD);

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# A =~ D:
	return all abs($A - $D) < $tolerance;
}

sub abcd_is_reciprocal
{
	my ($ABCD, $tolerance) = @_;

	my ($A, $B, $C, $D) = m_to_pos_vecs($ABCD);

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# AD-BC=1
	return all abs($ABCD->det()) < $tolerance;
}

sub abcd_is_open_circuit
{
	my ($ABCD, $tolerance) = @_;

	my ($A, $B, $C, $D) = m_to_pos_vecs($ABCD);

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# A=C=0
	return (all(abs($A) < $tolerance) && all(abs($C) < $tolerance));
}

sub abcd_is_short_circuit
{
	my ($ABCD, $tolerance) = @_;

	my ($A, $B, $C, $D) = m_to_pos_vecs($ABCD);

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# B=D=0
	return (all(abs($B) < $tolerance) && all abs($D) < $tolerance);
}

###############################################################################
#                                                       Public Helper Functions

# Return the number of ports in an (N,N,M) matrix where N is the port
# count and M is the number of frequencies.
sub n_ports
{
	my $m = shift;

	my @dims = $m->slice(':,:,0')->dims;

	croak "matrix must be square $m" if ($dims[0] != $dims[1]);

	return $dims[0];
}

# Given a PDL of frequencies and a N,N,M piddle of X-parameters, re-scale
# and return $m based on $args.
sub m_interpolate
{
	my ($f, $m, $args) = @_;

	croak "caller must expect an array!" if !wantarray;

	# Interpolate frequency range and input data:
	if (defined $args->{freq_min_hz} && defined $args->{freq_max_hz} && defined $args->{freq_count})
	{
		if ($args->{freq_min_hz} >= $args->{freq_max_hz})
		{
			croak "freq_min_hz=$args->{freq_min_hz} !< freq_max_hz=$args->{freq_max_hz}"
		}

		my $freq_step = ($args->{freq_max_hz} - $args->{freq_min_hz}) / ($args->{freq_count} - 1);
		my $f_new = sequence($args->{freq_count}) * $freq_step + $args->{freq_min_hz};

		# Scale the frequency unit to those requested by the caller:
		my $funit = $args->{units} || 'Hz';
		$f_new = _si_scale_hz('Hz', $funit, $f_new);

		my @cx_cols = m_to_pos_vecs($m);
		my @cx_cols_new;
		foreach my $cx (@cx_cols)
		{
			my ($cx_new, $err) = _interpolate($f_new, $f, $cx);
			if (!$args->{quiet} && any $err != 0)
			{
				carp "Frequency range for interpolation is below/beyond reference frequencies."
			}
			push @cx_cols_new, $cx_new;
		}

		return ($f_new, pos_vecs_to_m(@cx_cols_new));
	}
	elsif (defined $args->{freq_min_hz} || defined $args->{freq_max_hz} || defined $args->{freq_count})
	{
		croak("If any of freq_min_hz, freq_max_hz, or freq_count are defined then all must be defined.");
	}
	else
	{
		# Do nothing, just return the original values.
		return ($f, $m);
	}
}

# Return the maximum difference between an ideal uniformally-spaced frequency set
# and the frequency set provided.  For example:
#   $f = [ 1, 2, 3  , 4 ] would return 0.0
#   $f = [ 1, 2, 2.5, 4 ] would return 0.5
sub f_uniformity
{
	my ($f) = @_;

	my $f_min = $f->slice(0);
	my $f_max = $f->slice(-1);
	my $f_count = $f->nelem;

	my $f_step = ($f_max - $f_min) / ($f_count-1);

	my $f_new = sequence($f_count) * $f_step + $f_min;

	return max(abs($f-$f_new));
}

# Return true if the provided frequency set is uniform within a Hz value.
# We assume $f is provided in Hz, so adjust $tolerance_hz accordingly if
# $f is in a different unit.
sub f_is_uniform
{
	my ($f, $tolerance_hz) = @_;

	$tolerance_hz //= 1;

	return f_uniformity($f) < $tolerance_hz;
}

###############################################################################
#                                                      Private Helper Functions

# Return the number of measurements in the n,n,m pdl:
# This value will be equal to the number of frequencies:
sub _n_meas
{
	my $m = shift;

	my @dims = $m->dims;

	croak "matrix must be square $m" if ($dims[0] != $dims[1]);
	croak "matrix must have a 3rd dimension" if @dims < 3;

	return $dims[2];
}

# Converts a NxNxM pdl where M is the number of frequency samples to a
# N^2-length list of M-sized vectors, each representing a row-ordered position
# in the NxN matrix.  ROW ORDERED!
#
# This enables mutiplying vector positions for things like 2-port S-to-T
# conversion.
#
# For example:
# 	my ($S11, $S12, $S21, $S22) = m_to_pos_vecs($S)
#
# 	$T11 = -$S->det / $S21
# 	$T12 = ...
# 	$T21 = ...
# 	$T22 = ...
#
# @sivoais on irc.perl.org/#pdl calls these "index slices":
sub m_to_pos_vecs
{
	my $m = shift;

	return $m->dummy(0,1)->clump(0..2)->transpose->dog;
}

# inverse of m_to_pos_vecs:
# 	$m = pos_vecs_to_m(m_to_pos_vecs($m))
#
# for example, re-compose $T from the above:
# 	$T = pos_vecs_to_m($T11, $T12, $T21, $T22)
sub pos_vecs_to_m
{
	my @veclist = @_;
	my $n = sqrt(scalar(@veclist));
	my ($m) = $veclist[0]->dims;

	return cat(@veclist)->transpose->reshape($n,$n,$m)
}

# Return the position vector at (i,j).
# Note that i,j start at 1 so this is the first element:
# 	$s11 = pos_vec($S, 1, 1)
sub pos_vec
{
	my ($m, $i, $j) = @_;

	my $n_ports = n_ports($m);

	croak "position indexes (i,j) must be defined" if !defined($i) || !defined($j);
	croak "position indexes start at 1: i=$i j=$j" if $i < 1 || $j < 1;
	croak "requested position index than the matrix: i=$i > $n_ports" if ($i> $n_ports);
	croak "requested position index than the matrix: j=$j > $n_ports" if ($j> $n_ports);

	my @pos_vecs = m_to_pos_vecs($m);

	# Expect port numbers like (1,1) or (2,1) but perl expects indexes at 0:
	$i--;
	$j--;

	return $pos_vecs[$i * $n_ports + $j];
}

# Create a diagonal matrix of size n from a scalar or vector $v.
#
# For example, $v can represent charectaristic impedance at each port either as:
#   * a perl scalar value
#   * a 0-dim pdl like pdl( 5+2*i() )
#   * a 1-dim single-element pdl like pdl( [5+2*i()] )
#   * a 1-dim pdl representing the charectaristic impedance at each port
#
# In any case, the return value is an (N,N) pdl whith charectaristic impedances
# for each port along the diagonal:
#   [50  0]
#   [ 0 50]
sub _to_diagonal
{
	my ($v, $n_ports) = @_;

	my $ret;

	$v = pdl $v if (!ref($v));

	croak "v must be a PDL or scalar" if (ref($v) ne 'PDL');

	my @dims = $v->dims;

	if (!@dims || (@dims == 1 && $dims[0] == 1))
	{
		$ret = zeroes($n_ports,$n_ports);
		$ret->diagonal(0,1) .= $v;
	}
	elsif (@dims == 1 && $dims[0] == $n_ports)
	{
		$ret = stretcher($v);
	}
	else
	{
		croak "\$v must be either a scalar or vector of size $n_ports: $v"
	}

	return $ret;
}

sub _interpolate
{
	my ($xi, $x, $y) = @_;

	#return interpolate($xi, $x, $y);

	my $y_re = $y->re;
	my $y_im = $y->im;

	my ($yi_re, $err1) = interpolate($xi, $x, $y_re);
	my ($yi_im, $err2) = interpolate($xi, $x, $y_im);

	return ($yi_re+$yi_im*i(), $err1+$err2);
}

1;

__END__

=head1 NAME

PDL::IO::Touchstone - Read and manipulate Touchstone .s2p (and .sNp) files.

=head1 DESCRIPTION

A simple interface for reading and writing RF Touchstone files (also known as
".sNp" files).  Touchstone files contain complex-valued RF sample data for a
device or RF component with some number of ports. The data is (typically)
measured by a vector network analyzer under stringent test conditions.

The resulting files are usually provided by manufacturers so RF design
engineers can estimate signal behavior at various frequencies in their circuit
designs.  Examples of RF components include capacitors, inductors, resistors,
filters, power splitters, etc.

This C<PDL::IO::Touchstone> module is very low-level and returns lots of
variables to keep track of.  Instead, I recommend that you use L<RF::Component>
module for an object-oriented approach which encapsulates the data returned by
C<rsnp()> and will, most likely, simplify your RF component implementation.

=head1 SYNOPSIS

	use PDL::IO::Touchstone;

	# Read input matrix:
	($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) =
		rsnp('input-file.s2p', { units => 'MHz' });


	# Write output file:
	wsnp('output-file.s2p',
		$f, $m, $param_type, $z0, $comments, $fmt, $from_hz, $to_hz);

You can reproduce the same output file from an input as follows:

	@data = rsnp('input-file.s2p');
	wsnp('output-file.s2p', @data);

You may convert between output formats or frequency scale by changing the
C<$fmt> and C<$to_hz> fields when writing:

	@data = rsnp('input-file.s2p');
	$data[5] = 'DB'; # $fmt
	$data[7] = 'MHz' # $to_hz in wsnp() or $orig_f_unit from rsnp().
	wsnp('output-file.s2p', @data);

Note that you may change neither C<$param_type> nor C<$z0> unless you have done
your own matrix transform from one parameter type (or impedance) to another.
This is because while C<wsnp> knows how to convert between RA,
MA, and DB formats, it does not manipulate the matrix to convert between
parameter types (or impedances).  Use the C<P_to_Q()> functions below to transform between matrix types.

=head1 IO Functions

=head2 C<rsnp($filename, $options)> - Read touchstone file

=head3 Arguments:

=over 4

=item * $filename - the file to read

=item * $options - A hashref of options:

=over 4

=item units: Hz, KHz, MHz, GHz, or THz.

Units may specify one of Hz, KHz, MHz, GHz, or THz.  The resulting C<$f> vector
will be scaled to the frequency format you specify.  If you do not specify a
format then C<$f> will be scaled to Hz such that a value of 1e6 in the C<$f>
vector is equal to 1 MHz.

=item freq_min_hz, freq_max_hz, freq_count: see C<m_interpolate()>

If these options are passed then the matrix (C<$m>) and frequency (C<$f>) PDLs
returned by C<rsnp()> will have been interpolated by C<m_interpolate()>.

=back

=back

=head3 Return values

The first set of parameters (C<$f>, C<$m>, C<$param_type>, C<$z0>) are required to properly
utilize the data loaded by C<rsnp()>:

=over 4

=item * C<$f> - A (M) vector piddle of input frequencies where C<M> is the
number of frequencies.

=item * C<$m> - A (N,N,M) piddle of X-parameter matrices where C<N> is the number
of ports and C<M> is the number of frequencies.

These matrixes have been converted from their 2-part RI/MA/DB input format and
are ready to perform computation.  Matrix values (S11, etc) use PDL's
native complex values.

=item * C<$param_type> - one of S, Y, Z, H, G, T, or A that indicates the
matrix parameter type.

Note that T and A are not officially supported Touchstone formats, but you can
still load them with this module (but it is up to you to know how to use them).

=item * C<$z0> - The characteristic impedance reference used to collect the measurements.

=back

The remaining parameters (C<$comments>, C<$fmt>, C<$funit>) are useful only if you wish to
re-create the original file format by calling C<wsnp()>:

=over 4

=item * C<$comments> - An ARRAY-ref of full-line comments provided at the top of the input file.

=item * C<$fmt> - The format of the input file, one of:

=over 4

=item * C<RI> - Real/imaginary format

=item * C<MA> - Magnitude/angle format

=item * C<DB> - dB/angle format

=back

=item * C<$funit> - The frequency unit used by the C<$f> vector

The C<$funit> value is typically 'Hz' unless you overrode the frequency scaling unit with C<$options> in your
call to C<rsnp()>.  If you specified a unit the C<$funit> will use that unit so a call to C<wsnp()> will
re-create the original touchstone file.

=item * C<$orig_funit> - The frequency unit used by the original input file.

=back

=head2 C<wsnp($filename, $f, $m, $param_type, $z0, $comments, $fmt, $from_hz, $to_hz)>

=head3 Arguments

Except for C<$filename> (the output file), the arguments to C<wsnp()> are the
same as those returned by C<rsnp()>.

When writing it is up to you to maintain consistency between the output format
and the data being represented.  Except for complex value representation in
C<$fmt> and frequency scale in C<$f>, this C<PDL::IO::Touchstone> module will
not make any mathematical transform on the matrix data.

Changing C<$to_hz> will modify the frequency format in the resultant Touchstone
file, but the represented data will remain correct because Touchstone knows how
to scale frequencies.

Roughly speaking this should create an identical file to the input:

	wsnp('output.s2p', rsnp('input.s2p'));

However, there are a few output differences that may occur:

=over 4

=item * Floating point rounding during complex format conversion

=item * Same-line "suffix comments" are stripped

=item * The order of comments and the "# format" line may be changed.
C<wsnp()> will write comments before the "# format" line.

=item * Whitespace may differ in the output.  Touchstone specifies any whitespace as a
field delimiter and this module uses tabs as delimiters when writing output data.

=back

=head2 C<wsnp_fh($fh, $f, $m, $param_type, $z0, $comments, $fmt, $from_hz, $to_hz)>

Same as C<wsnp()> except that it takes a file handle instead of a filename.
Internally C<wsnp()> uses C<wsnp_fh()> and C<wsnp_fh()> can be useful for
building MDF files, however MDF files are much more complicated and outside of
this module's scope.  Consult the L</"SEE ALSO"> section for more about MDFs and optimizing circuits.

=head1 S-Parameter Conversion Functions

=over 4

=item * Each matrix below is in the (N,N,M) format where N is the number of ports and M
is the number of frequencies.

=item * The value of C<$z0> in the conversion functions may be complex-valued and
is represented as either:

=over 4

=item - A perl scalar value: all ports have same impedance

=item - A 0-dim pdl like pdl( 5+2*i() ): all ports have same impedance

=item - A 1-dim single-element pdl like pdl( [5+2*i()] ): all ports have same impedance

=item - A 1-dim pdl representing the charectaristic impedance at each port: ports may have different impedances

=back

=back

=head2 C<$Y = s_to_y($S, $z0)>: Convert S-paramters to Y-parameters.

=over 4

=item * C<$S>: The S-paramter matrix

=item * C<$z0>: Charectaristic impedance (see above).

=item * C<$Y>: The resultant Y-paramter matrix

=back

=head2 C<$S = y_to_s($Y, $z0)>: Convert Y-paramters to S-parameters.

=over 4

=item * C<$Y>: The Y-paramter matrix

=item * C<$z0>: Charectaristic impedance (see above).

=item * C<$S>: The resultant S-paramter matrix

=back

=head2 C<$Z = s_to_z($S, $z0)>: Convert S-paramters to Z-parameters.

=over 4

=item * C<$S>: The S-paramter matrix

=item * C<$z0>: Charectaristic impedance (see above).

=item * C<$Z>: The resultant Z-paramter matrix

=back

=head2 C<$S = z_to_s($Z, $z0)>: Convert Z-paramters to S-parameters.

=over 4

=item * C<$Z>: The Z-paramter matrix

=item * C<$z0>: Charectaristic impedance (see above).

=item * C<$S>: The resultant S-paramter matrix

=back

=head2 C<$ABCD = s_to_abcd($S, $z0)>: Convert S-paramters to ABCD-parameters.

=over 4

=item * C<$S>: The S-paramter matrix

=item * C<$z0>: Charectaristic impedance (see above).

=item * C<$ABCD>: The resultant ABCD-paramter matrix

=back

=head2 C<$S = abcd_to_s($ABCD, $z0)>: Convert ABCD-paramters to S-parameters.

=over 4

=item * C<$ABCD>: The ABCD-paramter matrix

=item * C<$z0>: Charectaristic impedance (see above).

=item * C<$S>: The resultant S-paramter matrix

=back

=head1 S-Paramter Calculaction Functions

All functions prefixed with "s_" require an S-parameter matrix.

=head2 C<$z0n = s_port_z($S, $z0, $n)> - Return the complex port impedance vector for each frequency

=over 4

=item - C<$S>: S paramter matrix

=item - C<$z0>: vector of _reference_ impedances at each port (from C<rsnp>)

=item - C<$n>: the port we want.

=back

In a 2-port, this will provide the input or output impedance as follows:

    $z_in  = s_port_z($S, 50, 1);
    $z_out = s_port_z($S, 50, 2);

Note that C<$z_in> and C<$z_out> are the PDL vectors for the input or output
impedance at each frequency in C<$f>.  (NB, C<$f> is not actually needed for
the calculation.)

=head1 Y-Paramter Calculaction Functions

All functions prefixed with "y_" require a Y-parameter matrix.

These functions are intended for use with 2-port matrices---but if you know
what you are doing they may work for higher-order matrices as well.

Unless otherwise indicated:

=over 4

=item * C<$Y> is a set Y-parameter matrices (one for each frequency), either  loaded directly from
a Y-formatted .s2p file or converted via C<s_to_y> or similar functions.

=item * C<$f_hz> is a vector of frequencies in Hz (one for each Y-matrix in
C<$Y>); C<$f_hz> is assumed to be sorted in ascending order and correspond to
each Mth element in C<$Y> of dimension N,N,M where N is the number of ports and
M is the number of sample frequencies.


=back

=head2 C<$C = y_capacitance($Y, $f_hz)> - Return a vector of capacitance for each frequency in Farads (F)

=head2 C<$C = y_cap_pF($Y, $f_hz)> - Return a vector of capacitance it each frequency in picofarads (pF)

=head2 C<$L = y_inductance($Y, $f_hz)> - Return a vector of inductance for each frequency in Henrys (H)

=head2 C<$L = y_ind_nH($Y, $f_hz)> - Return a vector of inductance for each frequency in nanohenrys (nH)

=head2 C<$Qc = y_qfactor_c($Y, $f_hz)> - Return the capacitive Q-factor vector for each frequency

Note that all inductive values are zeroed.

=head2 C<$Ql = y_qfactor_l($Y, $f_hz)> - Return the inductive Q-factor vector for each frequency

Note that all capacitive values are zeroed.

=head2 C<$X = y_reactance($Y, $f_hz)> - Return a vector of total reactance for each frequency

This is the same as (Xl - Xc).

=head2 C<$Xc = y_reactance_c($Y, $f_hz)> - Return a vector of capacitive reactance for each frequency

=head2 C<$Xl = y_reactance_l($Y, $f_hz)> - Return a vector of inductive reactance for each frequency

=head2 C<$R = y_resistance($Y)> - Return the equivalent series resistance (ESR) in Ohms

=head2 C<$R = y_esr($Y, $f_hz)> - An alias for C<y_resistance>.

=head2 C<@srf_list_hz = y_srf($Y, $f_hz)> - Return the component's self-resonant frequencies (SRF)

To calculate SRF, reactance is evaluated at each frequency.  If the next frequency being
evaulated has an opposite sign (ie, going from capacitive to inductive reactance) then
that previous frequency is selected as an SRF.

Return value:

=over 4

=item * List context: Return the list of SRF's in ascending order, or an empty list if no SRF is found.

=item * Scalar context: Return the lowest-frequency SRF, or undef if no SRF is found.

=back

=head2 C<$f_hz = y_srf_ideal($Y, $f_hz)> - Return the component's first self-resonant frequency

Notice: In almost all cases you will want C<y_srf> instead of C<y_srf_ideal>.

This is included for ideal Y-matrices only and may not be accurate.  While the
equation is a classic SRF calculation (1/(2*pi*sqrt(LC)), SRF should scan the
frequency lines as follows: "The SRF is determined to be the frequency at which
the insertion (S21) phase changes from negative through zero to positive."
[ L<https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363_measuringsrf.pdf> ]

=head1 Circuit Composition

=head2 C<$Y_pp = y_parallel($Y1, $Y2, [...])> - Compose a parallel circuit

For example, if C<$Y1> and C<$Y2> represent a 100pF capacitor, then C<$Y_pp> will
represent a ~200pF capacitor. Parameters and return value must be
Y matrices converted by a function like C<s_to_y>.

=head2 C<$ABCD_ss = abcd_series($ABCD1, $ABCD2, [...])> - Compose a series circuit

For example, if C<$ABCD1> and C<$ABCD2> represent a 100pF capacitor, then
C<$ABCD_ss> will represent a ~50pF capacitor.  Parameters and return value must be
ABCD matrices converted by a function like C<s_to_abcd>.

=head1 Helper Functions

=head2 C<$n = n_ports($S)> - return the number of ports represented by the matrix.

Given any matrix (N,N,M) formatted matrix, this function will return N.

=head2 C<($f_new, $m_new) = m_interpolate($f, $m, $args)> - Interpolate C<$m> to a different frequency set

This function rescales the X-parameter matrix (C<$m>) and frequency set (C<$f>)
to fit the requested frequency bounds.  This example will return the
interpolated C<$S_new> and C<$f_new> with 10 frequency samples from 100 to 1000
MHz (inclusive):

    ($f_new, $S_new) = m_interpolate($f, $S,
	{ freq_min_hz => 100e6, freq_max_hz => 1000e6, freq_count => 10,
	  quiet => 1 # optional
	} )

This function returns C<$f> and C<$m> verbatim if no C<$args> are passed.

=over 4

=item * freq_min_hz: the minimum frequency at which to interpolate

=item * freq_max_hz: the maximum frequency at which to interpolate

=item * freq_count: the total number of frequencies sampled

=item * quiet: suppress warnings when interpolating beyond the available frequency range

=back

=head2 C<$max_diff = f_uniformity($f)> - Return maximum frequency deviation.

Return the maximum difference between an ideal uniformally-spaced frequency set
and the frequency set provided.  This is used internally by C<f_is_uniform()>.
For example:

  0.0 == f_uniformity(pdl [ 1, 2, 3  , 4 ]);
  0.5 == f_uniformity(pdl [ 1, 2, 2.5, 4 ]);


=head2 C<$bool = f_is_uniform($f, $tolerance_hz)> - Return true if the frequency set is uniform

Return true if the provided frequency set is uniform within a Hz value.
We assume C<$f> is provided in Hz, so adjust C<$tolerance_hz> accordingly if
$f is in a different unit.

=head2 C<@vecs = m_to_pos_vecs($m)> - Convert N,N,M piddle to row-ordered index slices.

Converts a NxNxM pdl where M is the number of frequency samples to a
N^2-length list of M-sized vectors, each representing a row-ordered position
in the NxN matrix.  ROW ORDERED!  @sivoais on irc.perl.org/#pdl calls these
"index slices".

This enables mutiplying vector positions for things like 2-port S-to-T
conversion.

For example:

	my ($S11, $S12, $S21, $S22) = m_to_pos_vecs($S)

	$T11 = -$S->det / $S21
	$T12 = ...
	$T21 = ...
	$T22 = ...

See also the inverse C<pos_vecs_to_m> function.

=head2 C<$m = pos_vecs_to_m(@vecs)> - Convert row-ordered index slices to an N,N,M piddle.

This is the inverse of C<m_to_pos_vecs>, here is the identity transform:

	$m = pos_vecs_to_m(m_to_pos_vecs($m))

For example, re-compose $T from the C<m_to_pos_vecs> example.

	$T = pos_vecs_to_m($T11, $T12, $T21, $T22)



=head1 SEE ALSO

=over 4

=item L<RF::Component> - An object-oriented encapsulation of C<PDL::IO::Touchstone>.

=item Touchstone specification: L<https://ibis.org/connector/touchstone_spec11.pdf>

=item S-parameter matrix transform equations: L<http://qucs.sourceforge.net/tech/node98.html>

=item Building MDF files from multiple S2P files: L<https://youtu.be/q1ixcb_mgeM>, L<https://github.com/KJ7NLL/mdf/>

=item Optimizing amplifer impedance match circuits with MDF files: L<https://youtu.be/nx2jy7EHzxw>

=item MDF file format: L<https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#i489154>

=item "Conversions Between S, Z, Y, h, ABCD, and T Parameters which are Valid
for Complex Source and Load Impedances" March 1994 IEEE Transactions on
Microwave Theory and Techniques 42(2):205 - 211 L<https://www.researchgate.net/publication/3118645>

=back

=head1 AUTHOR

Originally written at eWheeler, Inc. dba Linux Global Eric Wheeler to
transform .s2p files and build MDF files to optimize with Microwave Office
for amplifer impedance matches.


=head1 COPYRIGHT

Copyright (C) 2022 eWheeler, Inc. L<https://www.linuxglobal.com/>

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see <http://www.gnu.org/licenses/>.


