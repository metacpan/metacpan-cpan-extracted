use 5.012;
use Test::More;
use lib 'lib';

use Number::MuPhone;

# just instantiation tests

{ # no args
  my $num = Number::MuPhone->new();
  isa_ok($num,'Number::MuPhone::Parser');
  is( $num->error, "'number' is required", 'Got error');
}

{ # no number
  my $num = Number::MuPhone->new({ country => 'US' });
  isa_ok($num,'Number::MuPhone::Parser');
  is( $num->error, "'number' is required", 'Got error');
}

{ # E.164
  my $num = Number::MuPhone->new({ number => '+12035031111'});
  isa_ok($num,'Number::MuPhone::Parser::US');
  ok( ! $num->error, 'No error');
}

{ # local num + country
  my $num = Number::MuPhone->new({ number => '203 503 1111',country=>'US'});
  isa_ok($num,'Number::MuPhone::Parser::US');
  ok( ! $num->error, 'No error');
}

{ # number with extension
  my $num = Number::MuPhone->new({ number => '+12035031111 ext 1111' });
  isa_ok($num,'Number::MuPhone::Parser::US');
  is( $num->extension, '1111', 'Extension' );
  is( $num->display, '(203) 503-1111 ext 1111', 'Display w Extension' );
  is( $num->dial, '12035031111,1111', 'Dial w Extension' );
  ok( ! $num->error, 'No error');
}


{ # Number::Phone style instantiation (1)
  my $num = Number::MuPhone->new('+12035031111');
  isa_ok($num,'Number::MuPhone::Parser::US');
  ok( ! $num->error, 'No error');
}

{ # Number::Phone style instantiation (2)
  my $num = Number::MuPhone->new('US', '+12035031111');
  isa_ok($num,'Number::MuPhone::Parser::US');
  ok( ! $num->error, 'No error');
}


{ # Call Canadian number from US number - confirm treated as local
  my $num_us = Number::MuPhone->new('+13104524522');
  my $num_ca = Number::MuPhone->new('+12042042044');
  is( $num_us->country, 'US', 'Got US number');
  is( $num_ca->country, 'CA', 'Got CA number');

  is( $num_us->dial_from($num_ca),     '13104524522',     'Dial US from CA' );
  is( $num_us->display_from($num_ca),  '(310) 452-4522',  'Display US from CA' );

}

{ # correctly throw an error when we can't identify the country code
  my $weird_num_from_us = Number::MuPhone->new({ number => '+01161396694916' });
  is (
    $weird_num_from_us->error,
    "Invalid country code - no country code begins with a zero",
    "international dial number with erroneous plus"
  );

  # 89 is not a valid country code
  my $weird_num_from_us2 = Number::MuPhone->new({ number => '+899396694916' });
  is (
    $weird_num_from_us2->error,
    "Invalid country code - could not determine country",
    "international dial number with erroneous country code"
  );
}

done_testing();
