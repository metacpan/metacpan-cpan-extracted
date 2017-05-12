
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
push @EXPORT, qw( Format AddFormat ) ;

our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

sub Format
{
# should be passed the elements needed to setup a hash

if(@_ % 2)
	{
	confess "Format should be passed a list of key/values!" ;
	}

return bless {@_}, "Spreadsheet::Perl::Format" ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::Format - Format support for Spreadsheet::Perl

=head1 SYNOPSIS

$ss{A1} = Format
		(
		  # formats are user defined 
		  # a cell can have multiple formats 
		  POD => [ 1, 2, 3] 
		, HTML => { H1 => \&GetH1Format }
		) ;
  
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
