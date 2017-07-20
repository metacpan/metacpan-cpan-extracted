use 5.012;
use Test::More;

use Number::MuPhone::Parser::UK;

########################################
# test various valid and invalid UK numbers
########################################

for my $number('+44 1929 552619','01929 552619') {
  diag "Processing $number";
  my $num = Number::MuPhone::Parser::UK->new({
    number => $number,
  });
  isa_ok($num,'Number::MuPhone::Parser::UK');
  ok( ! $num->error, 'No error' );

  is( $num->country,                    'UK'              ,'country' );
  is( $num->country_code,               '44'              ,'country_code');
  is( $num->_cleaned_number,            '1929552619'      ,'_cleaned_number');
  is( $num->_international_dial_prefix, '00'              ,'international_prefix');
  is( $num->_national_dial_prefix,      '0'               ,'national_prefix');
  is( $num->_formatted_number,          '1929 552619'     ,'format');
  is( $num->_national_display,          '01929 552619'    ,'_national_display');
  is( $num->dial_from($num),            '01929552619'     ,'national_dial');
  is( $num->international_display ,     '+44 1929 552619' ,'international_display');
  is( $num->international_dial,         '+441929552619'   ,'international_dial');
}

for my $number('+44 20 1234 1234','020 1234 1234') {
  diag "Processing $number";
  my $num = Number::MuPhone::Parser::UK->new({
    number => $number,
  });
  isa_ok($num,'Number::MuPhone::Parser::UK');
  ok( ! $num->error, 'No error' );

  is( $num->_cleaned_number,        '2012341234'       ,'_cleaned_number');
  is( $num->_formatted_number,      '20 1234 1234'     ,'format');
  is( $num->_national_display,      '020 1234 1234'    ,'_national_display');
  is( $num->dial_from($num),        '02012341234'      ,'national_dial');
  is( $num->international_display,  '+44 20 1234 1234' ,'international_display');
  is( $num->international_dial,     '+442012341234'    ,'international_dial');
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '0911 1111111'});
  is( $num->_formatted_number, '911 111 1111', '09XX XXXXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '0811 1111111'});
  is( $num->_formatted_number, '811 111 1111', '08XX XXXXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '0800 111111'});
  is( $num->_formatted_number, '800 111111', '0800 XXXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '07111 111111'});
  is( $num->_formatted_number, '7111 111111', '07XXX XXXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '05111 111111'});
  is( $num->_formatted_number, '5111 111111', '05XXX XXXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '0311 111 1111'});
  is( $num->_formatted_number, '311 111 1111', '03XX XXX XXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '019467 11111'});
  is( $num->_formatted_number, '19467 11111', '019467 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '017687 11111'});
  is( $num->_formatted_number, '17687 11111', '017687 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '017684 11111'});
  is( $num->_formatted_number, '17684 11111', '017684 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '017683 11111'});
  is( $num->_formatted_number, '17683 11111', '017683 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '016977 11111'});
  is( $num->_formatted_number, '16977 11111', '016977 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '016977 1111'});
  is( $num->_formatted_number, '16977 1111', '016977 XXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '016974 11111'});
  is( $num->_formatted_number, '16974 11111', '016974 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '016973 11111'});
  is( $num->_formatted_number, '16973 11111', '016973 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '015396 11111'});
  is( $num->_formatted_number, '15396 11111', '015396 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '015395 11111'});
  is( $num->_formatted_number, '15395 11111', '015395 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '015394 11111'});
  is( $num->_formatted_number, '15394 11111', '015394 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '015242 11111'});
  is( $num->_formatted_number, '15242 11111', '015242 XXXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '0131 111 1111'});
  is( $num->_formatted_number, '131 111 1111', '0131 XXX XXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '0113 111 1111'});
  is( $num->_formatted_number, '113 111 1111', '0113 XXX XXXX' );
}

{
  my $num = Number::MuPhone::Parser::UK->new({ number => '01929 552619'});
  is( $num->_formatted_number, '1929 552619', '01XXX XXXXXX' );
}

diag "Bad numbers";
{
  my $bad_num = Number::MuPhone::Parser::UK->new({
    number => '01929 5552619',
  });
  ok( $bad_num->error, 'Is bad num');
}

{
  # no numbers begin 04
  my $bad_num = Number::MuPhone::Parser::UK->new({
    number => '04929 5552619',
  });
  ok( $bad_num->error, 'Is bad num');
}

{
  # no numbers begin 06
  my $bad_num = Number::MuPhone::Parser::UK->new({
    number => '06929 5552619',
  });
  ok( $bad_num->error, 'Is bad num');
}


done_testing();
