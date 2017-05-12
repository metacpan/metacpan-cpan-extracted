
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
push @EXPORT, qw( SortCells ConvertAdressToNumeric) ;

our $VERSION = '0.03' ;

use Spreadsheet::ConvertAA 0.02 ;

#-------------------------------------------------------------------------------

sub IsAddress
{
my $self = shift ;
my $address = shift ;

eval
	{
	$self->CanonizeAddress($address) ; # dies if address is not valid
	} ;

$@ ? return(0) : return(1) ;
}

#-------------------------------------------------------------------------------

sub CanonizeAddress
{
# transform numeric cell index to alphabetic index
# transform symbolic addresses to alphabetic index

my $self = shift ;
my $address = uc(shift) ;

my ($is_cell, $start_cell, $end_cell) ;

my $spreadsheet = '' ;

if($address =~ /^([A-Z_]+!)(.+)/)
	{
	# reference to spreadsheet
	$spreadsheet = $1 ;
	$address = $2 ;
	}

if($address =~ /^(.+):(.+)$/)
	{
	# range
	$start_cell = $self->CanonizeCellAddress($1) ;
	$end_cell   = $self->CanonizeCellAddress($2) ;
	}
else
	{
	# single cell or range name
	my $named_cell_range = $self->CanonizeName($address) ;
	
	if(defined $named_cell_range)
		{
		if($named_cell_range =~ /^([A-Z_]+!)(.+)/)
			{
			if($spreadsheet ne '')
				{	
				confess "address '$address' contains multiple spreadsheet names !" ;
				}

			$spreadsheet = $1 ;
			$named_cell_range = $2 ;
			}

		($start_cell, $end_cell) = $named_cell_range =~ /^(.+):(.+)$/ ;
		
		unless(defined $start_cell)
			{
			$start_cell = $end_cell = $named_cell_range ;
			$is_cell++ ;
			}
		}
	else
		{
		$start_cell = $self->CanonizeCellAddress($address) ;
		$end_cell   = $start_cell ;
		
		$is_cell++ ;
		}
	}

if($is_cell)
	{
	if(wantarray)
		{
		return("$spreadsheet$start_cell", $is_cell, "$start_cell", "$end_cell") ;
		}
	else
		{
		return("$spreadsheet$start_cell") ;
		}
	}
else
	{
	if(wantarray)
		{
		return("$spreadsheet$start_cell:$end_cell", $is_cell, "$start_cell", "$end_cell") ;
		}
	else
		{
		return("$spreadsheet$start_cell:$end_cell") ;
		}
	}
}

#-------------------------------------------------------------------------------

sub CanonizeCellAddress
{
my $self = shift ;
my $address = shift ;

my $spreadsheet = '' ;

if($address =~ /^([A-Z_]+!)(.+)/)
	{
	$spreadsheet = $1 ;
	$address = $2 ;
	}

my $cell_address = $self->CanonizeName($address) ;

if(defined $cell_address)
	{
	return($cell_address) ;
	}
else
	{
	if($address =~ /^[A-Z@]+[0-9\*]+$/ || $address =~ /^\*[0-9\*]+$/ || $address =~ /^[A-Z@]+\*$/ || $address =~ /^\*$/)
		{
		return($spreadsheet . $address) ;
		}
	else
		{
		if($address =~ /^\s*([0-9]+)\s*,\s*([0-9]+)\s*$/)
			{
			return($spreadsheet . ConvertNumericToAddress($1, $2)) ;
			}
		else
			{
			confess "Invalid Address '$spreadsheet$address'." ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub SortCells
{
# returns the addresses, passed as argument, sorted.
return
	(
	sort
		{
		my ($a_spreadsheet_name, $a_letter, $a_number) = $a =~ /^([A-Z]+!)?([A-Z@]+)(.+)$/ ;
		my ($b_spreadsheet_name, $b_letter, $b_number) = $b =~ /^([A-Z]+!)?([A-Z@]+)(.+)$/ ;
		
		$a_spreadsheet_name ||= '' ;
		$b_spreadsheet_name ||= '' ;
		
		   $a_spreadsheet_name cmp $b_spreadsheet_name 
		|| length($a_letter) <=> length($b_letter) 
		|| $a_letter cmp $b_letter || $a_number <=> $b_number ;
		} @_
	) ;
}

#-------------------------------------------------------------------------------

sub SetNames
{
my $self = shift ;
my %name_address = @_ ;

while (my($name, $address) = each %name_address)
	{
	$name = uc($name) ;
	$name =~ s/^\s+// ;
	$name =~ s/\s+$// ;

#	print "setting name '$name' to '$address'\n" ;

	if(! exists $self->{NAMED_ADDRESSES}{$name} && $self->IsAddress($name))
		{
		confess "Can't use '$name' as a name as it is also a valid cell address.\n." ;
		}

	$self->{NAMED_ADDRESSES}{$name} = $self->CanonizeAddress($address) ;
	}
}

#-------------------------------------------------------------------------------

sub CanonizeName
{
my $self = shift ;
my $name = uc(shift) ;

return $self->{NAMED_ADDRESSES}{$name} ;
}

#-------------------------------------------------------------------------------

sub ConvertAdressToNumeric
{
my $address = shift ;

my $spreadsheet = '' ;
if($address =~ /^([A-Z_]+!)(.+)/)
	{
	$spreadsheet  = $1 ;
	$address = $2 ;
	}

if($address =~ /^([A-Z@]+)([0-9]+)$/)
	{
	my $letters = $1 ;
	my $figure = $2 ;
	
	my $converted_letters = FromAA($letters) ;
	
	#~ print "ConvertAdressToNumeric: $address => ($letters => $converted_letters), $figure\n" ;
	
	return($converted_letters, $figure) ;
	}
else
	{
	confess "Invalid Address '$address'." ;
	}
}

#-------------------------------------------------------------------------------

sub ConvertNumericToAddress
{
my ($x, $y) = @_ ;

my $converted_figures = ToAA($x) ;

#~ print "ConvertNumericToAddress: $x,$y => $converted_figures$y\n" ;

return("$converted_figures$y") ;
}

#-------------------------------------------------------------------------------

sub GetAddressList
{
my $self = shift ;
my @addresses_definition = @_;
my @addresses ;

for my $address (@addresses_definition)
	{
	my $spreadsheet = '' ;
	
	my ($address, $is_cell, $start_cell, $end_cell) = $self->CanonizeAddress($address) ;
	
	for($start_cell)
		{
		/^([A-Z@]+)\*$/ && do
			{
			$start_cell = "${1}1" ;
			last;
			} ;
			
		/^\*([0-9]+)$/ && do
			{
			$start_cell = "A${1}" ;
			last;
			} ;
			
		/^\*$/ && do
			{
			$start_cell = 'A1' ;
			last;
			} ;
		}
		
	for($end_cell)
		{
		/([A-Z@]+)\*/ && do
			{
			$end_cell= "${1}1" ;
			last;
			} ;
			
		/\*([0-9]+)/ && do
			{
			$end_cell = "A${1}" ;
			last;
			} ;
			
		/^\*$/ && do
			{
			$end_cell = 'A1' ;
			last;
			} ;
		}
		
	if($is_cell)
		{
		push @addresses, $start_cell ;
		}
	else
		{
		if($address =~ /^([A-Z]+!)(.+)/)
			{
			$spreadsheet = $1 ;
			$address = $2 ;
			}
			
		my ($start_x, $start_y) = ConvertAdressToNumeric($start_cell) ;
		my ($end_x, $end_y) = ConvertAdressToNumeric($end_cell) ;
		
		my @x_list ;
		if($start_x < $end_x)
			{
			@x_list = ($start_x .. $end_x) ;
			}
		else
			{
			@x_list = reverse  ($end_x .. $start_x ) ;
			}
		
		my @y_list ;
		if($start_y < $end_y)
			{
			@y_list = ($start_y .. $end_y) ;
			}
		else
			{
			@y_list = reverse ($end_y .. $start_y ) ;
			}
			
		for my $x (@x_list)
			{
			for my $y (@y_list)
				{
				push @addresses, $spreadsheet . ConvertNumericToAddress($x, $y) ;
				}
			}

		if($self->{DEBUG}{ADDRESS_LIST})
			{
			my $dh = $self->{DEBUG}{ERROR_HANDLE} ;
			print $dh "GetAddressList '$address': " 
				. (join ' - ', @addresses) . "\n"
			}
		}
	}
	
return(@addresses) ;
}

#-------------------------------------------------------------------------------

sub GetSpreadsheetReference
{
my $self = shift ;
my $address = shift ; #! must be canonized

#~ my ($canonized_address, $is_cell, $start_cell, $end_cell, $range) = $self->CanonizeAddress($address) ;

if($address=~ /^([A-Z]+)!(.+)/)
	{
	if(defined $self->{NAME} && $self->{NAME} eq $1)
		{
		return($self, $2) ;
		}
	else
		{
		if(exists $self->{OTHER_SPREADSHEETS}{$1})
			{
			return($self->{OTHER_SPREADSHEETS}{$1}, $2) ;
			}
		else
			{
			return(undef, $address) ;
			}
		}
	}
else
	{
	return($self, $address) ;
	}
}

#-------------------------------------------------------------------------------

sub is_within_range
{
my ($self, $cell_address, $range) = @_ ;

my ($range_canonized, $is_cell, $range_start_cell, $range_end_cell)
	= $self->CanonizeAddress($range) ;

if($cell_address=~ /^[A-Z_]+!(.+)/)
	{
	$cell_address = $1 ;
	}

my ($range_start_column, $range_start_row)
	= $range_start_cell=~ /^([A-Z@]+)([0-9]+)$/ ;

$range_start_column = FromAA($range_start_column) ;

my ($range_end_column, $range_end_row)
	= $range_end_cell=~ /^([A-Z@]+)([0-9]+)$/ ;

$range_end_column = FromAA($range_end_column) ;

my ($full_column, $column, $full_row, $row) 
	= $cell_address=~ /^(\[?([A-Z@]+)\]?)(\[?([0-9]+)\]?)$/ ;

my $column_index = FromAA($column) ;

if
	(
	$column_index < $range_start_column
	|| $column_index > $range_end_column
	|| $row < $range_start_row
	|| $row > $range_end_row
	)
	{
	return 0 ; # not within range
	}
else
	{
	return 1 ; # within range
	}
}

#-------------------------------------------------------------------------------

sub OffsetAddress
{
# this function accept adresses that are fixed ex: [A1]

my ($self, $address, $column_offset, $row_offset, $range) = @_ ;

my $range_print = $range || 'none' ;
#print "OffsetAddress: $address + $column_offset, $row_offset [$range_print] " ; # there is another print closed to the end of this sub you want to uncomment simulteanously

my ($spreadsheet, $is_cell, $start_cell, $end_cell) = ('') ;

if($address =~ /^([A-Z_]+!)(.+)/)
	{
	$spreadsheet = $1 ;
	$address = $2 ;
	}

if($address =~ /(\[?[A-Z@]+\]?\[?[0-9]+\]?):(\[?[A-Z@]+\]?\[?[0-9]+\]?)/)
	{
	($is_cell, $start_cell, $end_cell) = (0, $1, $2) ;
	}
else	
	{
	if($address =~ /(\[?[A-Z@]+\]?\[?[0-9]+\]?)/)
		{
		($is_cell, $start_cell, $end_cell) = (1, $1, $1) ;
		}
	else	
		{
		($address, $is_cell, $start_cell, $end_cell) = $self->CanonizeAddress($address) ;
		
		if($address =~ /^([A-Z_]+!)(.+)/)
			{
			$spreadsheet = $1 ;
			}
		}
	}

my $offset_address ;

if($is_cell)
	{
	if
		(
		! defined $range
		|| $self->is_within_range($start_cell, $range)
		)
		{
		$offset_address = $self->OffsetCellAddress
					(
					$spreadsheet . $start_cell,
					$column_offset,
					$row_offset
					) ;
		}
	else
		{
		$offset_address = "$spreadsheet$start_cell" ;
		}
	}
else
	{
	my $lhs = $start_cell ;
	my $rhs = $end_cell ;

	if
		(
		! defined $range
		|| $self->is_within_range($lhs, $range)
		)
		{
		$lhs = $self->OffsetCellAddress($start_cell, $column_offset, $row_offset) ;
		}

	if
		(
		! defined $range
		|| $self->is_within_range($rhs, $range)
		)
		{
		$rhs = $self->OffsetCellAddress($end_cell, $column_offset, $row_offset) ;
		}

	if(defined $lhs && defined $rhs)
		{
		$offset_address = ("$spreadsheet$lhs:$rhs") ;
		}
	#else
		# return undef
	}

#print " => $offset_address\n" ;
return $offset_address ;
}

#-------------------------------------------------------------------------------

sub OffsetCellAddress
{
my $self = shift ;
my $cell_address = shift ;
my $column_offset = shift ;
my $row_offset = shift ;

my $spreadsheet = '' ;
if($cell_address=~ /^([A-Z_]+!)(.+)/)
	{
	$spreadsheet = $1 ;
	$cell_address = $2 ;
	}

#~ print "OffsetCellAddress : $spreadsheet$cell_address\n" ;
my ($full_column, $column, $full_row, $row) = $cell_address=~ /^(\[?([A-Z@]+)\]?)(\[?([0-9]+)\]?)$/ ;

my $column_index = FromAA($column) ;
$column_index += $column_offset if($full_column !~ /[\[\]]/) ;
	
$row += $row_offset if($full_row !~ /[\[\]]/) ;

if($column_index > 0 && $row > 0)
	{
	return($spreadsheet . ToAA($column_index) . $row) ;
	}
else
	{
	return ;
	}
}

#-------------------------------------------------------------------------------

sub GetCellsOffset
{
my $self = shift ;
my $cell_address1 = $self->CanonizeAddress(shift) ;
my $cell_address2 = $self->CanonizeAddress(shift) ;

my $spreadsheet1 = '' ;
if($cell_address1=~ /^([A-Z_]+!)(.+)/)
	{
	$spreadsheet1  = $1 ;
	$cell_address1 = $2 ;
	}

my $spreadsheet2 = '' ;
if($cell_address2 =~ /^([A-Z_]+!)(.+)/)
	{
	$spreadsheet2  = $1 ;
	$cell_address2 = $2 ;
	}

confess "Can't compute offset of cells on different spreadsheets\n" if $spreadsheet1 ne $spreadsheet2 ;

my ($column1, $row1) = $cell_address1 =~ /^([a-zA-Z@]+)([0-9]+)/ ;
my ($column2, $row2) = $cell_address2 =~ /^([a-zA-Z@]+)([0-9]+)/ ;

#~ print "$cell_address1  => $column1, $row1. $cell_address2  => $column2, $row2.\n" ;

my $column1_index = FromAA($column1) ;
my $column2_index = FromAA($column2) ;

return ($column2_index - $column1_index, $row2 - $row1) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__

=head1 NAME

Spreadsheet::Perl::Address - Cell adress manipulation functions

=head1 SYNOPSIS

  $ss->SetRangeName("TestRange", 'A5:B8') ;
  my ($x, $y) = ConvertAdressToNumeric($address) ;
  ...
  
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

=head1 DEPENDENCIES

B<Spreadsheet::ConvertAA>.

=cut
