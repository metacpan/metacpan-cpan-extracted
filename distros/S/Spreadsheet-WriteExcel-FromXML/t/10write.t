use strict;
use warnings;
$|++;

use Test;
use Spreadsheet::WriteExcel::FromXML;
use IO::Handle;
use IO::Scalar;
use Carp;

plan( tests => 2 );

my $inFile = "t/practitioner2.xml";
my $outFile = "test2.xls";
Spreadsheet::WriteExcel::FromXML->XMLToXLS( $inFile, $outFile );
ok( -f $outFile );
ok( -s $outFile );
unlink $outFile if -f $outFile;

