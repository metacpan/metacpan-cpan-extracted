package Number::MuPhone::Parser::UK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'                    => ( default => 'UK'             );
has '+country_code'               => ( default => '44'             );
has '+country_name'               => ( default => 'United Kingdom' );
has '+_national_dial_prefix'      => ( default => '0'              );
has '+_international_dial_prefix' => ( default => '00'             );
has '+_international_dial_spacer' => ( default => ''               );

# format the number for display
# also used as a core validator - if it can't be formatted, assume bad number
# when validating, ensure you set an error and *not* set _formatted_number
sub _format_number {
  my $self = shift;
  my $num = $self->_cleaned_number;

  # UK has a bunch of display formats, as documented here:
  # http://www.area-codes.org.uk/formatting.php
  # last checked 2017-06-24

  # 0[46] - not used

     # 02X XXXX XXXX
     $num =~ s/^(2\d)(\d{4})(\d{4})$/$1 $2 $3/
     # 0[389]XX XXX XXXX
  or $num =~ s/^([389]\d{2})(\d{3})(\d{4})$/$1 $2 $3/
     # 0[57]XXX XXXXXX
  or $num =~ s/^([57]\d{3})(\d{6})$/$1 $2/
     # 0800 XXXXXX
  or $num =~ s/(800)(\d{6})/$1 $2/
     # 0[89]XX XXX XXXX 
  or $num =~ s/^([89]\d{2})(\d{3})(\d{4})$/$1 $2 $3/
     # 01 numbers are a pain....  
     # 01X1 XXX XXXX or 011X XXX XXXX
  or $num =~ s/(1\d1|11\d)(\d{3})(\d{4})$/$1 $2 $3/
     # 013873 ##### 015242 ##### 015394 ##### 015395 ##### 015396 ##### 016973 ##### 
     # 016974 ##### 017683 ##### 017684 ##### 017687 ##### 019467 #####
  or $num =~ s/^(13873|15242|15394|15395|15396|16973|16974|17683|17684|17687|19467)(\d{5})$/$1 $2/
     # 016977 #### / 016977 #####
  or $num =~ s/^(16977)(\d{4,5})$/$1 $2/
     # 01XXX XXXXX / 01XXX XXXXXX
  or $num =~ s/^(1\d{3})(\d{5,6})$/$1 $2/
     # doesn't match any known pattern, so it's invalid
  or $self->error("Not a valid UK number");

  return $num;
}

1;
