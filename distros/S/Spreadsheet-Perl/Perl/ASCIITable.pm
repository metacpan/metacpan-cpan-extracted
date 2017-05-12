package Spreadsheet::Perl ;
use 5.006 ;

use Carp ;
use strict ;
use warnings ;

require Exporter ;

our @ISA = qw(Exporter) ;

our %EXPORT_TAGS = 
	(
	'all' => [ qw() ]
	) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT ;
push @EXPORT, qw( ) ;

our $VERSION = '0.02' ;

#-------------------------------------------------------------------------------

use Text::ASCIITable 0.12 ;

use Data::TreeDumper ;
$Data::TreeDumper::Useascii = 0 ;

#-------------------------------------------------------------------------------

my @default_table_decoration =
	(
	  ['.','.','-','-']   # .-------------.
	, ['|','|','|']       # | info | info |
	, ['|','|','=','=']   # |=============|
	, ['|','|','|']       # | info | info |
	, ["'","'",'-','-']   # '-------------'
	, ['|','|','-','+']   # |------+------| rowseperator
	) ;
	
sub GenerateASCIITable
{
# The following code was contributed to Spreadsheet::Perl by Håkon Nessjøen <lunatic@cpan.org>

my $ss            = shift ;
my $ranges        = shift ; 
my $display_setup = shift ; 

my $ASCIITable_setup = shift || {} ;

my @table_decoration = @_ ;

@table_decoration = @default_table_decoration unless @table_decoration ;

#-------------------------------------------------------------------------------

my $dump = '' ;

if($display_setup)
	{
	my $NoData = sub
			{
			my $s = shift ;
			
			if('Spreadsheet::Perl' eq ref $s)
				{
				return('HASH', undef, sort grep {! /CELLS/} keys %$s) ;
				}
				
			return(Data::TreeDumper::DefaultNodesToDisplay($s)) ;
			} ;
			
	$dump = DumpTree($ss, 'Setup:', FILTER => $NoData, DISPLAY_ADDRESS => 0) ;
	}

#-------------------------------------------------------------------------------

my ($last_letter, $rows) = $ss->GetLastIndexes() ;

$ranges ||= ["A1:$last_letter$rows"] ;

for my $range (@$ranges)
	{
	my ($address, $is_cell, $start_cell, $end_cell) = $ss->CanonizeAddress($range) ;
	
	my ($start_cell_x, $start_cell_y) = ConvertAdressToNumeric($start_cell) ;
	my ($end_cell_x, $end_cell_y) = ConvertAdressToNumeric($end_cell) ;
	
	my $table = new Text::ASCIITable({ drawRowLine => 1 , %$ASCIITable_setup}) ;
	
	# Column names
	$table->setCols([ map{$ss->Get("$_,0")} (0, $start_cell_x .. $end_cell_x)]) ;
	
	if(exists $ss->{DEBUG}{INLINE_INFORMATION})
		{
		if($ss->{DEBUG}{PRINT_DEPENDENT_LIST})
			{
#			my $dh = $ss->{DEBUG}{ERROR_HANDLE} ;
#			print $dh "PRINT_DEPENDENT_LIST set, calling Recalculate before dumping spreadsheet in table form.\n" ;

			$ss->Recalculate() ;
			}
		}

	for my $row ($start_cell_y .. $end_cell_y) 
		{
		my $cell_values ;
		
		if(exists $ss->{DEBUG}{INLINE_INFORMATION})
			{
			# go through all the cells, heavy and slow process but gives nice debugging info
			
			for my $current_cell ($ss->GetAddressList("$start_cell_x,$row:$end_cell_x,$row"))
				{
				my $cell_value = $ss->Get($current_cell) || '' ;
				my $cell_info = $ss->GetCellInfo($current_cell) ;
				
				push @$cell_values, "$cell_info$cell_value" ;
				}
			}
		else
			{
			# get all the values in one shot
			$cell_values = $ss->Get("$start_cell_x,$row:$end_cell_x,$row") ;
			}
			
		unshift @$cell_values, $ss->Get("\@$row") ;
		
		$table->addRow($cell_values) ;
		}
		
	#------------------------------------------------------------------------
	# page width handling
	use Term::Size::Any ;
	
	my $table_width = $table->getTableWidth() ;
	
	my ($screen_width) = Term::Size::chars *STDOUT{IO} ;
	$screen_width = 78 if $screen_width eq '' ;
	
	my $page_width = $screen_width ;
		
	$page_width = $ASCIITable_setup->{pageWidth} if exists $ASCIITable_setup->{pageWidth} ;

	if($page_width < $table_width)
		{
		my @cuts ;
		
		my $row_header_width = $table->getColWidth($ss->Get("0,0")) + 2 ;
		my $running_width    = $row_header_width ;
		
		for my $column ($start_cell_x .. $end_cell_x)
			{
			my $column_width = $table->getColWidth($ss->Get("$column,0")) ;
			
			if($running_width  + $column_width + 1 >= $page_width)
				{
				push @cuts, ($running_width - $row_header_width) ;
				
				$running_width = $row_header_width + $column_width + 1 ;
				}
			else
				{
				$running_width += $column_width + 1 ;
				}
			}
			
		push @cuts, $table_width ;
			
		my $table_dump = $table->draw(@table_decoration) ;
		
		my @pages ;
		
		while($table_dump =~ /([^\n]+)\n/g)
			{
			my $offset = $row_header_width ;
			my $page = 0 ;
			my $row_header = substr($1, 0, $row_header_width) ;
			
			for my $cut (@cuts)
				{
				$pages[$page] .= $row_header . substr($1, $offset, $cut) . "\n" ;
						 
				$offset += $cut ;
				$page++ ;
				}
			}
			
		unless(exists $ASCIITable_setup->{noPageCount})
			{
			for my $page (0 .. $#pages)
				{
				$pages[$page] .=  "'" . $ss->GetName() . "' " . ($page + 1) . '/' . scalar(@pages) . ".\n" ;
				}
			}
			
		$dump .= join "\n\n", @pages ;
		$dump .= "\n" ;
		}
	else
		{
	#------------------------------------------------------------------------
		$dump .= $table->draw(@table_decoration) . "\n" ;
		}
	}
	
return( $dump ) ;
}

*DumpTable = \&GenerateASCIITable ;

#-------------------------------------------------------------------------------

1 ;

__END__

=head1 NAME

Spreadsheet::Perl::ASCIITable - ASCIITable output for Spreadsheet::Perl

=head1 SYNOPSIS

  print $ss->GenerateASCIITable() ;
  
  # or

  print $ss->DumpTable() ;

=head1 DESCRIPTION

Part of Spreadsheet::Perl.

=head1 AUTHOR

Håkon Nessjøen, <lunatic@cpan.org>

  Copyright (c) 2004 Håkon Nessjøen. All rights reserved.
  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.
  
=cut
