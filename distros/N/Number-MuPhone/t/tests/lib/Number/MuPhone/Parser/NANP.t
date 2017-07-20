use 5.012;
use Test::More;

use Number::MuPhone::Parser::NANP;

########################################
# test various valid and invalid non identifiable North American  numbers
########################################

for my $number('+1 990 503 1111','1 990 503 1111','990 503 1111') {
  diag "Processing $number";
  my $num = Number::MuPhone::Parser::NANP->new({
    number => $number,
  });
  isa_ok($num,'Number::MuPhone::Parser::NANP');
  ok( ! $num->error, 'No error: '.$num->error );

  is( $num->country,                   'NANP'            ,'country' );
  is( $num->country_code,              '1'               ,'country_code');
  is( $num->_cleaned_number,            '9905031111'      ,'_cleaned_number');
  is( $num->_international_dial_prefix, '011'             ,'international_prefix');
  is( $num->_national_dial_prefix,      '1'               ,'national_prefix');
  is( $num->_formatted_number,          '990 503 1111'    ,'formatted number');
  is( $num->_national_display,          '(990) 503-1111'  ,'national_format');
  is( $num->international_display,     '+1 990 503 1111' ,'international_format');
}

diag "Process bad number";
{
  my $bad_num = Number::MuPhone::Parser::NANP->new({
    number => '990 2222 2222',
  });
  ok( $bad_num->error, 'Is bad num');
}

done_testing();
