package Taxon::Parse::Normalize;

use strict;
use warnings;
use utf8;

use parent qw( Taxon::Parse );

#use HTML::Entities;

our $VERSION = '0.013';

# decode_entities($a);
# encode_entities($a, "\200-\377");

#use Unicode::Normalize;
# NFC($string);

sub init {
  my $self = shift;

  my $p = $self->{pattern_parts};

  $p->{comma_before_year} = qr/
    (?:
		,+
		|[^0-9\(\[\"])\s*\d{3}    #????
    )
  /xms;
  $p->{quotes} = qr/[\"'`´]+/xms;
  $p->{UPPERCASE_WORD} = qr/ \b ( \p{Lu}{2,} ) \b /xms;
  $p->{WHITESPACE} = qr/\s+/xms;
  $p->{SQUARE_BRACKETS} = qr/ \[ (.*?) \] /xms;
  $p->{BRACKETS_OPEN} = qr/( [{(\[] ) \s* /xms;
  $p->{BRACKETS_CLOSE} = qr/ \s* ( [})\]] ) /xms;
  $p->{BRACKETS_OPEN_STRONG} = qr/(\s?[{(\[]\s?)+/xms;
  $p->{BRACKETS_CLOSE_STRONG} = qr/(\s?[})\\]]\s?)+/xms;
  $p->{NORM_AND} = qr/ \s (and|et|und|&amp;) \s /xms;
  $p->{NORM_ET_AL} = qr/ & \s al\.?/xms;
  $p->{NORM_AMPERSAND_WS} = qr/&/xms;
  $p->{NORM_HYPHENS} = qr/\s*-\s*/xms;
  $p->{NORM_COMMAS} = qr/\s*,+/xms;        
          
  $p->{NORM_HYBRIDS_FORM} = qr/\s[×xX]\s/xms;
  $p->{NORM_HYBRIDS_GENUS} = "";
  $p->{NORM_HYBRIDS_EPITH} = "";
          
  my $patterns = $self->{patterns};
  my @patterns = qw< full abbreviated_name>;
  map { $patterns->{$_} = $p->{$_} } @patterns;

}


sub normalise {
  my $self = shift;
  my $string = shift;
            
  if ($string eq '') {
    return $string;
  }
    
  $string =~ s/—//g;
  $string =~ s/://g;
 
  # use commas before years
  # ICZN §22A.2 http://www.iczn.org/iczn/includes/page.jsp?article=22&nfv=
  $string =~ s/$this->COMMA_BEFORE_YEAR/$1, $2'/;
            
            
  # no whitespace around hyphens
  $string =~ s/$this->NORM_HYPHENS/-/;
  # use whitespace with &
  $string =~ s/$p->{NORM_AMPERSAND_WS}/ & /;
              
  # whitespace before and after brackets, keeping the bracket style
  $string =~ s/$p->{NORM_BRACKETS_OPEN}/ $1/;
  $string =~ s/$p->{NORM_BRACKETS_CLOSE}/$1 /;
  # remove whitespace before commas and replace double commas with one
  $string =~ s/$p->{NORM_COMMAS}/, /;
  # normalize hybrid markers
  $string =~ s/$p->{NORM_HYBRIDS_GENUS}/×$1/;
  $string =~ s/$p->{NORM_HYBRIDS_EPITH}/$1 ×$2/;
  $string =~ s/$p->{NORM_HYBRIDS_FORM}/ × /;
  # capitalize all entire upper case words
  $string =~  s/$p->{NORM_UPPERCASE_WORDS}/ucfirst(lc($1)/eg;
   
  $string =~ s/\s\s+/ /g;
                $string =~ s/^\s//;
                $string =~ s/\s$//;
                
            return $string;
}

1;