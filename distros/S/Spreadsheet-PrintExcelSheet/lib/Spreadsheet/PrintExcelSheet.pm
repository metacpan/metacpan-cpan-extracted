package Spreadsheet::PrintExcelSheet;

use warnings;
use strict;
use Win32::OLE;

our $VERSION = '0.02';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &PrintIt );
}

sub PrintIt($@) {

	my ($dateiXls, @sheetNr) = @_;

	my $sheetNr = "@sheetNr";

	use Win32::OLE        qw(in with);
	use Win32::OLE::Const 'Microsoft Excel';

	$Win32::OLE::Warn = 3;

	my $excel = Win32::OLE->GetActiveObject('Excel.Application') ||
	            Win32::OLE->new('Excel.Application', 'Quit');

	my $book  = $excel->Workbooks->Open("$dateiXls");
	my $sheet = $book->Worksheets;

	if ($sheetNr eq 'all') {
		for my $worksheet (in ($sheet)) {
			$worksheet->PrintOut;
		} # for
	} # if
	else {
		for my $i (@sheetNr) {
			$book->Worksheets($i)->PrintOut;
		} # for
	} # else

	$excel->Quit();

} # PrintIt


1;
__END__

=pod

=head1 NAME

PrintExcelSheet - a module for print Excelsheets

=head1 SYNOPSIS

	use warnings;
	use strict;
	use PrintExcelsheet qw( PrintIt );

	PrintIt("C:\\Test.xls", 'all'); # print all sheets
	PrintIt("C:\\Test.xls", 2..5);  # print sheet 2 to 5
	PrintIt("C:\\Test.xls", 6);     # print sheet 6

=head1 ABSTRACT

Test

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut
