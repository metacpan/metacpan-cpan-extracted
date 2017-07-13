use strictures 2;
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

done_testing();
