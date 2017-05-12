package Spreadsheet::WriteExcel::Worksheet::SheetProtection;

use 5.005;
use strict;

use vars '$VERSION';

$VERSION = '0.03';

BEGIN {
	use Spreadsheet::WriteExcel::Worksheet;
	no strict 'refs';

	## HACK ALERT!
	## Add a _store_eof method to Spreadsheet::WriteExcel::Worksheet to be able to
	## add the SHEETPROTECTION record when streaming out file
	*{"Spreadsheet::WriteExcel::Worksheet::_store_eof"} = sub {
			_store_sheet_protection(@_);
			Spreadsheet::WriteExcel::BIFFwriter::_store_eof(@_);
		} ;

	## Add sheet_protection method
	*{"Spreadsheet::WriteExcel::Worksheet::sheet_protection"} = \&sheet_protection;
}


=head1 NAME

Spreadsheet::WriteExcel::Worksheet::SheetProtection - Sheet Protection extension
for Spreadsheet::WriteExcel::Worksheet

=head1 SYNOPSIS

	use Spreadsheet::WriteExcel;
	use Spreadsheet::WriteExcel::Worksheet::SheetProtection;

	my $workbook = new Spreadsheet::WriteExcel("file.xls");
	my $worksheet = $workbook->add_worksheet;
	
	...

	# Protect workseet
	$worksheet->protect;
	
	## Specify protection settings
	## Disallow selection of locked cells but allow column formatting
	$worksheet->sheet_protection(
				-select_locked_cells => 0,
				-format_columns => 1 );

=head1 DESCRIPTION

This module allows you to specify the sheet protection attribute available in recent
versions of Microsoft Excel (Menu item: Tools > Protection > Protect Sheet...).

It extends the L<Spreadsheet::WriteExcel::Worksheet> class by adding a
C<sheet_protection> method which you use to specify the protection attributes.

=head2 Protection Flags

The following flags can be set (or cleared) to specify which aspects of a
worksheet are protected.

	SelectLockedCells    (Default set)
	SelectUnlockedCells  (Default set)

	FormatCells
	FormatColumns
	FormatRows

	InsertColumns
	InsertRows
	InsertHyperlinks

	DeleteColumns
	DeleteRows

	Sort

	UseAutoFilters
	UsePivotTableReports

	EditObjects
	EditScenarios

The flag names are case insensitive and non-letter characters are ignored, so
the following are all valid and equivalent:

	SelectLockedCells
	"select locked cells"
	-select_locked_cells

=cut

my $default_protection = 0x4400;	## 'Select Locked Cells' and 'Select Unlocked Cells'
my %protection_flags = (
		EDITOBJECTS =>				0x0001,
		EDITSCENARIOS =>			0x0002,
		FORMATCELLS =>				0x0004,
		FORMATCOLUMNS =>			0x0008,

		FORMATROWS =>				0x0010,
		INSERTCOLUMNS =>			0x0020,
		INSERTROWS =>				0x0040,
		INSERTHYPERLINKS =>			0x0080,

		DELETECOLUMNS =>			0x0100,
		DELETEROWS =>				0x0200,
		SELECTLOCKEDCELLS =>		0x0400,
		SORT =>						0x0800,
		
		USEAUTOFILTERS =>			0x1000,
		USEPIVOTTABLEREPORTS =>		0x2000,
		SELECTUNLOCKEDCELLS =>		0x4000
		);

=head1 METHODS

=head2 sheet_protection()

The sheet_protection method sets or returns the current sheetprotection settings.

	print "0x%04x\n", $worksheet->sheet_protection;	## Default protection is 0x4400
	
	## Allow column formatting but disallow selection of locked cells
	$worksheet->sheet_protection(0x4008);

	print "0x%04x\n", $worksheet->sheet_protection;	## Protection is now 0x4008

Protection settings can also be specified as a hash.  If the value is true, the
specified protection is enabled, otherwise it's disabled.

	## Allow column formatting but disallow selection of locked cells
	$worksheet->sheet_protection(
				-select_locked_cells => 0,
				-format_columns => 1 );

	print "0x%04x\n", $worksheet->sheet_protection;	## Protection is now 0x4008

	$worksheet->sheet_protection( -sort => 1 );

	print "0x%04x\n", $worksheet->sheet_protection;	## Protection is now 0x4808

=cut

sub sheet_protection {
	my $self = shift;
	my $protection = defined($self->{_sheet_protection})
						? $self->{_sheet_protection} : $default_protection;

	return $protection unless @_;

	if(scalar (@_) == 1) {
		$protection = shift;
	} else {
		my %settings = @_;
		while (my ($flag, $value) = each %settings) {
			my $key = $flag;
			$key =~ s/[^a-z]//gi;	# Normalize
			$key =~ tr/a-z/A-Z/;

			my $mask = $protection_flags{$key} or die "Unkown protection setting '$flag'";
			if($value) {
				$protection |= $mask;
			} else {
				$protection &= ~$mask;
			}
		}
	}

	$protection &= 0xffff;

	$self->{_sheet_protection} = $protection;
}

sub _store_sheet_protection {
    my $self        = shift;

    # Exit unless sheet protection has been specified
    return if $self->sheet_protection == $default_protection;

	my $record      = 0x0867;               # Record identifier
	my $data		= '';

	$data			= pack("v", $record);	# Repeated record identifier
	$data			.= pack "x10";			# Not used (OpenOffice spec incorrectly claims 9 bytes)
	$data			.= pack "C7", 0x02, 0x00, 0x01, 0xff, 0xff, 0xff, 0xff;	# Unkown data (OpenOffice spec incorrect)
	$data			.= pack "v", $self->{_sheet_protection};
	$data			.= pack "x2";			# Not used

    my $header      = pack("vv", $record, length($data));

    $self->_append($header, $data);
}

=head1 CAVEATS

This module depends on the internal workings of  L<Spreadsheet::WriteExcel> and has
only been tested with version 2.13.  It may or may not work with previous version.

It would be better if the functionality of this module were directly incorporated
into Spreadsheet::WriteExcel::Worksheet, when that happens this module will become
obsolete.

=head1 SEE ALSO

L<Spreadsheet::WriteExcel#protect($password)> and L<Spreadsheet::WriteExcel#set_locked()>

The BIFF record format is based on documentation in L<http://sc.openoffice.org/excelfileformat.pdf>.
However, that documentation (as of 5/29/2005) contains some errors.

=head1 AUTHOR

Stepan Riha, E<lt>sriha@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Stepan Riha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

__END__
