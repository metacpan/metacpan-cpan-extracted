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

package PDL::IO::MDIF;

# Use PDL::IO::Touchstone's version.  See https://stackoverflow.com/a/74264406/14055985 .
use PDL::IO::Touchstone; our $VERSION = $PDL::IO::Touchstone::VERSION;

use 5.010;
use strict;
use warnings;
use Carp;

use PDL::IO::Touchstone qw/rsnp_fh wsnp_fh n_ports/;

BEGIN {
	use Exporter;
	our @ISA = ( @ISA, qw(Exporter) );
	our @EXPORT = qw/ rmdif rmdf wmdif wmdf /;
	our @EXPORT_OK = ();

	our %EXPORT_TAGS = (ALL => [ @EXPORT, @EXPORT_OK ]);
}

sub rmdif
{
	my ($filename, $args) = @_;

	open(my $in, $filename) or croak "$filename: $!";

	# Clone the input args and add to it:
	$args = \%{ $args // {} };
	$args->{filename} = $filename;
	$args->{EOF_REGEX} = qr/^END$/;

	my %vars;
	my @ret;
	while (defined(my $line = <$in>))
	{
		chomp $line;

		if ($line =~ /^\s*!\s*(.*?)\s*$/)
		{
			push @{ $vars{_comments} }, $1;
		}
		elsif ($line =~ /^\s*VAR\s+([^=]+?)\s*=\s*"?(.+?)"?\s*$/i)
		{
			$vars{$1} = $2;
		}
		elsif ($line =~ /^\s*BEGIN\s+ACDATA\s*$/)
		{
			my @rsnp = rsnp_fh($in, $args);
			push @ret, { %vars, _data => \@rsnp };
			%vars = ();
		}
		elsif ($line =~ /^\s*BEGIN\s*NFDATA/)
		{
			carp "$filename: NFDATA (noise data) is not supported, skipping.";
			while (defined($line = <$in>) && $line !~ /^\s*END/) {}
		}
	}

	close($in) or carp "$filename: $!";

	return \@ret;
}
*rmdf = \&rmdif;

sub wmdif
{
	my ($filename, $components) = @_;

	#my ($components, $fmt, $type, $fd) = @opts{qw/components format type/};

	open(my $out, ">", $filename) or croak "$filename: $!";

	my $n_ports;
	my $n = 1;
	foreach my $c (@$components)
	{
		croak "$filename: component $n does not define _data!" if !defined $c->{_data};

		if ($c->{_comments})
		{
			my $comments = join("\n", map { "! $_" } @{ $c->{_comments} });
			print $out "$comments\n";
		}
		 
		# Iterate vars that don't start with an underscore:
		foreach my $var (grep { !/^_/ } keys(%$c))
		{
			my $val = $c->{$var};

			# Quote if its not a number:
			$val = "\"$val\"" if $val !~ /^[-+]?[0-9]*\.?[0-9]+$/;

			print $out "VAR $var=$val\n";
		}

		print $out "BEGIN ACDATA\n";

		my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = @{ $c->{_data} };
		my $n_ports = n_ports($m);

		# In the AWR and Keysight example formats the %F line comes
		# _after_ the "# HZ" line from the original s2p.  Fixing this
		# requires hooking the touchstone code somewhere or
		# re-processing the MDF; since it works in AWR we'll leave it
		# for now.  If you have trouble with the MDF output then swap
		# the #HZ and %F lines.  If it works after the swap then open a
		# bug to fix this.  References:
		#    https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#d0e5542
		#    https://edadocs.software.keysight.com/display/ads2009/Working+with+Data+Files#WorkingwithDataFiles-1135104
		my $pct_line = "% F";
		for (my $i = 1; $i <= $n_ports; $i++)
		{
			for (my $j = 1; $j <= $n_ports; $j++)
			{
				$pct_line .= sprintf(" %s[%d,%d](Complex)", $param_type, $j, $i);
			}
		}
		
		print $out "$pct_line\n";

		wsnp_fh($out, @{ $c->{_data} });
		print $out "END\n\n";
	}

	close($out);
}
*wmdf = \&wmdif;

1;

__END__

=head1 NAME

PDL::IO::MDIF - Read and manipulate Measurement Data Interchange Format (MDIF, *.mdf) files.

=head1 DESCRIPTION

A simple interface for reading and writing RF MDIF files (also known as MDF or
.mdf files).  MDIF files contain multiple Touchstone files in a text format;
consult the L</"SEE ALSO"> section for more about the MDIFs format and using
them to optimize circuits. For example, a single MDIF file could contain the
Touchstone RF data for each available value in a line of capacitors (ie, from
10pF to 1000pF) provided by a particular manufacturer. 

MDIF files contain Touchstone-formatted data representing multiple components,
so L<PDL::IO::Touchstone> is used internally for processing the Touchstone
data.

A notable difference between Touchstone files and MDIF files is that MDIF supports
variable parameters within the MDIF file itself. For example, an MDIF file containing
a set of capacitor data of different values might define the following:

	VAR pF = 1000
	VAR Vmax = 250

These variables are provided in the return value of C<rmdif> as shown below.

=head1 SYNOPSIS

	use PDL::IO::MDIF;

	# Read input matrix into an arrayref:
	$mdif_data = rmdif('input-file.mdf', { units => 'MHz' });

	# Write output file:
	wmdif('output-file.mdf', $mdif_data);

=head1 IO Functions

=head2 C<rmdif($filename, $options)> - Read MDIF file

C<$options> is a hashref passed to L<PDL:IO::Touchstone>'s C<rsnp> function.
The function C<rmdf> is an alias for C<rmdif>.

	# Read input matrix into an arrayref:
	$mdif_data = rmdif('input-file.mdf');

It returns the an arrayref of hashrefs, as follows:

	[ 
		# Component 1
		{
			var1 => "val1",
			var2 => -123, 
			...
			_data => [ @rsnp_data ],
			_comments => [ 'comment line 1', 'comment line 2', ... ]
		},

		# Component 2:
		{
			pF => 1000,  # component value in pF
			Vmax => 250, # component maximum voltage
			...
			_data => [ @rsnp_data ]
		},

		...
	]

=over 4

=item * MDIF Variable (parameter) Names

The example variables and values above (var1, pF, etc) are arbitrary; they are
specific to the MDIF file being read.

=item * C<_data> Structure

The C<_data> hash element is an array refernce to exactly that which was
returned by L<PDL::IO::Touchstone>'s C<rsnp()> function.  It is prefixed with
an underscore to prevent name collisions with the MDIF file being loaded.

This may deviate from the typical PDL structures in the sense that frequency
and S-parameter data is not combined into one big PDL.  There are a number of
reasons for this, but notably, the frequencies and RF port count in each
component contained in the MDF are not required to be identical.

Since they are not guaranteed to be consistent the best we can do is generate a
structure containing all of the data and let the user parse what they need.
Interpolation using things like L<PDL::IO::Touchstone>'s  C<m_interpolate>
function is possible if the frequencies differ, but we don't want to modify the
source data, and that wouldn't address the RF port count issue.

=item * C<_comments> Structure

Comments are simply an arrayref of strings, one for each comment line.  When
written by C<wsnp>, each comment will be written before that component's
section on the resulting .mdf text file.

=back

=head2 C<wmdif($filename, $mdif_data)> - Write MDIF file

The C<wmdif> function writes the MDIF data in C<$mdif_data> to C<$filename>.
The function C<wmdf> is an alias for C<wmdif>.

Internally wmdif uses L<PDL::IO::Touchstone>'s  C<wsnp_fh> function to write
Touchstone data for each component into the MDIF file.  To generate an MDIF
file from multiple Touchstone files you can read each Touchstone file and merge
them as follows:

	my @cap_100pF = rsnp('100pF.s2p');
	my @cap_200pF = rsnp('200pF.s2p');
	my @cap_300pF = rsnp('300pF.s2p');

	wmdif("my_caps.mdf", [
			{ pF => 100, _data => \@cap_100pF },
			{ pF => 200, _data => \@cap_200pF },
			{ pF => 300, _data => \@cap_300pF },
		]);

Note that C<pF> is just an arbitrary variable that will be stored in the MDIF file
for reference when you load it in your EDA software.

You may transform the content of C<$mdif_data> in any way that is suitable to
your application before writing the file provided the resulting data is valid.
For example, if you convert S paramters to Z parameters using C<s_to_z> then be
sure to set C<$param_type> to C<Y> before writing the MDIF output. See
L<PDL::IO::Touchstone> for details.

=head1 SEE ALSO

=over 4

=item MDIF file format from AWR: L<https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#i489154>

=item MDIF file format from Keysight L<https://edadocs.software.keysight.com/display/ads2009/Working+with+Data+Files#WorkingwithDataFiles-1135104>

=item L<RF::Component> - An object-oriented encapsulation of C<PDL::IO::Touchstone>.

=item L<PDL::IO::Touchstone> - A L<PDL> IO module to load Touchstone (*.sNp, s2p, ...) files.

=item Touchstone specification: L<https://ibis.org/connector/touchstone_spec11.pdf>

=item Building MDIF/MDF files from multiple S2P files: L<https://youtu.be/q1ixcb_mgeM>, L<https://github.com/KJ7NLL/mdf/>

=item Optimizing amplifer impedance match circuits with MDIF files: L<https://youtu.be/nx2jy7EHzxw>

=back

=head1 AUTHOR

Originally written at eWheeler, Inc. dba Linux Global Eric Wheeler to
transform .s2p files and build MDIF files to optimize with Microwave Office
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
