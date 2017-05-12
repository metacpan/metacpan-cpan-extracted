
package Spreadsheet::Perl::Arithmetic ;

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

our @EXPORT = qw( ) ;
#our @EXPORT ;
#push @EXPORT, qw( ) ;

our $VERSION = '0.02' ;

use Spreadsheet::Perl ;
use Scalar::Util qw(looks_like_number) ;

#-------------------------------------------------------------------------------

sub Sum
{
my $ss = shift ;
my @addresses  = @_ ;

my $sum = 0 ;

for my $address (@addresses)
	{
	for my $current_address ($ss->GetAddressList($address))
		{
		my $cell_value = $ss->Get($current_address) ;
		
		#~ if(exists $ss->{DEBUG_MODULE}{ARITHMETIC_SUM})
			#~ {
			#~ print $self->{DEBUG}{ERROR_HANDLE} "Sum: $current_address => $cell_value\n" ;
			#~ }
		
		$sum += $cell_value if (defined $cell_value && looks_like_number($cell_value)) ; 
		}
	
	}
	
return($sum) ;
}

DefineSpreadsheetFunction('Sum', \&Sum, undef, __PACKAGE__) ;
DefineSpreadsheetFunction('SUM', \&Sum, undef, __PACKAGE__) ;

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

Spreadsheet::Perl::Arithmetic - Arithmetic functions for Spreadsheet::Perl

=head1 SYNOPSIS

  my $sum = $ss->Sum('A5:B8') ;
  $ss{A5} = PerlFormula('$ss->Sum('A5:B8')') ;
  
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
