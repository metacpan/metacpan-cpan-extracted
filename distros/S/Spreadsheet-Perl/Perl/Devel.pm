
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

use Data::TreeDumper ;
$Data::TreeDumper::Useascii = 0 ;

#-------------------------------------------------------------------------------

sub DumpDependentStack
{
my ($ss, $title) = @_ ;

$title ||= "no title at @{[caller]}" ;

my $separator = '-' x 60 ;

my $dump = $separator ;
$dump .= "\n$title\n";
$dump .= "$ss " ;

if(defined $ss->{NAME})
	{
	$dump .= "'$ss->{NAME}'" ;
	}

$dump .= "Dependent stack:\n" ;
$dump .= "$separator\n" ;

for my $dependent (@{$ss->{DEPENDENT_STACK}})
	{
	my ($spreadsheet, $address, $name) = @$dependent ;
	my $formula = '' ;
	
	if(exists $spreadsheet->{CELLS}{$address}{GENERATED_FORMULA})
		{
		$formula = "$spreadsheet->{CELLS}{$address}{GENERATED_FORMULA}" ;
		
		if(exists $ss->{DEBUG}{DEFINED_AT})
			{
			my ($package, $file, $line) = @{$spreadsheet->{CELLS}{$address}{DEFINED_AT}} ;
			$formula .= "[$package] $file:$line" ;
			}
		}
		
	$dump .= "$name!$address: $formula\n" ;
	}

$dump .= "$separator\n\n" ;

return($dump) ;
}

#-------------------------------------------------------------------------------

sub Dump
{
my $ss = shift ;
my $address_list  = shift ; # array ref
my $display_setup = shift ;
my $dtd_setup     = shift || {} ;

#~ print DumpTree($ss, $ss->{NAME}) ;  ;

use Data::Dumper ;
$Data::Dumper::Indent = 1 ;
#~ return(Dumper($ss)) ;

my $use_data_treedumper = 0 ;
my $use_devel_size = 0 ;

eval <<'EOE' ;
use Devel::Size qw(size total_size) ;
$Devel::Size::warn = 0 ;
$use_devel_size = 1 ;
EOE

# Saturday 08 September 2007
# Devel::Size seg faults or generates a *** glibc detected *** perl: double free or corruption (out): 0x0000000000605190 ***
# see RT #29238

#~ $use_devel_size = 0 ;

my $dump ;

$dump .= '-' x 60 . "\n" ;
$dump .= "$ss " ;

if(exists $ss->{NAME} && defined $ss->{NAME})
	{
	$dump .= "'$ss->{NAME}'" ;
	}
	
if($use_devel_size)
	{
	$dump .= " [" . total_size($ss) . " bytes]\n" ;
	}
	
$dump .= "\n" ;

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
	
	$dump .= DumpTree($ss, 'Setup:', FILTER => $NoData, DISPLAY_ADDRESS => 0, %$dtd_setup) ;
	}
	
$dump .= "\n" ;

my %cell_filter ;

if(defined $address_list)
	{
	my %cells_to_display ;
	@cells_to_display{$ss->GetAddressList(@$address_list)} = undef ;
	
	my $CellPruner = sub
				{
				my $s = shift ;
				if('HASH' eq ref $s)
					{
					return('HASH', $s, , SortCells(grep {exists $cells_to_display{$_};} keys %$s)); 
					}
					
				die "this filter is to be used on hashes!." ;
				} ;
				
	%cell_filter= (LEVEL_FILTERS => {0 => $CellPruner}) ;
	}
else
	{
	my $CellSorter= sub
				{
				my $s = shift ;
				if('HASH' eq ref $s)
					{
					return('HASH', $s, SortCells(keys %$s)) ;
					}
					
				die "this filter is to be used on hashes!." ;
				} ;
				
	%cell_filter= (LEVEL_FILTERS => {0 => $CellSorter}) ;
	}
	
my $NoDependentData = sub
			{
			my $s = shift ;
			
			if('HASH' eq ref $s)
				{
				my $is_dependent_hash = grep {/^Spreadsheet::Perl=HASH\(0x[0-9a-z]+\), [A-Z]/} keys %$s ;
				
				if($is_dependent_hash)
					{
					my @dependents ;
					my @dependents_formulas ;
					
					for my $dependent (keys %$s)
						{
						my ($spreadsheet, $cell, $name) = @{$s->{$dependent}{DEPENDENT_DATA}} ;
						push @dependents, "$name!$cell" ;
						
						if($ss->{DEBUG}{DEPENDENT})
							{
							push @dependents_formulas, "$spreadsheet->{CELLS}{$cell}{GENERATED_FORMULA} [$s->{$dependent}{COUNT}]" ;
							#~ push @dependents_formulas, "$s->{$dependent}{FORMULA} [$s->{$dependent}{COUNT}]" ;
							}
						else
							{
							push @dependents_formulas, 1 ;
							}
						}
						
					return ('ARRAY', \@dependents_formulas, map{[$_, $dependents[$_]]} 0 .. $#dependents ) ;
					}
				else
					{
					return(Data::TreeDumper::DefaultNodesToDisplay($s)) ;
					}
				}
				
			return(Data::TreeDumper::DefaultNodesToDisplay($s)) ;
			} ;
			
$dump .= DumpTree
		(
		  $ss->{CELLS}
		, "Cells (" . scalar(keys %{$ss->{CELLS}}) . "):"
		, DISPLAY_ADDRESS        => 0
		, FILTER                 => $NoDependentData
		, %cell_filter
		, %$dtd_setup
		) ;
		
$dump .= "\n$ss " ;

if(defined $ss->{NAME})
	{
	$dump .= "'$ss->{NAME}'" ;
	}
	
$dump .= " dump end\n" . '-' x 60 . "\n" ;

return($dump) ;
}

#-------------------------------------------------------------------------------

sub GetCellsToUpdateDump
{
my $ss = shift ;
return( "Cells to update: " . (join " - ", $ss->GetCellsToUpdate()) . "\n") ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::Devel - Development support for Spreadsheet::Perl

=head1 SYNOPSIS

  print $ss->Dump() ;
  print $ss->DumpDependentStack() ;
  print $ss->GetCellsToUpdateDump() ;
  
=head1 DESCRIPTION

Part of Spreadsheet::Perl.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

  Copyright (c) 2004 Nadim Ibn Hamouda el Khemir. All rights
  reserved.  This program is free software; you can redis-
  tribute it and/or modify it under the same terms as Perl
  itself.
  
If you find any value in this module, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=cut
