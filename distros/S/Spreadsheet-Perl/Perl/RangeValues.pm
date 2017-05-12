
package Spreadsheet::Perl ;

use 5.006 ;

use Carp ;
use strict ;
use warnings ;

require Exporter ;

our @ISA = qw(Exporter) ;

our %EXPORT_TAGS = 
	(
	'all' => [ qw(RangeValues) ]
	) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT ;
push @EXPORT, qw( RangeValues RangeValuesSub ) ;

our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

sub RangeValues
{
return bless [@_], "Spreadsheet::Perl::RangeValues" ;
}

sub RangeValuesSub
{
return bless [@_], "Spreadsheet::Perl::RangeValuesSub" ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::RangeValues - Helper functions to fill cell ranges

=head1 SYNOPSIS

  $ss{'A1:A5'} = RangeValues(reverse 1 .. 10) ;
  $ss{'A1:A5'} = RangeValuesSub(\&Filler, [11, 22, 33]) ;
  
  @ss{'A1', 'B1:C2', 'A8'} = ('A', Spreadsheet::Perl::RangeValues(reverse 1 .. 10), -1) ;
  
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
