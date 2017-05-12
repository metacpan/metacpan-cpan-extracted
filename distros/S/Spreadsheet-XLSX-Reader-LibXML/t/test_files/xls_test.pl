#!/usr/bin/env perl

use strict;
use Spreadsheet::ParseExcel;
use Data::Dumper;

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse('TestBook.xls');

if ( !defined $workbook ) {
	die $parser->error(), ".\n";
}

my $worksheet = $workbook->worksheet( 'Sheet1' );
#~ print "$worksheet\n";
my $cell = $worksheet->get_cell( 5, 0 );
#~ print "$cell\n";
print	$cell->value . "\n";
print	Dumper( $worksheet->get_merged_areas() );
$cell = $worksheet->get_cell( 5, 1 );
#~ print "$cell\n";
print "Other merged area value: " . $cell->value . "\n";
#~ print	Dumper( $cell->get_rich_text );

$workbook = $parser->parse('Rich.xls');

if ( !defined $workbook ) {
	die $parser->error(), ".\n";
}

$worksheet = $workbook->worksheet( 'Sheet1' );
$cell = $worksheet->get_cell( 1, 0 );
print "Rich text test value: " . $cell->value . "\n";
print	Dumper( $cell->get_rich_text );

$workbook = $parser->parse('perc.xls');

if ( !defined $workbook ) {
	die $parser->error(), ".\n";
}

$worksheet = $workbook->worksheet( 'Blad1' );
$cell = $worksheet->get_cell( 0, 2 );
print "Cell type: " . $cell->type . "\n";
print "Cell value: " . $cell->value . "\n";

$workbook = $parser->parse('attr.xls');

if ( !defined $workbook ) {
	die $parser->error(), ".\n";
}

$worksheet = $workbook->worksheet( 'Format' );
$cell = $worksheet->get_cell( 7, 0 );
print "Cell value: " . $cell->value . "\n";