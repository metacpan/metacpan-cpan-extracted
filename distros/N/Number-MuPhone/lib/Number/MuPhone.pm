package Number::MuPhone;
use strict;
use warnings;
use v5.020;
use Moo;
use Types::Standard qw( Maybe Str );

$Number::MuPhone::VERSION = '1.02';

our $MUPHONE_BASE_DIR = $ENV{MUPHONE_BASE_DIR} || $ENV{HOME}.'/.muphone';
our $EXTENSION_REGEX  = qr/(?:\*|extension|ext|x)/;
our $DIAL_PAUSE       = ',,,';

# if custom data module exists, load it, else use distribution default
# (which will most likely be out of date)
our $MUPHONE_DATA;
my $data_module_path = "$MUPHONE_BASE_DIR/lib/NumberMuPhoneData.pm";
if (-f $data_module_path) {
  require $data_module_path;
}
else {
  require Number::MuPhone::Data;
}
# Let's import the var shortcut to save typing
Number::MuPhone::Data->import('$MUPHONE_DATA');

################################################################################

=head1 NAME

Number::MuPhone - parsing and displaying phone numbers in pure Perl

NOTE: this is a full rewrite and is not backwards compatible with earlier
versions of this module.

=head1 DESCRIPTION

Parse, validate (loosely in some cases) and display phone numbers as expected.

This has stripped down functionality compared to libphonenumber, but it is
also Pure Perl (TM), is simpler to use, and contains the core functionality
needed by common use cases.

If you have functionality requests, please let me know: L<mailto:clive.holloway@gmail.com>

All number regexes are derived from the XML file supplied by:

L<https://github.com/google/libphonenumber/>


=head1 BASIC USAGE

Instantiate an instance using one of the following syntaxes

    # single arg: E.123 formatted number, scalar shortcut
    my $num = Number::MuPhone->new('+1 203 503 1199');

    # single arg: E.123 formatted number, hashref format
    my $num = Number::MuPhone->new({
                number => '+1 203 503 1199'
              });

    # double arg, number and country - number can be in local or E.123 format, scalar args
    my $num = Number::MuPhone->new('+1 203 503 1199','US");
    my $num = Number::MuPhone->new('(203) 503-1199','US');

    # double arg, number and country - number can be in local or E.123 format, hashref args
    my $num = Number::MuPhone->new({
                number  => '+1 203 503 1199'
                country => 'US',
              });
    my $num = Number::MuPhone->new({
                number  => '(203) 503-1199'
                country => 'US',
              });

    # after instantiation, check all is well before using the object
    if ($num->error) {
      # process the error
    }


=head1 ATTRIBUTES

=cut

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;

  # args are probably a hashref - { number => $number, country => 'US' }
  # but can use a shortcut, if preferred
  # ($number, 'US')

  if (ref $args[0] ne 'HASH' and @args>2) {
    die "Bad args - must be a hashref of name args or (\$num,\$country_code)";
  }

  if (!ref $args[0]) {
    $args[0] = { number => $args[0] };

    $args[0]->{country} = pop @args
      if $args[1];
  }

  return $class->$orig(@args);
};

sub BUILD {
  my ($self,$arg) = @_;

  # extract number and extension, determine countrycode from number,
  # strip off possible national/international dial prefix
  # and store attributes as needed
  $self->_process_raw_number;

}

=head2 number

The raw number sent in at instantiation - not needed (outside of logging, maybe)

=cut

has number => (
  isa      => Str,
  is       => 'ro',
  required => 1,
);

=head2 extension

Extenstion number (digits only)

=cut

has extension => (
  is => 'rw',
  default => ''
);

=head2 country

The 2 character country code sent in instantiation, or inferred from an E.123 number

=cut

# 2 char country code - either explicitly sent, to inferred from the number / config
has country => (
  isa  => Maybe[Str],
  is   => 'rw',
  lazy => 1,
);

=head2 error

If the args don't lead to a valid number at instantiation, this error will be set

=cut

has error => (
  isa      => Str,
  is       => 'rw',
  default  => '',
);

=head2 country_name

Full text name of country (may be inaccurate for single arg instantiation - see below)

=cut

has country_name => (
  is => 'lazy',
);
sub _build_country_name {
  my $self = shift;
  return $MUPHONE_DATA->{territories}->{ $self->country }->{TerritoryName};
}

=head2 country_code

1-3 digit country code

=cut

has country_code => (
  is => 'lazy',
);
sub _build_country_code {
  my $self = shift;
  return $MUPHONE_DATA->{territories}->{ $self->country }->{countryCode};
}

=head2 national_dial

How you would dial this number within the country (including national dial code)

=cut

has national_dial => (
  is => 'lazy',
);
sub _build_national_dial {
  my $self = shift;
  my $dial_prefix = $self->_national_prefix_optional_when_formatting
                      ? ''
                      : $self->_national_dial_prefix;

  return $dial_prefix.$self->_cleaned_number.$self->_extension_dial;
}

=head2 national_display

Display this number in the national number format

=cut

# How do you display the number when you're in the country?
# this default should work for most countries
has national_display => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $dial_prefix = $self->_national_prefix_optional_when_formatting
                      ? ''
                      : $self->_national_dial_prefix;

    return $dial_prefix.$self->_formatted_number.$self->_extension_display;
  }
);

=head2 international_display

Display this number in the international number format (E.123)

=cut

has international_display => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return '+'.$self->country_code.' '.$self->_formatted_number.$self->_extension_display;
  }
);

=head2 e164

The number in E.164 format (+$COUNTRY_CODE$NUMBER[;ext=$EXTENSION])

=cut

has e164 => (
  is => 'lazy',
);
sub _build_e164 {
  my $self = shift;
  my $ext = $self->extension
            ? ";ext=".$self->extension
            : '';
  return $self->e164_no_ext.$ext;
}

=head2 e164_no_ext

The number in E.164 format, but with no extension  (+$COUNTRY_CODE$NUMBER)

=cut

has e164_no_ext => (
  is => 'lazy',
);
sub _build_e164_no_ext {
  my $self = shift;
  return '+'.$self->country_code.$self->_cleaned_number;
}

# number with international and national dial codes, and all non digits removed
has _cleaned_number => (
  is      => 'rw',
  default => '',
);

# basic validation of a number via this regex
has _national_number_regex => (
  is => 'lazy',
);
sub _build__national_number_regex {
  my $self = shift;
  my $regex_string = $MUPHONE_DATA->{territories}->{ $self->country }->{generalDesc}->{nationalNumberPattern};
  return qr/^$regex_string$/;
}

# Display number without international or nation dial prefixes
# built by _process_raw_number
has _formatted_number => (
  is => 'rw',
);

# Boolean used to help determine how to display a number
# built in sub _process_raw_number
has _national_prefix_optional_when_formatting => (
  is      => 'rw',
);

# add pause to extension to create dial
has _extension_dial => (
  is => 'lazy',
);
sub _build__extension_dial {
  my $self = shift;
  return $self->extension
         ? $DIAL_PAUSE.$self->extension
         : '';
}

# prefix you dial when dialing the _cleaned_number within the country
has _national_dial_prefix => (
  is => 'lazy',
);
sub _build__national_dial_prefix {
  my $self = shift;
  $MUPHONE_DATA->{territories}->{ $self->country }->{nationalPrefix};
}

# how to display the extension text + number (currently only in English)
has _extension_display => (
  is => 'lazy',
);
sub _build__extension_display {
  my $self = shift;
  my $ext =
  return $self->extension
         ? ' '.$self->_extension_text.' '.$self->extension
         : '';
}

# text to display befor an extension
has _extension_text => (
  is => 'ro',
  default => 'ext',
);

# helper method to get the country for a number, country, or object
sub _get_country_from {
  my ($self,$str_or_obj) = @_;

  # $str_or_arg should be
  # - Number::MuPhone instance
  # - E.123 formatted number
  # - 2 char country code

  # muphone num
  if (ref $str_or_obj eq 'Number::MuPhone') {
    return $str_or_obj->country;
  }
  # E.123
  elsif ($str_or_obj =~ /^\s\+/) {
    my $num = Number::MuPhone->new($str_or_obj);
    return $num->country;
  }
  # it should be a country
  elsif ( $str_or_obj =~ /^[A-Z]{2}$/ ) {
    return $str_or_obj;
  }
  else {
    die "Not a country, E.123 num, or MuPhone object: $str_or_obj";
  }
}

=head1 METHODS

=head2 dial_from

How to dial the number from the number/country sent in as an arg. eg

    my $uk_num1 = Number::MuPhone->new({ country => 'GB', number => '01929 552699' });
    my $uk_num2 = Number::MuPhone->new({ country => 'GB', number => '01929 552698' });
    my $us_num  = Number::MuPhone->new({ country => 'US', number => '203 503 1234' });

    # these all have the same output (01929552699)
    my $dial_from_uk = $uk_num1->dial_from($uk_num2);
    my $dial_from_uk = $uk_num1->dial_from('GB');
    my $dial_from_uk = $uk_num1->dial_from('+441929 552698');

    # similarly, dialling the number from the US (011441929552699)
    my $dial_from_us = $uk_num1->dial_from($us_num);
    my $dial_from_us = $uk_num1->dial_from('US');
    my $dial_from_us = $uk_num1->dial_from('+1 203 503 1234');

=cut

sub dial_from {
  my ($self,$str_or_obj) = @_;
  $str_or_obj||=$self;
  my $from_country = $self->_get_country_from($str_or_obj);
  if ( $from_country eq $self->country ) {
    return $self->national_dial;
  }
  else {
    return $MUPHONE_DATA->{territories}->{ $from_country }->{internationalPrefix}
      .$self->country_code
      .$self->_cleaned_number;
  }
}

=head2 display_from

How to display the number for the number/country sent in as an arg. eg

    my $uk_num1 = Number::MuPhone->new({ country => 'GB', number => '01929 552699' });
    my $uk_num2 = Number::MuPhone->new({ country => 'GB', number => '01929 552698' });
    my $us_num  = Number::MuPhone->new({ country => 'US', number => '203 503 1234' });

    # these all have the same output (01929 552699)
    my $display_from_uk = $uk_num1->display_from($uk_num2);
    my $display_from_uk = $uk_num1->display_from('GB');
    my $display_from_uk = $uk_num1->display_from('+441929 552698');

    # similarly, dialling the number from the US (01144 1929 552699)
    my $display_from_us = $uk_num1->display_from($us_num);
    my $display_from_us = $uk_num1->display_from('US');
    my $display_from_us = $uk_num1->display_from('+1 203 503 1234');

=cut

sub display_from {
  my ($self,$str_or_obj) = @_;
  $str_or_obj||=$self;
  my $from_country = $self->_get_country_from($str_or_obj);
  if ( $from_country eq $self->country ) {
    return $self->national_display;
  }
  else {
    # (DIAL PREFIX) (COUNTRY CODE) (FORMATTED NUMBER) [ (EXTENSION) ]
    return $MUPHONE_DATA->{territories}->{ $from_country }->{internationalPrefix}
          .$self->country_code.' '
          .$self->_formatted_number.$self->_extension_display;
  }
}


# PRIVATE METHODS

# splits off optional extension, and cleans both up for storage
# only place where we set error
sub _process_raw_number {
  my $self = shift;

  my ($raw_num,$ext) = split $EXTENSION_REGEX, $self->number;
  $ext||='';
  $ext =~ s/\D//g;
  $self->extension($ext);

  # if number begins with a '+' we can determine country from E.123 number
  if ($raw_num =~ /^\s*\+/) {
    $self->_process_from_e123($raw_num);
  }
  # if we have a country set, clean up raw number (ie, strip national dial code, if set)
  elsif (my $country = $self->country) {
    $raw_num =~ s/\D//g;
    my $national_prefix = $MUPHONE_DATA->{territories}->{ $country }->{nationalPrefix};
    if ( defined $national_prefix ) {
      $raw_num =~ s/^$national_prefix//;
    }
    $self->_cleaned_number( $raw_num );
  }

  # if no country set by the time we get here, we need to set error and bail
  my $country = $self->country;
  unless ( $country ) {
    $self->error("Country not supplied, and I can't determine it from the number");
    return;
  }

  # Number must match the national number pattern, if exists
  my $cleaned_num = $self->_cleaned_number;
  if ( $MUPHONE_DATA->{territories}->{ $country }->{generalDesc}
       && $MUPHONE_DATA->{territories}->{ $country }->{generalDesc}->{nationalNumberPattern} ) {

      my $regex = qr/^(?:$MUPHONE_DATA->{territories}->{ $country }->{generalDesc}->{nationalNumberPattern})$/;
    unless ( $cleaned_num =~ $regex ) {
      $self->error("Number ($cleaned_num) is not valid for country ($country)");
      return;
    }
  }

  # confirm cleaned number is a valid number for the country
  unless ( $self->_cleaned_number =~ $self->_national_number_regex ) {
    $self->error("Number $raw_num is not valid for country ".$self->country);
  }

  # don't create formatted number if we have an error
  $self->error and return;

  # if no number formats, just set to the cleaned number
  my $number_formats = $MUPHONE_DATA->{territories}->{ $self->country }->{availableFormats}->{numberFormat};

  my $num = $self->_cleaned_number;
  my $national_prefix_optional=0;

  # iterate through the available formats until you get a match
  # (if not set, we default to cleaned number
  FORMAT: foreach my $format_hash (@$number_formats) {
    # not all countries have leading digit mappings
    if (my $leading_digits = $format_hash->{leadingDigits}) {
      next FORMAT unless ( $num =~ /^(?:$leading_digits)/ );
    }

    my $pattern = qr/^$format_hash->{pattern}$/;
    next FORMAT unless ( $num =~ $pattern );

    my $format = $format_hash->{format};

    my $regex_statement = "\$num =~ s/$pattern/$format/;";
    ## no critic
    eval $regex_statement;
    ## use  critic
    if ($@) {
      $self->error("Can't format number($num) with regex($regex_statement): $@");
      last FORMAT;
    }

    $national_prefix_optional = $format_hash->{nationalPrefixOptionalWhenFormatting}
                                ? 1 : 0;
    last FORMAT;
  }

  $self->_formatted_number($num);
  $self->_national_prefix_optional_when_formatting($national_prefix_optional);

}

# number starts with a + ? Great, we should be able to work it out.
sub _process_from_e123 {
  my ($self,$num) = @_;

  $num =~ s/\D//g;

  my $countries = [];

  # grab from country lookup - country code is 1-3 digits long
  my @prefixes = map { substr($num, 0, $_) } 1..3;
  PREFIX: foreach my $idd (@prefixes) {
    # we found a match
    if ($countries = $MUPHONE_DATA->{idd_codes}->{$idd}) {
      # so strip off the IDD from the number
      $num =~ s/^$idd//;
      last PREFIX;
    }
  }

  # now find out which country the number matches
  # (for IDD codes with multiple countries, this may not be correct, but should be
  # good enough for this use case - just don't rely on the country
  # TODO - maybe iterate through all regexes by number type to confirm validity?
  # generalDesc regex is too loose for (eg) US/CA
  # to implement this, we'd need to keep the various number type regexes around
  # Suggest look at adding in next update
  my $country;
  COUNTRY: foreach my $country (@$countries) {
    my $national_number_format_regex  = $MUPHONE_DATA->{territories}->{$country}->{generalDesc} && $MUPHONE_DATA->{territories}->{$country}->{generalDesc}->{nationalNumberPattern}
                                        ? qr/^$MUPHONE_DATA->{territories}->{$country}->{generalDesc}->{nationalNumberPattern}$/
                                        : '';
    $national_number_format_regex
      or next COUNTRY;

    $num =~ $national_number_format_regex
      or next COUNTRY;

    $self->country($country);
    $self->_cleaned_number($num);
  }

}

=head1 A WARNING ABOUT INFERRED COUNTRIES

If you instantiate an object with an E.123 formatted number, the inferred country will be
the 'main' country for that number. This is because Number::MuPhone is currently using the
loosest regex available to validate a number for a country (this may change soon). This
affects these country codes:

    Code       Main Country
    ====       ============
    1          US
    44         GB
    212        EH
    61         CC
    590        MF
    7          KZ
    599        BQ
    47         SJ
    262        YT

As far as functionality is concerned, you should see no difference, unless you want to use
the country() attribute. To avoid this, instantiate with both number and country.

=head1 KEEPING UP TO DATE WITH CHANGES IN THE SOURCE XML FILE

The data used to validate and format the phone numbers comes from Google's libphonenumber:

L<https://github.com/google/libphonenumber/releases/latest>

This distribution should come with a reasonably recent copy of the libphonenumber source XML,
but you can also set up a cron to update your source data weekly, to ensure you don't have
problems with new area codes as they get added (this happens probably more often than you think).

By default, C<Number::MuPhone>'s update script (perl-muphone-build-data) stores this data in the
~/.muphone directory, but you can overload this by setting the C<MUPHONE_BASE_DIR> environment
variable. Wherever you choose, it must be writeable by the user, and remember to expose the same
C<ENV> var to any scripts using C<Number::MuPhone> (if needed).

When run, the following files are created in the C<~/.muphone> or C<$ENV{MUPHONE_BASE_DIR}> dirs as appropriate

    ./etc/PhoneNumberMetadata.xml     # the libphonenumber source XML file
    ./lib/NumberMuPhoneData.pm        # the generated Number::MuPhone::Data
    ./t/check_data_module.t           # a little sanity script that runs after creating the data file

Currently, the extractor script only grabs the data we need, and removes spacing, to keep the size down.

If you want to examine all available data, set C<$DEBUG=1> (add in padding, switch commas to =>) and set
C<$STRIP_SUPERFLUOUS_DATA=0> in the script and run it again. then look at the generated C<NumberMuPhoneData.pm>

=head2 Initial run

Optionally, set the C<MUPHONE_BASE_DIR> environment variable to point to your config directory (must be writeable).
Otherwise, C<~/.muphone> will get used (default).

As the appropriate user, run:

    perl-muphone-build-data

Confirm the tests pass and the files are created (if no error output, tests passed, and all should be good).

=head2 Set up the cron to run weekly to update the data

    # using default data dir (~/.muphone)
    0 5 * * 1 /usr/local/bin/perl-muphone-build-data

    # using user specific data dir
    0 5 * * 1 MUPHONE_BASE_DIR=/path/to/config /usr/local/bin/perl-muphone-build-data

=head2 Dockerfile config

Similarly, add the C<perl-muphone-build-data> script to your Dockerfile, as appropriate. If you're using
Kubernetes, this might be enough, but for longer running Docker instances, you might want to
consider setting up the cronjob within the image too.

If anyone has best practice recommendations for this, let me know and I'll update the POD :D

=cut


1;
