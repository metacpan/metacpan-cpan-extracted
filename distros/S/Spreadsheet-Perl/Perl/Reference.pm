
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
push @EXPORT, qw( Ref ) ;

our $VERSION = '0.02' ;

#-------------------------------------------------------------------------------

sub Ref
{
my $self = shift ;

if(defined $self && __PACKAGE__ eq ref $self)
	{
	my $information = shift ;

	confess "First argument to 'Ref' should be a description" unless '' eq ref $information ;

	my %references = @_ ;
	
	my %address_to_reference ;
	my $spreadsheet_reference_sub = bless 
						[
						  $information
						 
						, sub # store sub
						   {
						   ${$address_to_reference{$_[1]}} = $_[2] ;
						   }
						  
						, sub # fetch sub 
						   {
						   ${$address_to_reference{$_[1]}}
						   }
						], "Spreadsheet::Perl::Reference" ;
						
	while(my ($address, $reference) = each %references)
		{
		for my $current_address ($self->GetAddressList($address))
			{
			$address_to_reference{$current_address} = $reference ;
			$self->Set($current_address, $spreadsheet_reference_sub) ;
			}
		}
	}
else	
	{
	my $information = $self ;

	confess "First argument to 'Ref' should be a description" unless '' eq ref $information ;

	my $reference = shift ;
	
	confess "Error: 'Ref' takes a  reference as argument" unless(defined $reference) ;
	
	for(ref $reference)
		{
		'SCALAR' eq $_ && do
			{
			return bless 
				[
				  $information
				, sub{$$reference = $_[2] ;} # store sub
				, sub{$$reference} # fetch sub
				], "Spreadsheet::Perl::Reference" ;
			} ;
			
		confess "Error: 'Ref' doesn't know how to handle reference of type '$_'" ;
		}
	}
}

#-------------------------------------------------------------------------------

sub get_reference_description
{
my ($self, $address) = @_ ;

my @information ;

for my $current_address ($self->GetAddressList($address))
	{
	if(exists $self->{CELLS}{$current_address})
		{
		if(exists $self->{CELLS}{$current_address}{REF_SUB_INFO})
			{
			push @information,
				$self->{CELLS}{$current_address}{REF_SUB_INFO} || '' ;
			}
		}
	else
		{
		push @information, '' ;
		}
	}

return @information ;
}

*REF_INFO = \&get_reference_description ;

#-------------------------------------------------------------------------------
1 ;

__END__
=head1 NAME

Spreadsheet::Perl::Reference - Reference access for Spreadsheet::Perl

=head1 SYNOPSIS

  my $variable = 25 ;
  $ss{A1} = Ref(\$struct->{something}) ;
  $ss{A2} = PerlFormula('$ss{A1}') ;
  
  print "$ss{A1} $ss{A2}\n" ;
  
  $ss{A1} = 52 ;
  
  print "\$variable = $variable\n" ;
  
=head1 DESCRIPTION

Part of Spreadsheet::Perl. See "Scalar reference mapping" in main documentation

=head1 AUTHOR

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

  Copyright (c) 2004 Nadim Ibn Hamouda el Khemir. All rights
  reserved.  This program is free software; you can redis-
  tribute it and/or modify it under the same terms as Perl
  itself.
  
If you find any value in this module, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=cut
