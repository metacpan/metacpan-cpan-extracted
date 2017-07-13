use strictures 2;
use Test::More;

use Number::MuPhone::Parser::US;

################################################################################
# test various valid and invalid US numbers
################################################################################

for my $number('+1 203 503 1111','1 203 503 1111','203 503 1111') {
  diag "Processing $number";
  my $num = Number::MuPhone::Parser::US->new({
    number => $number,
  });
  isa_ok($num,'Number::MuPhone::Parser::US');
  ok( ! $num->error, 'No error' );

  is( $num->country,                    'US'              ,'country' );
  is( $num->country_code,               '1'               ,'country_code');
  is( $num->_cleaned_number,            '2035031111'      ,'_cleaned_number');
  is( $num->_international_dial_prefix, '011'             ,'_international_dial_prefix');
  is( $num->_national_dial_prefix,      '1'               ,'_national_dial_prefix');
  is( $num->_formatted_number,          '203 503 1111'    ,'_formatted_number');
  is( $num->_national_display,          '(203) 503-1111'  ,'_national_display');
  is( $num->international_display ,     '+1 203 503 1111' ,'international_display');
  is( $num->dial_from($num),            '12035031111'     ,'national_dial');
  is( $num->international_dial,         '+12035031111'    ,'international_dial');
  is( $num->dial,                       '12035031111',    ,'national dial');
}

diag "num with extension";
{
  my $num = Number::MuPhone::Parser::US->new({ number => '+12035031111 ext 1111' });
  isa_ok($num,'Number::MuPhone::Parser::US');
  is( $num->extension, '1111', 'Extension (1)' );
  is( $num->display, '(203) 503-1111 ext 1111', 'Display w Extension (1)' );
  is( $num->dial, '12035031111,1111', 'Dial w Extension (1)' );
  ok( ! $num->error, 'No error');
}

{
  my $num = Number::MuPhone::Parser::US->new({ number => '+12035031111 extension 1111' });
  isa_ok($num,'Number::MuPhone::Parser::US');
  is( $num->extension, '1111', 'Extension (2)' );
  is( $num->display, '(203) 503-1111 ext 1111', 'Display w Extension (2)' );
  is( $num->dial, '12035031111,1111', 'Dial w Extension (2)' );
  ok( ! $num->error, 'No error');
}

{
  my $num = Number::MuPhone::Parser::US->new({ number => '+12035031111 x1111' });
  isa_ok($num,'Number::MuPhone::Parser::US');
  is( $num->extension, '1111', 'Extension (3)' );
  is( $num->display, '(203) 503-1111 ext 1111', 'Display w Extension (3)' );
  is( $num->dial, '12035031111,1111', 'Dial w Extension (3)' );
  ok( ! $num->error, 'No error');
}

{
  my $num = Number::MuPhone::Parser::US->new({ number => '+12035031111 *1111' });
  isa_ok($num,'Number::MuPhone::Parser::US');
  is( $num->extension, '1111', 'Extension (4)' );
  is( $num->display, '(203) 503-1111 ext 1111', 'Display w Extension (4)' );
  is( $num->dial, '12035031111,1111', 'Dial w Extension (4)' );
  ok( ! $num->error, 'No error');
}

diag "Process bad number";
{
  my $bad_num = Number::MuPhone::Parser::US->new({
    number => '222 2222 2222',
  });
  ok( $bad_num->error, 'Is bad num');
}

done_testing();
