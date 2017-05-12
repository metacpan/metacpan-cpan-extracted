package String::Nysiis;

require 5.005_62;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    nysiis
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT  = qw();
our $VERSION = '1.00';


# Preloaded methods go here.
sub nysiis
{
  my($string) = @_;

  $string = uc($string);
  
  $string =~ s/[^A-Za-z]//g;
  $string =~ s/[SZ]*$//g;
  $string =~ s/^MAC/MC/;
  $string =~ s/^PF/F/;

  $string =~ s/IX$/IC/;
  $string =~ s/EX$/EC/;
  $string =~ s/(?:YE|EE|IE)$/Y/;
  $string =~ s/(?:NT|ND)$/N/;

  $string =~ s/(.)EV/$1EF/g;
  my $first = substr($string,0,1);
  $string =~ s/[AEIOU]+/A/g;
  $string =~ s/AW/A/g;
    
  $string =~ s/GHT/GT/g;
  $string =~ s/DG/G/g;
  $string =~ s/PH/F/g;
  $string =~ s/(.)(?:AH|HA)/$1A/g;
  $string =~ s/KN/N/g;
  $string =~ s/K/C/g;
  $string =~ s/(.)M/$1N/g;
  $string =~ s/(.)Q/$1G/g;
  $string =~ s/(?:SCH|SH)$/S/;
  $string =~ s/YW/Y/g;
  
  $string =~ s/(.)Y(.)/$1A$2/g;
  $string =~ s/WR/R/g;
  
  $string =~ s/(.)Z/$1S/g;
  
  $string =~ s/AY$/Y/;
  $string =~ s/A+$//;

  $string =~ s/(\w)\1+/$1/g;
  
  if ($first =~ /[AEIOU]/) {
    substr($string,0,1) = $first;
  }
    
  return $string;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

String::Nysiis - NYSIIS Phonetic Encoding

=head1 SYNOPSIS

  use String::Nysiis qw(nysiis);
  my $enc = nysiis($string);

  print nysiis('Larry'),"\n"; # should print LARY

=head1 DESCRIPTION

New York State Identification and Intelligence System (NYSIIS) algorithm
for phonetic encoding of names.

=head2 EXPORT

None by default.


=head1 AUTHOR

This module is based on a NYSIIS implementation by 
Ben Kennedy <bkennedy@hmsonline.com>.  It is currently
being maintained by:

 Kyle R. Burton 
 krburton@cpan.org
 kburton@hmsonline.com
 HMS
 625 Ridge Pike
 Building E
 Suite 400
 Conshohocken, PA 19428
 

=head1 SEE ALSO

 Atack, J., and F. Bateman. 1992.  
  "Matchmaker, matchmaker, make me a match" : a general personal 
    computer-based matching program for historical research. 
    Historical Methods 25: 53-65.

perl(1).  Text::DoubleMetaphone.  Text::Soundex.

=cut
