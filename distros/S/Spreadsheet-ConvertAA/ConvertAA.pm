
package Spreadsheet::ConvertAA;

use 5.006;
use strict;
use warnings;
use Carp ;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( FromAA ToAA);
our $VERSION = '0.06';


#----------------------------------------------------

sub ToAA($)
{
my $c = shift ;
confess "Invalid base10 '$c'" if($c =~ /[^0-9]/) ;

return('@') if $c == 0 ;

my $cell = "";

while($c)
	{
	use integer;
	substr ($cell, 0, 0) = chr (--$c % 26 + ord "A");
	$c /= 26;
	}

return($cell) ;
}

sub FromAA ($)
{
my $cc = shift ;
confess "Invalid baseAA '$cc'" if($cc =~ /[^A-Za-z@]/) ;

my $c = 0;

while($cc =~ s/^([A-Z])//) 
	{
	$c = 26 * $c + 1 + ord ($1) - ord ("A");
	}

return($c);
}

#----------------------------------------------------

1;
__END__
=head1 NAME

Spreadsheet::ConvertAA - Perl extension for Converting Spreadsheet column name to/from  decimal

=head1 SYNOPSIS

  use Spreadsheet::ConvertAA ;

  my $baseAA = ToAA(475255) ;
  my $base10 = FromAA('AAAZ') ;

=head1 DESCRIPTION

This module allows you to convert from Spreadsheet column notation ('A', 'AZ', 'BC') to decimal and back.

The Spreadsheet column notation is base 26 _without_ zero. 'A' is 1 and 'AA' is 27. I named the base 'AA' because
I found no better name.

Spreadsheet::ConvertAA 'confess' on invalid input.

=head1 IMPORTANT

As of version 0.04, I have replaced the implementation of ToAA and FromAA with code from L<Spreadsheet::Read> written
by B<H.Merijn Brand>. The new code is cleaner. The new ToAA is 50% faster and the new FromAA is only slightly slower.

The new code doesn't have the limitation ConvertAA had previously.

=head2 EXPORT

ToAA and FromAA

=head1 AUTHOR

Khemir Nadim ibn Hamouda. <nadim@khemir.net>

  Copyright (c) 2004-2005 Nadim Ibn Hamouda el Khemir. All rights
  reserved.  This program is free software; you can redis-
  tribute it and/or modify it under the same terms as Perl
  itself.
  
If you find any value in this module, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=head1 SEE ALSO

L<Spreadsheet::Perl>. L<Spreadsheet::Read>.

=cut

