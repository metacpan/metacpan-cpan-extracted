package Number::MuPhone;
use 5.012;
use Number::MuPhone::Parser;
use Number::MuPhone::Data;
use Number::MuPhone::Config;

our $VERSION = '0.07';

# need this non-Moo encapsulation to allow backwards compatability with Number::Phone

# Bad parsers are seamlessly dropped - turn on debug to see them
# (useful when amending parsers, to keep an eye out for issues)
# Only really used when checking tweaks to the Parser modules
# bad syntax silently dies otherwise and it can be confusing while developing
our $DEBUG=0;


sub new {
  my ($class,@args) = @_;

  my ($country,$number,$is_number_phone)=('','',0);
  # normal instantiation
  if ( ref $args[0] eq 'HASH' ) {
    $country = $args[0]->{country};
    $number  = $args[0]->{number};
  }
  # Number::Phone style
  else {
    $number  = pop @args;
    $country = pop @args;
    $is_number_phone=1;
  }
  $number||='';

  # only number supplied - let's look up the country or use default (if set)
  if (!$country) {
    $country = _phone2country($number)
               || $Number::MuPhone::Config::config->{default_country}
               || '';
  }

  $country = uc($country);

  # at this point we have enough valid data to instantiate a parser
  my $parser_obj;
  if ($country) {
    my $parser_module = "Number::MuPhone::Parser::$country";
    eval {
      eval "use $parser_module";
      $parser_obj = $parser_module->new({
        number  => $number,
      });
    };
    if ($@) {
      $DEBUG && warn "Couldn't load module ($parser_module): $@\n";
      $country ||= 'NO COUNTRY';
      $parser_obj = Number::MuPhone::Parser->new({
        number  => $number,
      });
      $parser_obj->error("Invalid country ($country)");
    }
  }

  # if load fails, default back to base class and set an error
  # (missing or bad parser module)
  if (!$parser_obj) {
    $parser_obj = Number::MuPhone::Parser->new({
      number  => $number,
    });
  }

  # Improve error message for some strings
  # starts with a + but not a valid international country?
  if ( $parser_obj->error && !$country && $number =~ /^\s*\+(.)/ ) {
    my $first_digit = $1;
    if ( $first_digit eq '0' ) {
      $parser_obj ->error('Invalid country code - no country code begins with a zero');
    }
    else {
      $parser_obj ->error('Invalid country code - could not determine country');
    }
  }


  # duplicate Number::Phone behavior
  if ( $number && $parser_obj->error && $is_number_phone ) {
    $DEBUG && warn "ERROR: ".$parser_obj->error;
    return undef;
  }
  return $parser_obj;
}

# rewritten version of code used in Number::Phone
sub _phone2country {
  my $num = shift || '';

  # if number doesn't begins with + we can't determine the country
  # if you need a default country, set 'default_country' in a config file, set it in a config file
  $num =~ /^\s*\+/ or return '';

  # strip out non-digits
  $num =~ s/[^0-9]//g;

  # deal with NANP insanity
  if( $num =~ m/^1(\d{3})\d{7}/ ) {
    my $area = $1;
    if (my $country = $Number::MuPhone::Data::NANP_areas{$area}) {
      return $country;
    }
    else {
      return 'NANP';
    }
  } else {
    my @prefixes = map { substr($num, 0, $_) } reverse 1..7;
    foreach my $idd (@prefixes) {
      if( my $country = $Number::MuPhone::Data::idd_codes{$idd} ) {
        return $country;
      }
    }
  }
  return '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::MuPhone - phone number parsing and display

=head1 VERSION

version 0,01

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Number::MuPhone;

  my $num_us = Number::MuPhone->new({number => '+12035031111'});
  my $num_uk = Number::MuPhone->new({number => '+441929552618'});

  # shortcut for displaying the relevant national dial / display numbers from from
  # within this number's country
  my $dial    = $num_us->dial;        # alias for $num->dial_from($num);
  my $display = $num_us->display;     # alias for $num->display_from($num);

  # show how to dial this number from the number/country supplied.
  $dial = $num_uk->dial_from('US');
  $dial = $num_uk->dial_from($num_us);
  $dial = $num_uk->dial_from('+12035031111');

  # show formatted display number from the number/country supplied.
  $display = $num_uk->display_from('US');
  $display = $num_uk->display_from($num_us);
  $display = $num_uk->display_from('+12035031111');

=head1 DESCRIPTION

Number::MuPhone is a simplified rewrite of Number::Phone with the internal 
caching removed, and with the ability to parse extensions added

One sentence summary:

"Parse and display phone numbers from/to multiple formats"

This module came about when I was trying to write a parser to run a batch
job for several million numbers. Number::Phone looked like it fit the bill, but
it contains an undocumented cache that caused issues with such large data
sets. I initially looked at patching Number::Phone, but soon realised that
would be a lot more work than I anticipated. Couple that in with extra 
parsing capabilities (mainly for extensions and 'fuzzy' numbers) that I was
looking to add and I made the decision to start from scratch.

=head1 USAGE

=head2 Instantiation

Two arguments are needed to instantiate - a number and a country.

The number must be supplied, but the country can be determined through:

  * supplying a number in E.164/E.123 format;
  * explicitly supplying a country.
  * setting a default_country attribute in your config file

All of these will get parsed as valid US numbers

  my $num = Number::MuPhone->new({ number => '+12035031234' });
  my $num = Number::MuPhone->new({ number => '+1 203 503 1234' });
  my $num = Number::MuPhone->new({ number => '+1 203 503 1234 ext 1234' });

as will this

  my $num = Number::MuPhone->new({ number => '203 503 1198', country => 'US' });

If you have set default_country in a config file (see below), then this
will try to parse the number using the home country's parser

  my $num = Number::MuPhone->new({ number => '203 503 1198' });

  # Two other methods of instantiation are available for users familiar
  # with Number::Phone 
  my $num = Number::MuPhone->new('+12035031234');
  my $num = Number::MuPhone->new('US','2035031234');

=head2 Handling Errors

If used, a bad configuration file will cause your code to die at run time.

Otherwise, when instantiating the object, if an error is encountered it is
accessable through the error() method, eg:

  my $num = number::Phone->new({ number => '203 230 320', country => 'US' });

  if ( my $err = $num->error ) {
    die "Invalid phone number: $err";
  }

=head2 Object Accessors

$num->number
  Original number string (including extension, if relevant) supplied at instantiation

$num->country
  Two char country code, either supplied at instantiation or derived from the number

$num->country_name
  Country name (Currently in English only)

$num->country_code
  International country code for number.
  See: https://en.wikipedia.org/wiki/List_of_country_calling_codes

$num->extension
  If supplied in the initial number, the number's extension (digits only)

$num->error
  If not a valid number, error is stored here

$num->storage_formatted_number
  A concise, readable string for storing a number, with optional extension in (say)
  a database field. eg,

  my $num = Number::MuPhone->new({ number => '203 503 1111 extension 1234', country => 'US' });
  $num->storage_formatted_number -> '+1 2035031111 x1234'  

$num->E123
  Number in E.123 format for display

$num->international_display
  Display number in standard +COUNTRY_CODE NUMBER format 
  Alias of $num->E123

$num->dial_from( $obj || num || '2 char country code');
$num->display_from( $obj || num || '2 char country code');

  These methods work the same way - single arg is either:

  * another Number::MuPhone object;
  * a raw phone number that will parse correctly to a valid Number::MuPhone object; or
  * a two character country code

  $num->dial    => alias for $num->dial_from($num);
  $num->display => alias for $num->display_from($snum);

  my $num_uk = Number::MuPhone->new('+442012341234');
  my $num_us = Number::MuPhone->new('+12035031111');

  $num_uk->dial                                 # 02012341234
  $num_uk->dial_from('UK')                      # 02012341234
  $num_uk->dial_from('US')                      # 011442012341234
  $num_uk->dial_from('+12035031111')            # 011442012341234
  $num_uk->dial_from($num_us)                   # 011442012341234
  
  $num_uk->display                              # 020 1234 1234
  $num_uk->display_from('UK')                   # 020 1234 1234
  $num_uk->display_from('US')                   # 011 44 20 1234 1234
  $num_uk->display_from('+12035031111')         # 011 44 20 1234 1234
  $num_uk->display_from($num_us)                # 011 44 20 1234 1234
  
$num->E164
  Number in E.164 format - see https://en.wikipedia.org/wiki/E.164
  Note: this drops the extension as this format does not appear to
  support them

$num->international_dial
  Full number to dial, including extension
  $num->E164 + dialer pause + $num->extension

$num->E123
  Number in E.123 format - see https://en.wikipedia.org/wiki/E.123
  Includes extension

=head2 Configuration file

If you want to set a default_country or dialer options, create a configuration file
An example file is included in the distribution in the ./t/data directory.

Currently, only two attributes are recognized (more coming soon!):

* default_country - if set and instantiating a number with no country set, the parser
  will assume the number is in the default_country unless it determines the country
  from an E.164/E.123 supplied number. Default value is undefined.

* dialer => pause - the pause character to use in dialer numbers. Default is a comma

There are two ways you can indicate that a conf file should be loaded:

* by setting the path to the config file in the ENV variable MUPHONE_CONF_FILEPATH;
* by creating a .muphone_conf.yaml file in your $HOME directory

Example conf files are available in the ./t/data directory of this distribution

=head1 ACKNOWLEDGEMENTS

With thanks to Tye McQueen and John Binns for code and philosophical input, and
to my employer, ZipRecruiter, for encouraging employees to release the code we use
as Open Source where possible.

=head1 BUGS/CAVEATS

Email bugs/comments to me.

Software is provided as is. No guarantees are made as to its usefulness 
or reliability :D

=head1 AUTHOR

Clive Holloway <clive.holloway@gmail.com>

Copyright (c) 2017 Clive Holloway

=head1 SEE ALSO

Number::Phone was the inspiration for this module, and it contains different
functionality. Check it out.

=cut
