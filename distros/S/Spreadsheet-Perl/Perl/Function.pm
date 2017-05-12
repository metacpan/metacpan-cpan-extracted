
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
push @EXPORT, qw( StoreFunction FetchFunction StoreOnFetch DeleteFunction) ;

our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

sub StoreFunction
{
confess "First argument to 'StoreFunction' should be a description" unless '' eq ref $_[0] ;
return bless [@_], "Spreadsheet::Perl::StoreFunction" ;
}

#-------------------------------------------------------------------------------

sub FetchFunction
{
confess "First argument to 'FetchFunction' should be a description" unless '' eq ref $_[0] ;
return bless [@_], "Spreadsheet::Perl::FetchFunction" ;
}

#-------------------------------------------------------------------------------

sub StoreOnFetch
{
return bless [@_], "Spreadsheet::Perl::StoreOnFetch" ;
}

#-------------------------------------------------------------------------------

sub DeleteFunction
{
return bless [@_], "Spreadsheet::Perl::DeleteFunction" ;
}

#-------------------------------------------------------------------------------
1 ;

__END__
=head1 NAME

Spreadsheet::Perl::Function - Function support for Spreadsheet::Perl

=head1 SYNOPSIS

  sub SumRowsAbove
  {
  my $ss = shift ;
  my $address  = shift ;
  my @arguments = @_ ;
  
  my ($x, $y) = Spreadsheet::Perl::ConvertAdressToNumeric($address) ;
  
  my $sum = 0 ;
  
  for my $current_y (1 .. ($y - 1))
  	{
  	my $cell_value = $ss->Get("$x,$current_y") ;
  	
  	$sum += $cell_value if (is_numeric($cell_value)) ;
  	}
  	
  return($sum) ;
  }

  $ss{A1} = FetchFunction(\&SumRowsAbove, $arg1, $arg2, ...)
  
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

