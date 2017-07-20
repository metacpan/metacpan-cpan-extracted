package Number::MuPhone::Parser;
use 5.012;
use Moo;
use Number::MuPhone::Config;


# base class for number parsers
# many countries don't have parsers (yet), so this is a sane default

# user shouldn't be calling the parser module direct
# if they do, ensure all args exist
# assume they are valid - user error if not ;-)

########################################
# attributes
# - first 2 are required at instantiation
# - and only 2 expected
########################################

# originally supplied phone number
has number => (
  is       => 'ro',
);

# 2 upper case char country code (except for catchall NANP)
#  - inherited from subclass (matches module name
has country => ( is => 'ro' );

# common name for the country
#  - inherited from subclass
has 'country_name' => ( is => 'ro' );

# international country code - numeric country code
#  - inherited from subclass
has country_code => ( is => 'ro' );

# optional extension
# - determined from number
has extension => ( is => 'rw', default => '' );

# store error message (silently ignored under Number::Phone
has error => ( is => 'rw', default => '' );

# default or loaded config
has config => (
  is => 'ro',
  default => sub {
    return $Number::MuPhone::Config::config 
  }
);

# "standard" way to display the number in International Format
# E.123 format
has international_display => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return '+'.$self->country_code.' '.$self->_formatted_number.$self->_extension_display;
  }
);

# dial number when you're in the country
# this default should work for most countries
has _national_dial => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return $self->_national_dial_prefix.$self->_cleaned_number.$self->_extension_dial;
  }
);

# return number formatted in E164 format (note, this drops the extension)
# https://en.wikipedia.org/wiki/E164
has E164 => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return '+'.$self->country_code.$self->_cleaned_number;
  }
);

# how do you dial the number when out of the country
# just an alias for E.164 format with (pause) extension added
sub international_dial { 
  my $self = shift;
  return $self->E164.$self->_extension_dial;
}

# E123 format is like E164 + spacing
# https://en.wikipedia.org/wiki/E123
has E123 => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return '+'.$self->country_code.' '.$self->_formatted_number.$self->_extension_display;
  }
);

# How you want to store the number (say, in the DB)
# defaults to +C N[ xE] (where C=Country code, N=number and E is optional extension)
has storage_formatted_number => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $num = '+'.$self->country_code.' '.$self->_cleaned_number;
    $self->extension
      and $num .= ' x'.$self->extension;
    return $num;
  }
);

# shortcut
sub display {
  my $self = shift;
  return $self->display_from( $self );
}

# shortcut 
sub dial {
  my $self = shift;
  return $self->dial_from( $self );
}

# return formatted number in national or international format, depending on where
# the 'from' number (arg sent) is located
sub display_from {
  my ($self,$str) = @_;
  my $from = $self->_get_obj_from($str);
  if ( $from->country_code eq $self->country_code ) {
    return $self->_national_display;
  }
  else {
    # (DIAL PREFIX) (SPACER) (COUNTRY CODE) (FORMATTED NUMBER) [ (EXTENSION) ]
    return $from->_international_dial_prefix.$from->_international_dial_spacer.$self->country_code.' '
          .$self->_formatted_number.$from->_extension_display;
  }
}

# return dial number in national or international format, depending on where
# the 'for' number (arg sent) is located
sub dial_from {
  my ($self,$str) = @_;
  my $obj = $self->_get_obj_from($str);
  if ( $obj->country_code eq $self->country_code ) {
    return $self->_national_dial;
  }
  else {
    return $obj->_international_dial_prefix.$self->country_code.$self->_cleaned_number;
  }
}

sub BUILD {
  my $self = shift;

  $self->number  or $self->error("'number' is required")  and return;
  $self->country or $self->error("'country' is required")  and return;

  # all of these actions can be overloaded on a per country basis
  # - _parse_number_and_extension()
  # - _parse_number
  # - _format_number

  # get raw number and extension from string
  # (may still contain punctuation)
  my ($rawnum,$extension) = $self->_parse_number_and_extension;
  if ($extension) {
    $extension =~ s/\D//g;
    $self->extension($extension);
  }

  # clean up to international format (minus country code) for base usage
  $self->_cleaned_number( $self->_parse_number($rawnum) );

  # local error checking and display formatting
  # fits known number patterns and reformats number as needed
  $self->_formatted_number( $self->_format_number );
};

# on init, this is created from the raw number
has _cleaned_number => (
  is => 'rw',
);

# prefix you dial when dialing the _cleaned_number within the country
#  - inherited from subclass
has _national_dial_prefix => ( is => 'ro' );

# prefix you dial when dialing *out* of the country to an international number
#  - inherited from subclass
has _international_dial_prefix => ( is => 'ro' );

# spacer to put between _international_dial_pref and country_code
# when displaying a full number
has _international_dial_spacer => ( is => 'ro', default => ' ' );

# When overloading this, try to keep as spaces and numbers only
# (to stay in E.123 format)
# If national_display uses different punctuation, add that in there, not here.
# this is the general, "how should I space the number in an expected way" method
has _formatted_number => ( is => 'rw' );
sub _format_number {
  my $self = shift;
  my $num = $self->_cleaned_number||'';

  if ( length($num) == 12 ) {
    $num =~ s/^(\d{4})(\d{4})(\d{4})$/$1 $2 $3/;
  }
  elsif ( length($num) == 11 ) {
    $num =~ s/^(\d{3})(\d{4})(\d{4})$/$1 $2 $3/;
  }
  elsif ( length($num) == 10 ) {
    $num =~ s/^(\d{3})(\d{3})(\d{4})$/$1 $2 $3/;
  }
  elsif ( length($num) == 9 ) {
    $num =~ s/^(\d{4})(\d{5})$/$1 $2/;
  }
  elsif ( length($num) == 8 ) {
    $num =~ s/^(\d{4})(\d{4})$/$1 $2/;
  }
  elsif ( length($num) == 7 ) {
    $num =~ s/^(\d{3})(\d{4})$/$1 $2/;
  }
  return $num;
}

# text to display before extension
has _extension_text => ( is => 'rw', default => 'ext ' );

# How do you display the number when you're in the country?
# this default should work for most countries
has _national_display => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return $self->_national_dial_prefix.$self->_formatted_number.$self->_extension_display;
  }
);

# sane default in English - overload as needed
# MUST return the parsed out phone number and extension
# can contain extraneous characters - this is basically just splitting
# the number from the extension
sub _parse_number_and_extension {
  my $self = shift;
  # note - extension / ext / x must be in that order for highest chance of valid match
  my ($num,$ext) = split /(?:\*|extension|ext|x)/, $self->number;
  $ext||='';
  return ($num,$ext);
}

# sane default - overload in country class if needed
# this should work for most numbers
sub _parse_number {
  my ($self,$rawnum) = @_;

  my $country_code         = $self->country_code;
  my $_national_dial_prefix = $self->_national_dial_prefix;   

  $rawnum =~ s/[^\+0-9]//g;                   # remove non-digits (except +)
  $rawnum =~ s/\+$country_code//;             # remove country_code()
  $rawnum =~ s/^$_national_dial_prefix//;     # remove _national_dial_prefix()

  return $rawnum;
}

# for flexibility, we can parse out the country from
# - another Number::MuPhone::Parser::* object
# - a phone number string
#   - return local country if we can't parse this
sub _get_obj_from {
  my ($self,$str) = @_;

  # another parser object
  my $ref = ref $str;
  if ( $ref =~ /^Number::MuPhone::Parser::/ ) {
    return $str;
  }
  # assume it's a country code
  elsif ( $str =~ /^(?:[A-Z]{2}|[A-Z]{4})$/ ) {
    return Number::MuPhone->new({country => $str});
  }
  # assume it's a raw phone number
  else {
    my $num = Number::MuPhone->new({ number => $str });
    if ( $num->error ) {
      # OK, so it wasn't a valid phone number, so let's display for local country as sane default
      return $self;
    }
    else {
      # we found a phone number, so return object
      return $num;
    }
  }
}

sub _extension_display {
  my $self = shift;
  my $ext = 
  return $self->extension
         ? ' '.$self->_extension_text.$self->extension
         : '';
}

sub _extension_dial {
  my $self = shift;
  my $pause = $self->config->{dialer}->{pause} || '';
  return $self->extension
         ? $pause.$self->extension
         : '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::MuPhone::Parser

=head1 VERSION

version 0,01

=head1 DESCRIPTION

Base phone number parser class. Contains sane defaults.

This document covers how you might want to tweak Parser methods on a per
country basis. For further documentation, please see the Number::MuPhone POD.

If you do find a need, please contact me so I can merge useful changes in
as needed.

For each Number::MuPhone::Parser::COUNTRY.pm module, you must set values
for the attributes country, country_code, country_name, 
_national_dial_prefix and _international_dial_prefix. eg:

    has '+country'                    => ( default => 'UK'             );
    has '+country_code'               => ( default => '44'             );
    has '+country_name'               => ( default => 'United Kingdom' );
    has '+_national_dial_prefix'      => ( default => '0'              );
    has '+_international_dial_prefix' => ( default => '00'             );

These are already set for known countries.

=head1 COMMONLY OVERLOADED METHODS

Pretty much anything *may* benefit from overloading on a per country basis,
but these are the most common methods that are need to be overloaded.

=head2 _format_number() 

Different countries have different ways of displaying phone numbers.

The method _format_number is used to take the raw number (minus any extension)
and format it a way that is normal for that country. The US's formatter is 
simple; the UK's, not so much. It doesn't just do that though. It:

* confirms the number is valid;
* formats the number for common display; 
* sets an error() if there's a problem; and
* sets the value in the _formatted_number accessor.

On completion of validation, it returns the formatted number if valid, or the
original number if an error was encountered.

There's a generic default, but it should be overloaded in each country's 
Parser. This is an ongoing project to replace.

=head2 _extension_text

Text to display after the number plus a space, but before the extension.

This defaults to the english 'ext ' but can be overloaded in individual 
countries as needed.


=head2 display_from( $num | $num_obj | country )

This works out of the box for 90% of countries, but there are a few places 
where this may need overwriting - eg, dialing French territories from France.

=head2 dial_from( $num | $num_obj | country )

This works out of the box for 90% of countries, but there are a few places 
where this may need overwriting - eg, dialing French territories from France.

=head2 _parse_number_and_extension

Basically split the entered number on a string that marks an extension.

Defaults to English.

Can amend this rule as needed in country classes

=head1 AUTHOR

Clive Holloway <clive.holloway@gmail.com>

Copyright (c) 2017 Clive Holloway 

=cut
