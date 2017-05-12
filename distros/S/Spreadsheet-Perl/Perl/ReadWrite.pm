
package Spreadsheet::Perl ;

use 5.006 ;

use Carp ;
use strict ;
use warnings ;
use Data::Dumper ;


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

sub Read
{
my $ss = shift ;
my $file_name = shift ;

confess "Can't read file '$file_name'" unless -e $file_name ;

my $ss_data = do $file_name or confess("Couldn't evaluate setup file '$file_name': $@\n");

%$ss = GetSpreadsheetDefaultData() ;

for (keys %$ss_data)
	{
	next if /CELLS/ ;
	
	$ss->{$_} = $ss_data->{$_} ;
	}

$ss->{DEBUG}{ERROR_HANDLE} = \*STDERR unless defined $ss->{DEBUG}{ERROR_HANDLE} ;

for (keys %{$ss_data->{CELLS}})
	{
	$ss->Set($_, $ss_data->{CELLS}{$_}) ;
	}
}


#-------------------------------------------------------------------------------

sub Write
{
my $ss = shift ;
my $file_name = shift ;

my $ss_data = $ss->GeneratedWriteData() ;

open(SS_OUT, ">", $file_name) or croak qq[Can't open $file_name : $!] ;
print SS_OUT $ss_data ;
close(SS_OUT) ;
}


sub GeneratedWriteData
{
my $ss = shift ;
my $write_data = SerializeBuiltin() ;

# save functions
for (sort keys %Spreadsheet::Perl::defined_functions)
	{
	my $function = $Spreadsheet::Perl::defined_functions{$_} ;
	
	if(defined $function->{FUNCTION_BODY})
		{
		$write_data .= <<EOF
DefineSpreadsheetFunction('$_', undef, <<'DSF') ;
$function->{FUNCTION_BODY}
DSF

EOF
		}
	else
		{
		if(defined $function->{MODULE_NAME})
			{
			$write_data .= "use $function->{MODULE_NAME} ;\n" ;
			}
		else
			{
			warn "# Can't serialize function '$_'.\n" ;
			$write_data .= "\n\n# Couldn't serialize function '$_'.\n\n" ;
			}
		}
	}
	
$write_data .= <<EOH ;

#-------------------------------------------------------------------------------
# spreadsheet data, a hash reference
#-------------------------------------------------------------------------------
{ 

#-------------------------------------------------------------------------------
# spreadsheet setup
#-------------------------------------------------------------------------------
# default values will be set, we can override them
EOH

# save spreadsheet setup
$Data::Dumper::Indent = 2 ;
$Data::Dumper::Terse = 1 ;

for (sort keys %$ss)
	{
	next if /CELLS/ ;
	next if /VALIDATORS/ ;
	next if /OTHER_SPREADSHEETS/ ;
	next if /DEPENDENT_STACK/ ;
	next if /ERROR_HANDLER/ ;
	
	my $dump = Dumper($ss->{$_}) ;
	$dump =~ s/\n+$// ;
	
	$write_data .= "$_ => " . $dump . ",\n" ;
	}

$write_data .= <<EOH ;
#-------------------------------------------------------------------------------
# cell data
#-------------------------------------------------------------------------------
CELLS =>
	{
EOH

# save cells
for my $current_address ($ss->GetCellList())
	{
	my $current_cell = $ss->{CELLS}{$current_address} ;
	
	if(exists $current_cell->{FORMULA})
		{
		$write_data .= "\t$current_address => Formula('$current_cell->{FORMULA}[1]'),\n" ;
		}
		
	if(exists $current_cell->{GENERATED_FORMULA})
		{
		$write_data .= "\t$current_address => PerlFormula(" ;
		
		if($current_cell->{GENERATED_FORMULA} =~ /\n/)
			{
			$write_data .= "<<'EOF'),\n" ;
			$write_data .= $current_cell->{GENERATED_FORMULA} ;
			$write_data .=  "EOF\n" ;
			}
		else
			{
			$write_data .= "q~$current_cell->{GENERATED_FORMULA}~),\n" ;
			}
		}
	else
		{
		if(exists $current_cell->{VALUE})
			{
			if('CODE' eq ref $current_cell->{VALUE})
				{
				warn "# $current_address holds a sub ref, dummy will be written.\n" ;
				}
				
			my $dump = Dumper($current_cell->{VALUE}) ;
			$dump =~ s/\n+$// ;
			
			$write_data .= "\t$current_address => $dump,\n"
			}
		else
			{
			
			}
		}
	
	# handle these too:
	# formats
	# user data
	# validators
	}
	
$write_data .= <<EOH ;
	}
} ;

EOH

return($write_data) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::ReadWrite - File read/write support for Spreadsheet::Perl

=head1 SYNOPSIS

  $ss->Write('generated_ss_data.pl') ;
  $ss->Read('generated_ss_data.pl') ;

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

