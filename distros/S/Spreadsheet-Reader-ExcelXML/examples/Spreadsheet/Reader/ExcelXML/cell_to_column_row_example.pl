#!/usr/bin/env perl
package MyPackage;
use lib '../../../../lib';
use Moose;
with 'Spreadsheet::Reader::ExcelXML::CellToColumnRow';

sub set_error{} # Required method of this role
sub error{ print "Missing the column or row\n" } # Required method of this role
sub counting_from_zero{ 0 } # Required method of this role
	
sub my_method{
	my ( $self, $cell ) = @_;
	my ($column, $row ) = $self->parse_column_row( $cell );
	print $self->error if( !defined $column or !defined $row );
	return ($column, $row );
}

package main;

my $parser = MyPackage->new;
print '(' . join( ', ', $parser->my_method( 'B2' ) ) . ")\n";