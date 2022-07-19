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
$VERSION = 1.001;

use 5.010;
use strict;
use warnings;

use Carp;

use PDL;
use PDL::Ops;
use PDL::Constants qw(PI);

BEGIN {  
	use Exporter;
	our @ISA = ( @ISA, qw(Exporter) );
	our @EXPORT = qw/rsnp wsnp/;
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

	my $hz;

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

			$hz = shift(@params);
			$f[$row_idx] = $hz;
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

	foreach my $c (@cols)
	{
		$c->[0] = pdl $c->[0];
		$c->[1] = pdl $c->[1];
	}

	my $m = _cols_to_matrix($fmt, \@cols);

	my $f = pdl \@f;

	my $funit;
	if ($args->{units})
	{
		$funit = $args->{units};
	}
	else
	{
		$funit = 'Hz'
	}

	$f = _si_scale_hz($orig_funit, $funit, $f);
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

	my ($n_ports) = $m->index(0)->dims;
	my $n_freqs = $f->nelem;

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
	if ($fmt eq 'ri')
	{
		$a = $d->re;
		$b = $d->im;
	}
	elsif ($fmt eq 'ma')
	{
		$a = $d->abs;
		$b = $d->carg * 180 / PI;
	}
	elsif ($fmt eq 'db')
	{
		$a = 20*log($d->abs)/log(10);
		$b = $d->carg * 180 / PI;
	}

	# Prepare real/imag values for interleaving:
	my $ab = $a->append($b);

	# Create one row per frequency: (n_ports*2, n_freqs):
	my $out = $ab->clump(0..2);

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
sub _cols_to_matrix
{
	my ($fmt, $cols) = @_;

	$fmt = lc $fmt;
	my @cx;
	my $n = $cols->[0][0]->nelem;
	my $n_ports = sqrt(scalar @$cols);

	foreach my $c (@$cols)
	{
		my $a = $c->[0];
		my $b = $c->[1];
		if ($fmt eq 'ri')
		{
			push @cx, $a + $b*i();
		}
		elsif ($fmt eq 'ma')
		{
			push @cx, $a*exp(i()*$b*PI()/180);
		}
		elsif ($fmt eq 'db')
		{
			my $a = 10**($a/20);
			push @cx, $a*exp(i()*$b*PI()/180);
		}
		else
		{
			croak "Unknown s-parameter format: $fmt";
		}
	}

	my $m = pdl \@cx;
	$m = $m->mv(0, -1)->reshape($n_ports,$n_ports,$n);
}

sub _si_scale_hz
{
	my ($from, $to, $n) = @_;

	my %scale = 
	(
		hz => 1,
		khz => 1e3,
		mhz => 1e6,
		ghz => 1e9,
		thz => 1e12,
	);

	$from = $scale{lc($from)};
	$to = $scale{lc($to)};

	my $fscale = $from/$to;

	croak "Unknown frequency scale: $fscale" if !$fscale;

	return $n*$fscale;
}

1;

__END__

=head1 NAME

PDL::IO::Touchstone 

=head1 DESCRIPTION

A simple interface for reading and writing RF Touchstone files (also known as
".sNp" files).  Touchstone files contain complex-valued RF sample data for a
device or RF component with some number of ports. The data is (typically)
measured by a vector network analyzer under stringent test conditions.

The resulting files are usually provided by manufacturers so RF design
engineers can estimate signal behavior at various frequencies in their circuit
designs.  Examples of RF components include capacitors, inductors, resistors,
filters, power splitters, etc.

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
This is because while C<PDL::IO::Touchstone> knows how to convert between RA,
MA, and DB formats, it does not manipulate the matrix to convert between
parameter types (or impedances).


=head2 C<rsnp($filename, $options)> - Read touchstone file

=head3 Arguments: 

=over 4

=item * $filename - the file to read

=item * $options - A hashref of options.

Currently only 'units' is supported, which may specify one of Hz, KHz, MHz,
GHz, or THz.  The resulting C<$f> vector will be scaled to the frequency format
you specify.  If you do not specify a format then C<$f> will be scaled to Hz
such that a value of 1e6 in the C<$f> vector is equal to 1 MHz.

=back

=head3 Return values

The first set of parameters (C<$f>, C<$m>, C<$param_type>, C<$z0>) are required to properly
utilize the data loaded by C<rsnp()>:

=over 4

=item * C<$f> - A (M,1) vector piddle of input frequencies where C<M> is the
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

=head1 SEE ALSO

=over 4

=item Touchstone specification: L<https://ibis.org/connector/touchstone_spec11.pdf>

=item Building MDF files from multiple S2P files: L<https://youtu.be/q1ixcb_mgeM>, L<https://github.com/KJ7NLL/mdf/>

=item Optimizing amplifer impedance match circuits with MDF files: L<https://youtu.be/nx2jy7EHzxw>

=item MDF file format: L<https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#i489154>

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


