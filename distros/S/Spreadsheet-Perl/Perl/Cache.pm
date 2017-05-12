
package Spreadsheet::Perl ;

use 5.006 ;

use Carp ;
use strict ;
use warnings ;

require Exporter ;
#~ use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;

our %EXPORT_TAGS = 
	(
	'all' => [ qw() ]
	) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT ;
push @EXPORT, qw( Cache NoCache ) ;

our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

sub Cache
{
my $self = shift ;

if(defined $self && __PACKAGE__ eq ref $self)
	{
	$self->{CACHE} = 1 ;
	}
else	
	{
	my $true = 1 ;
	return bless \$true, "Spreadsheet::Perl::Cache" ;
	}
}

sub NoCache
{
my $self = shift ;

if(defined $self && __PACKAGE__ eq ref $self)
	{
	$self->{CACHE} = 0 ;
	}
else	
	{
	my $false= 0 ;
	return bless \$false, "Spreadsheet::Perl::Cache" ;
	}
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::Cache - Cell caching support for Spreadsheet::Perl

=head1 SYNOPSIS

  $ss{A5} = Cache() ;
  $ss{A5} = NoCache() ;
  
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
