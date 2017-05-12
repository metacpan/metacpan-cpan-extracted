package Spreadsheet::Excel2Text;

use warnings;
use strict;

our $VERSION = '0.04';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &XlsSaveToText );
}

sub XlsSaveToText($$) {

	my $xlsFile  = shift;
	my $txtFile  = shift;
	my $excelTab = "";

	use Win32::OLE        qw(in with);
	use Win32::OLE::Const 'Microsoft Excel';

	$Win32::OLE::Warn = 3;

	my $excel = Win32::OLE->GetActiveObject('Excel.Application') || Win32::OLE->new('Excel.Application', 'Quit');

	my $book  = $excel->Workbooks->Open("$xlsFile");
	my $sheet = $book->Worksheets(1);

	$excel->ActiveCell->SpecialCells(xlLastCell)->Select;
	my $lastLine = $excel->ActiveCell->Row;
	my $lastRow  = $excel->ActiveCell->Column;

	my $array = $sheet->Range($sheet->Cells(1,1),$sheet->Cells($lastLine,$lastRow))->{'Value'};

	$book->Close;

	open(my $fhText, ">$txtFile") or die $!;

	my $line  = "";
	my $field = "";
	foreach my $refArray (@$array) {
		$line = "";
		foreach my $excelTab (@$refArray) {
			$field = $excelTab;
			no warnings;
			$line .= $field."\t";
			use warnings;
		} # foreach
		$line =~ s%\r?\n?%%g;
		print $fhText $line, "\n";
	} # foreach

	$excel->Quit();

	close($fhText) or die $!;

	$txtFile;

} # XlsSaveToText

1;
__END__

=pod

=head1 NAME

Excel2Text - a module for save Excelfile as Textfile

=head1 SYNOPSIS

  use warnings;
  use strict;
  use Spreadsheet::Excel2Text qw( XlsSaveToText );

  XlsSaveToText("C:\\Excel.xls", "C:\\Excel.txt");

=head1 ABSTRACT

Test

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut
