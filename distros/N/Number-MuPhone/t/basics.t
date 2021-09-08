use v5.020;
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Number::MuPhone;
use Data::Dumper 'Dumper';

# bad number with country code
{
  my $num = Number::MuPhone->new({
    number  => '003 503 1234',
    country => 'US',
  });
  ok( $num->error, 'Error set: '.$num->error);
}

# instantiation with single arg (must be E.123)
{
  my $num = Number::MuPhone->new('+1 203 503 1199');
  is( $num->country, 'US','Single Arg US Number');
}

{
  my $num = Number::MuPhone->new('+44 1929 552699');
  is( $num->country, 'GB', 'iSingle arg GB Number');
}

# double arg instantiation (num, country)
{
  my $num = Number::MuPhone->new('203 503 1199', 'US');
  is( $num->country, 'US', 'Double arg US Number');
}
# double arg instantiation (num, country) - bad number for country
{
  my $num = Number::MuPhone->new('01929 552619', 'US');
  ok( $num->error, 'Bad nnum/country combo throws an error: '.$num->error);
}

# sledgehammer check everything
{
  my $num = Number::MuPhone->new({
    number => '203 503 1234',
    country => 'US',
  });

  isa_ok($num,'Number::MuPhone');
  is($num->number,                                    '203 503 1234',          'number set' );
  is($num->country,                                   'US',                    'country set' );
  is($num->_cleaned_number,                           '2035031234',            'cleaned number' );
  is($num->country_name,                              'United States',         'full country name' );
  is($num->_formatted_number,                          '(203) 503-1234',       'formatted number' );
  is($num->_national_prefix_optional_when_formatting,  1,                      'National dial prefix optional bool' );
  is($num->_national_dial_prefix,                      1,                      'National dial prefix' );
  is($num->national_display,                           '(203) 503-1234',       'National display' );
  is($num->international_display,                      '+1 (203) 503-1234',    'International display' );
  is($num->e164_no_ext,                                '+12035031234',         'e164 no ext');
  is($num->e164,                                       '+12035031234',         'e164');
  
}

# US with explicit country code
{
  my $num = Number::MuPhone->new({
    number => '+1 203 503 1234',
  });
  is($num->country,         'US',         'country set' );
  is($num->_cleaned_number, '2035031234', 'cleaned number' );
}

diag "try various GB formats";
{
  my $num = Number::MuPhone->new({
    number => '+44 1929 552699'
  });
  is($num->country,                                  'GB',                   'country set');
  is($num->_cleaned_number,                          '1929552699',          'cleaned number' );
  is($num->country_name,                             'United Kingdom',      'full country name' );
  is($num->country_code,                              44,                   'country code' );
  is($num->_formatted_number,                         '1929 552699',        'formatted number' );
  is($num->_national_dial_prefix,                     '0',                  'National dial prefix' );
  is($num->_national_prefix_optional_when_formatting, 0,                    'National dial prefix optional bool' );
  is($num->_national_dial_prefix,                     0,                    'National dial prefix' );
  is($num->national_display,                          '01929 552699',       'National display' );
  is($num->international_display,                     '+44 1929 552699',    'International display' );
  is($num->e164_no_ext,                               '+441929552699',      'e164 no ext');
  is($num->e164,                                      '+441929552699',      'e164');
}

{
  my $num = Number::MuPhone->new({
    number  => '01929 552699',
    country => 'GB',
  });
  is($num->country,               'GB',                   'country set');
  is($num->_cleaned_number,       '1929552699',           'cleaned number' );
  is($num->country_name,          'United Kingdom',       'full country name' );
  is($num->country_code,          44,                     'country code' );
  is($num->display_from('US'),    '01144 1929 552699',    'Display from US' );
  is($num->display_from('GB'),    '01929 552699',         'Display from GB' );
  is($num->dial_from('US'),       '011441929552699',      'Dial from US' );
  is($num->dial_from('GB'),       '01929552699',          'Dial from GB' );
}

# bad UK number (too long)
{
  my $num = Number::MuPhone->new({
    number  => '01929 5526999',
    country => 'GB',
  });
  ok($num->error, "Bad GB number: ".$num->error );
}

diag "Number with extension";
{
  my $num = Number::MuPhone->new({
    number  => '203 503 1234 x 12345',
    country => 'US',
  });
  is($num->_cleaned_number,       '2035031234',                      'Number extracted' );
  is($num->extension,             '12345',                           'Extension extracted' );
  is($num->_extension_display,    ' ext 12345',                      'Extension display' );
  is($num->national_display,      '(203) 503-1234 ext 12345',        'National display' );
  is($num->international_display, '+1 (203) 503-1234 ext 12345',     'International display' );
  is($num->e164_no_ext,           '+12035031234',                    'e164 no ext' );
  is($num->e164,                  '+12035031234;ext=12345',          'e164' );
  is($num->display_from('US'),    '(203) 503-1234 ext 12345',        'Display from US' );
  is($num->display_from('GB'),    '001 (203) 503-1234 ext 12345',    'Display from GB' );
  is($num->dial_from('US'),       '2035031234,,,12345',              'Dial from US' );
}

diag "check dial/display from for two separate numbers";
{
  my $num_us = Number::MuPhone->new({ number  => '203 503 1234', country => 'US', });
  my $num_gb = Number::MuPhone->new({ number  => '01929 552699', country => 'GB', });
  is ($num_us->dial_from( $num_gb ),    '0012035031234',       'dial US num from GB' );
  is ($num_us->dial_from( $num_us ),    '2035031234',          'dial US num from US' );
  is ($num_gb->dial_from( $num_us ),    '011441929552699',     'dial GB num from US' );
  is ($num_gb->dial_from( $num_gb ),    '01929552699',         'dial GB num from GB' );
  is ($num_us->display_from( $num_gb ), '001 (203) 503-1234',  'display US num from GB' );
  is ($num_us->display_from( $num_us ), '(203) 503-1234',      'display US num from US' );
  is ($num_gb->display_from( $num_us ), '01144 1929 552699',   'display GB num from US' );
  is ($num_gb->display_from( $num_gb ), '01929 552699',        'display GB num from GB' );
}

diag "Check various GB formats";
{
  my $num = Number::MuPhone->new({ number  => '015395 63987', country => 'GB', });
  is( $num->national_display, '015395 63987', 'Cumbrian number'),
}
{
  my $num = Number::MuPhone->new({ number  => '02073238299', country => 'GB', });
  is( $num->national_display, '020 7323 8299', 'London number'),
}
{
  my $num = Number::MuPhone->new({ number  => '0120461123', country => 'GB', });
  is( $num->national_display, '01204 61123', 'Bolton number'),
}
{
  my $num = Number::MuPhone->new({ number  => '01211234567', country => 'GB', });
  is( $num->national_display, '0121 123 4567', 'Birmingham number'),
}

#ok($num->_global_config->{possible_countries});
#is($num->_national_dial_prefix, '1');

#is($num->country, 'US');


#  is( $num->country_code,               '1'                 ,'country_code');

done_testing(); exit(0);

__DATA__
my @test_us_numbers = ('+1 203 503 1111','1 203 503 1111','203 503 1111');

done_testing();
