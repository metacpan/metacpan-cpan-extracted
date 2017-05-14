#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Spreadsheet::ParseExcel::Assist' ) || print "Bail out!\n";
    use_ok( 'Spreadsheet::XLSX::Assist' ) || print "Bail out!\n";
}

diag( "Testing Spreadsheet::ParseExcel::Assist $Spreadsheet::ParseExcel::Assist::VERSION, Perl $], $^X" );
