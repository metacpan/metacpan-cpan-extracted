use strict;
use warnings;
$|++;

use Test;
use Spreadsheet::WriteExcel::FromXML;
use IO::Handle;
use IO::Scalar;
use Carp;

plan( tests => 1 );

my $inFile = "t/practitioner2.xml";
my $outFile = "test2.xls";
my $data = Spreadsheet::WriteExcel::FromXML->BuildSpreadsheet( $inFile );
ok( $data );
