
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
push @EXPORT, qw( PerlFormula PF ) ;

our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

sub PerlFormula
{
my $self = shift ;

if(defined $self && __PACKAGE__ eq ref $self)
	{
	my %formulas= @_ ;
	
	while(my ($address, $formula) = each %formulas)
		{
		$self->Set
			(
			  $address
			, bless [\&GeneratePerlFormulaSub, $formula], "Spreadsheet::Perl::PerlFormula"
			) ;
		}
	}
else	
	{
	unshift @_, $self ;
	return bless [\&GeneratePerlFormulaSub, @_], "Spreadsheet::Perl::PerlFormula" ;
	}
}

*PF = \&PerlFormula ;

#-------------------------------------------------------------------------------

sub GeneratePerlFormulaSub
{
my ($ss, $current_cell_address, $anchor, $formula) = @_ ;

if($formula =~ /[A-Z]+\]?\[?[0-9]+/)
	{
	my $dh = $ss->{DEBUG}{ERROR_HANDLE} ;
	print $dh "Formula definition (anchor'$anchor' @ cell '$current_cell_address'): $formula\n" if $ss->{DEBUG}{PRINT_FORMULA} ;
	
	my ($column, $row) = $anchor =~ /^([A-Z]+)([0-9]+)/ ;
	my ($column_offset, $row_offset) = $ss->GetCellsOffset("$column$row", $current_cell_address) ;
	
	if($column_offset || $row_offset)
		{
		$formula =~ s/(\[?[A-Z]+\]?\[?[0-9]+\]?(:\[?[A-Z]+\]?\[?[0-9]+\]?)?)/$ss->OffsetAddress($1, $column_offset, $row_offset)/eg ;
		}
	else
		{
		# remove fixed cell address that is normally handled
		# by OffsetAddress
		$formula =~ s/\[?([A-Z]+)\]?\[?([0-9]+)\]?/$1$2/g ;
		}

	print $dh "=> $formula\n" if $ss->{DEBUG}{PRINT_FORMULA} ;
	}

return
	(
	sub 
		{ 
		my $ss = shift ; 
		tie my (%ss), $ss ; 
		
		my $cell = shift ;
		my @formula_arguments = @_ ;

		my $dh = $ss->{DEBUG}{ERROR_HANDLE} ;
		my $ss_name = $ss->GetName() ;
		my @generated_warnings ;
		my $warning_message ;

		local $SIG{__WARN__} = 
			sub
			{
			my $generated_warning = $_[0] ;

			$warning_message .= "Warning at cell '$ss_name!$cell' formula: $formula" ;
			$warning_message .= " defined at '@{$ss->{CELLS}{$cell}{DEFINED_AT}}'" if(exists $ss->{CELLS}{$cell}{DEFINED_AT}) ;
			$warning_message .= ":\n\t$generated_warning" ;

			print $dh $warning_message ;

			$generated_warning =~ s/ at formula_eval.*// ;
			chomp $generated_warning ;

			push @generated_warnings, $generated_warning ;
			} ;
			
		my $result = eval "#line " . __LINE__ . " formula_eval\n$formula" ;
			
		if($@)
			{
			my ($exception_type, $exception_data) = (ref $@, $@) ;

			if($exception_type eq 'Cyclic dependency')
				{
				$exception_data->{warnings} = \@generated_warnings if @generated_warnings ;
				}
			elsif($exception_type eq 'Invalid dependency cell')
				{
				$exception_data->{spreadsheet} = $exception_data->{spreadsheet}->GetName() ;
				$exception_data->{warnings} = \@generated_warnings if @generated_warnings ;

				$exception_type .= ' ' . $exception_data->{spreadsheet} . '!' . $exception_data->{cell} ;
				}
			else
				{
				chomp $exception_data ;
				$exception_data =~ s/ at formula_eval line \d+,//s ;

				$exception_type = $exception_data ;

				$exception_data = {message => $exception_data} ;
				}

			my $dh = $ss->{DEBUG}{ERROR_HANDLE} ;
			
			print $dh "At cell '$ss_name!$cell' formula: $formula" ;
			print $dh " defined at '@{$ss->{CELLS}{$cell}{DEFINED_AT}}'" if(exists $ss->{CELLS}{$cell}{DEFINED_AT}) ;
			print $dh ":\n" ;
			print $dh "\t$exception_type\n" ;

			return($ss->{MESSAGE}{ERROR}, 0, $exception_type,  $exception_data) ;
			}
		else
			{
			if(@generated_warnings)
				{
				return($result, 1, 'OK', {warnings => \@generated_warnings}) ;
				}
			else
				{
				return($result, 1, 'OK') ;
				}
			}
		}
	, $formula
	) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::PerlFormula - Perl Formula support for Spreadsheet::Perl

=head1 SYNOPSIS

  $ss{A1} = PerlFormula('$ss{B1} + $ss{TOTAL}', $arg1, $arg2, ...) ;
  my $formula = $ss->GetFormulaText('A1') ;
  
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
