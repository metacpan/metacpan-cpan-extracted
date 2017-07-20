use 5.012;
use Test::More;

use Number::MuPhone;
use Number::MuPhone::Parser;

# no args, missing number
{
  my $num = Number::MuPhone::Parser->new();
  is( $num->error, "'number' is required", 'Valid Error' );
}

# no country, missing country (usually subclassed, so not an issue)
 {
  my $num = Number::MuPhone::Parser->new({number => 12345});
  is( $num->error, "'country' is required", 'Missing country' );
}

# we only really use this special case to get mets info on a specific country
{
  my $num = Number::MuPhone->new({country => 'US'});
  is( $num->error, "'number' is required", 'Missing number' );
  is( $num->country_code, '1', 'Valid country code' );
  is( $num->_international_dial_prefix, '011', 'Valid dial prefix');
}

# How we display a number depends on where we are and where we're calling
{
  my $uk_num = Number::MuPhone->new('+441929552619');
  my $us_num = Number::MuPhone->new('+12035031111');

  # show UK num in UK: 01929 552619
  is( $uk_num->display,                       '01929 552619',         'Display UK number in UK 1');
  is( $uk_num->display_from($uk_num),         '01929 552619',         'Display UK number in UK 2');
  is( $uk_num->display_from('+441929552619'), '01929 552619',         'Display UK number in UK 3');
  is( $uk_num->display_from('UK'),            '01929 552619',         'Display UK number in UK 4');
  is( $uk_num->dial,                          '01929552619',          'Dial UK number in UK 1');
  is( $uk_num->dial_from($uk_num),            '01929552619',          'Dial UK number in UK 2');
  is( $uk_num->dial_from('+441929552619'),    '01929552619',          'Dial UK number in UK 3');
  is( $uk_num->dial_from('UK'),               '01929552619',          'Dial UK number in UK 4');
  is( $uk_num->E164,                          '+441929552619',        'UK number in E.164 format');
  is( $uk_num->E123,                          '+44 1929 552619',      'UK number in E.123 format');

  # UK num from US: 01144 1929 552619
  is( $uk_num->display_from($us_num),         '011 44 1929 552619',   'Display UK number in US 1');
  is( $uk_num->display_from('+12035031111'),  '011 44 1929 552619',   'Display UK number in US 2');
  is( $uk_num->display_from('US'),            '011 44 1929 552619',   'Display UK number in US 3');
  is( $uk_num->dial_from($us_num),            '011441929552619',      'Dial UK number from US 1');
  is( $uk_num->dial_from('+12035031111'),     '011441929552619',      'Dial UK number from US 2');
  is( $uk_num->dial_from('US'),               '011441929552619',      'Dial UK number from US 3');

  # show US num in US: (203) 503-1111
  is( $us_num->display,                       '(203) 503-1111',       'Display US number in US 1');
  is( $us_num->display_from($us_num),         '(203) 503-1111',       'Display US number in US 2');
  is( $us_num->display_from('+12035031111'),  '(203) 503-1111',       'Display US number in US 3');
  is( $us_num->display_from('US'),            '(203) 503-1111',       'Display US number in US 4');
  is( $us_num->E164,                          '+12035031111',         'US number in E.164 format');
  is( $us_num->E123,                          '+1 203 503 1111',      'US number in E.123 format');

  # US num from UK: 001 (203) 503-1111
  is( $us_num->display_from($uk_num),         '001 203 503 1111',     'Display US number in UK 1');
  is( $us_num->display_from('+441929552619'), '001 203 503 1111',     'Display US number in UK 2');
  is( $us_num->display_from('UK'),            '001 203 503 1111',     'Display US number in UK 3');
  is( $us_num->dial_from($uk_num),            '0012035031111',        'Dial US number from UK 1');
  is( $us_num->dial_from('+441929552619'),    '0012035031111',        'Dial US number from UK 2');
  is( $us_num->dial_from('UK'),               '0012035031111',        'Dial US number from UK 3');

}

done_testing();
