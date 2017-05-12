
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
push @EXPORT, qw( DefineSpreadsheetFunction ) ;

our $VERSION = '0.02' ;

#-------------------------------------------------------------------------------

sub SetAutocalc
{
my $self = shift ;
my $autocalc = shift ;

if(defined $autocalc)
	{
	$self->{AUTOCALC} = $autocalc ;
	}
else
	{
	$self->{AUTOCALC} = 1 ;
	}
}

#-------------------------------------------------------------------------------

sub GetAutocalc
{
my $self = shift ;
return($self->{AUTOCALC}) ;
}

#-------------------------------------------------------------------------------

sub Recalculate
{
my $self = shift ;

for my $cell_name (SortCells keys %{$self->{CELLS}})
	{
	if(exists $self->{CELLS}{$cell_name}{FETCH_SUB})
		{
		$self->Get($cell_name) ;
		}
	}
}

#-------------------------------------------------------------------------------

sub AddSpreadsheet
{
my $self = shift ;
my $name = shift ;
my $reference = shift ;

confess "Invalid spreadsheet name '$name'." unless $name =~ /^[A-Z]+$/ ;

return if(defined $self->{NAME} && $self->{NAME} eq $name) ;

if(exists $self->{OTHER_SPREADSHEETS}{$name})
	{
	if($self->{OTHER_SPREADSHEETS}{$name} != $reference)
		{
		my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
		print $dh "AddSpreadsheet: Replacing spreadsheet '$name'\n" ;
		}
	}
	
$self->{OTHER_SPREADSHEETS}{$name} = $reference ;
}

#-------------------------------------------------------------------------------

sub SetName
{
my $self = shift ;
my $name = shift ;

$self->{NAME} = $name ;
}

#-------------------------------------------------------------------------------

sub GetName
{
my $self = shift ;
my $ss = shift ;

return($self->{NAME} || "$self") unless defined $ss ;

my $name ;

if(exists $self->{OTHER_SPREADSHEETS})
	{
	for my $current_name (keys %{$self->{OTHER_SPREADSHEETS}})
		{
		if($self->{OTHER_SPREADSHEETS}{$current_name} == $ss)
			{
			$name = $current_name ;
			last ;
			}
		}
	}
	
return($name) ;
}

#-------------------------------------------------------------------------------

sub GetCellList
{
# doesn't return headers cells

my $self = shift ;

return
	(
	SortCells
		(
		grep
			{
			! /^@/ && ! /^[A-Z]+0$/
			} keys %{$self->{CELLS}}
		)
	) ;
}

sub GetCellHeaderList
{
my ($self) = @_ ;

return
	(
	grep
		{
		/^@/ || /^[A-Z]+0$/
		} keys %{$self->{CELLS}}
	) ;
}

#-------------------------------------------------------------------------------

sub GetLastIndexes
{
my $self = shift ;

my ($last_letter, $last_number) = ('A', 1) ;

for my $address(keys %{$self->{CELLS}})
	{
	my ($letter, $number) = $address =~ /([A-Z@]+)(.+)/ ;
	
	($last_letter) = sort{length($b) <=> length($a) || $b cmp $a} ($last_letter, $letter) ;
	$last_number   = $last_number > $number ? $last_number : $number ;
	}
	
return($last_letter, $last_number) ;
}


#-------------------------------------------------------------------------------

sub GetCellsToUpdate
{
# return the address of all the cells needing an update

my $ss = shift ;

return
	(
	grep 
		{
		   ( exists $ss->{CELLS}{$_}{NEED_UPDATE} && $ss->{CELLS}{$_}{NEED_UPDATE})
		||
			(
			   (exists $ss->{CELLS}{$_}{PERL_FORMULA} || exists $ss->{CELLS}{$_}{FETCH_SUB} || exists $ss->{CELLS}{$_}{FORMULA})
			&& (! exists $ss->{CELLS}{$_}{NEED_UPDATE})
			)
		} (SortCells(keys %{$ss->{CELLS}}))
	) ;
}

#-------------------------------------------------------------------------------

sub DefineSpreadsheetFunction
{
my ($name, $function_ref, $function_body, $module_name) = @_ ;

confess "Expecting a name!" unless '' eq ref $name && defined $name && $name ne '' ;
confess "Expecting a function reference or a function body!" unless defined $function_ref || defined $function_body ;
confess "Expecting a function reference _or_ a function body!" if defined $function_ref && defined $function_body ;

no strict ;

#~ *$name = sub {$function_ref->(@_) ;} ; # this has perl generate a warning but with the wrong context

if(eval "*$name\{CODE}")
	{
	warn "Subroutine Spreadsheet::Perl::$name redefined at @{[join ':', caller()]}\n" ;
	#~ undef &${name} ; #!! hmm, undef the sub in its original package and local package as it is an alias
	}
	
if(defined $function_body && ! defined $function_ref)
	{
	$function_body =~ s/\n+$// ;
	$function_ref = eval $function_body ;
	}
	
if($@)
	{
	confess $@  ;
	}
else
	{
	local $SIG{'__WARN__'} = sub {print STDERR $_[0] unless $_[0] =~ 'redefined at'} ;
	
	*$name = $function_ref ;
	
	$Spreadsheet::Perl::defined_functions{$name} = {
							  FUNCTION_REF => $function_ref
							, FUNCTION_BODY => $function_body
							, MODULE_NAME => $module_name
							, DEFINED_AT => join('::', caller())
							} ;
	}
}

#-------------------------------------------------------------------------------

sub GetFormulaText
{
my $self = shift ;
my $address = shift ;

my $is_cell ;
($address, $is_cell) = $self->CanonizeAddress($address) ;

if($is_cell)
	{
	if(exists $self->{CELLS}{$address})
		{
		if(exists $self->{CELLS}{$address}{PERL_FORMULA} || exists $self->{CELLS}{$address}{FORMULA})
			{
			return($self->{CELLS}{$address}{GENERATED_FORMULA}) ;
			}
		else
			{
			return ;
			}
		}
	else
		{
		return ;
		}
	}
else
	{
	confess "GetFormula can only return the formula for one cell not '$address'.\n" ;
	}
}

#-------------------------------------------------------------------------------

sub GetCellInfo
{
my $self = shift ;
my $address = shift ;

my $is_cell ;
($address, $is_cell) = $self->CanonizeAddress($address) ;

if($is_cell)
	{
	if(exists $self->{CELLS}{$address})
		{
		my $cell_info = '' ;
		
		if(exists $self->{CELLS}{$address}{CACHE})
			{
			$cell_info .= "CACHE: '$self->{CELLS}{$address}{CACHE}'\n" ;
			}

		# lock ?
		
		if(exists $self->{CELLS}{$address}{STORE_SUB_INFO})
			{
			$cell_info .= "StoreSub: '$self->{CELLS}{$address}{STORE_SUB_INFO}'\n" ;
			}
			
		if(exists $self->{CELLS}{$address}{FORMULA})
			{
			# definition line?
			
			$cell_info .= "OF: " . $self->{CELLS}{$address}{FORMULA}[1] . " =>\n" if $self->{DEBUG}{PRINT_ORIGINAL_FORMULA} ;
			$cell_info .= "F: " . $self->{CELLS}{$address}{GENERATED_FORMULA}  . "\n" ;
			}
			
		if(exists $self->{CELLS}{$address}{PERL_FORMULA})
			{
			# definition line?
			
			$cell_info .= "OPF: " . $self->{CELLS}{$address}{PERL_FORMULA}[1] . " =>\n" if $self->{DEBUG}{PRINT_ORIGINAL_FORMULA} ;
			$cell_info .= "PF: " . $self->{CELLS}{$address}{GENERATED_FORMULA}  . "\n" ;
			}
			
		if(exists $self->{CELLS}{$address}{FETCH_SUB_INFO})
			{
			$cell_info .= "FetchSub: '$self->{CELLS}{$address}{FETCH_SUB_INFO}'.\n" ;
			}

		if(exists $self->{CELLS}{$address}{DEPENDENT})
			{
			if($self->{DEBUG}{PRINT_DEPENDENT_LIST})
				{
				for(keys %{$self->{CELLS}{$address}{DEPENDENT}})
					{
					$cell_info .= "dependent: $_\n" ;
					}
				}
			}

		if(exists $self->{CELLS}{$address}{EVAL_OK})
			{
			if($self->{DEBUG}{PRINT_FORMULA_EVAL_STATUS})
				{
				if($self->{CELLS}{$address}{EVAL_OK} == 0 )
					{
					$cell_info .= DumpTree($self->{CELLS}{$address}{EVAL_DATA}, 'eval error:', USE_ASCII => 1) ;
					}
				elsif(exists $self->{CELLS}{$address}{EVAL_DATA}{warnings})
					{
					$cell_info .= DumpTree($self->{CELLS}{$address}{EVAL_DATA}{warnings}, 'eval warnings:', USE_ASCII => 1, DISPLAY_ADDRESS => 0) ;
					}
				}
			}
		
		return($cell_info) ;
		}
	else
		{
		return($self->{MESSAGE}{VIRTUAL_CELL} . "\n") ;
		}
	}
else
	{
	confess "GetCellInfo can only return information about one cell not '$address'.\n" ;
	}
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::QuerySet - Functions at the spreadsheet level

=head1 SYNOPSIS

  SetAutocalc
  GetAutocalc
  Recalculate
  
  SetName
  GetName
  AddSpreadsheet
  
  GetCellList
  GetLastIndexes
  GetCellsToUpdate
  
  DefineFunction
  
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
