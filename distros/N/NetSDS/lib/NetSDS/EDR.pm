#===============================================================================
#
#         FILE:  EDR.pm
#
#  DESCRIPTION:  Module for reading/writing Event Details Records
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  28.08.2009 16:43:02 EEST
#===============================================================================

=head1 NAME

NetSDS::EDR - read/write Event Details Records

=head1 SYNOPSIS

	use NetSDS::EDR;

	my $edr = NetSDS::EDR->new(
		filename => '/mnt/billing/call-stats.dat',
	);

	...

	$edr->write(
		{
		callerid => '80441234567',
		clip => '89001234567',
		start_time => '2006-12-55 12:21:46',
		end_time => '2008-12-55 12:33:22'
		}
	);

=head1 DESCRIPTION

C<NetSDS::EDR> module implements API for writing EDR (Event Details Record) files
form applications.

EDR itself is set of structured data describing details of some event. Exact
structure depends on event type and so hasn't fixed structure.

In NetSDS EDR data is written to plain text files as JSON structures one row per record.

=cut

package NetSDS::EDR;

use 5.8.0;
use strict;
use warnings;

use JSON;
use NetSDS::Util::DateTime;
use base 'NetSDS::Class::Abstract';

use version; our $VERSION = '1.301';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

Parameters:

* filename - EDR file name

Example:

    my $edr = NetSDS::EDR->new(
		filename => '/mnt/stat/ivr.dat',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	# Create JSON encoder for EDR data processing
	$self->{encoder} = JSON->new();

	# Initialize file to write
	if ( $params{filename} ) {
		$self->{edr_file} = $params{filename};
	} else {
		return $class->error("Absent mandatory parameter 'filename'");
	}

	return $self;

}

#***********************************************************************

=item B<write($rec1 [,$rec2 [...,$recN]])> - write EDR to file

This methods converts records to JSON and write to file.
Each record writing to one separate string.

Example:

	$edr->write({from => '380441234567', to => '5552222', status => 'busy'});

=cut

#-----------------------------------------------------------------------
sub write {

	my ( $self, @records ) = @_;

	open EDRF, ">>$self->{edr_file}";

	# Write records - one record per line
	foreach my $rec (@records) {
		my $edr_json = $self->{encoder}->encode($rec);
		print EDRF "$edr_json\n";
	}

	close EDRF;

}

1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory.

=head1 TODO

* Handle I/O errors when write EDR data.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


