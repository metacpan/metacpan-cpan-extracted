use 5.012;
use Test::More;

use Number::MuPhone::Parser::CA;

########################################
# test various valid and invalid UK numbers
########################################

for my $number('+1 204 503 1111','1 204 503 1111','204 503 1111') {
  diag "Processing $number";
  my $num = Number::MuPhone::Parser::CA->new({
    number => $number,
  });
  isa_ok($num,'Number::MuPhone::Parser::CA');
  ok( ! $num->error, 'No error' );

  is( $num->country,                   'CA'              ,'country' );
  is( $num->country_code,              '1'               ,'country_code');
  is( $num->_cleaned_number,            '2045031111'      ,'_cleaned_number');
  is( $num->_international_dial_prefix, '011'             ,'international_prefix');
  is( $num->_national_dial_prefix,      '1'               ,'national_prefix');
  is( $num->_formatted_number,          '204 503 1111'    ,'format');
  is( $num->_national_display,          '(204) 503-1111'  ,'national_format');
  is( $num->international_display,     '+1 204 503 1111' ,'international_format');
}

diag "Bad number";
{
  my $bad_num = Number::MuPhone::Parser::US->new({
    number => '204 2222 2222',
  });
  ok( $bad_num->error, 'Is bad num');
}

done_testing();
