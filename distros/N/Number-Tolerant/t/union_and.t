use Test::More tests => 39;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }
BEGIN { use_ok("Number::Tolerant::Union"); }

{
  my $alpha = Number::Tolerant->new(5 => to => 10);
  my $beta  = Number::Tolerant->new(7 => to => 15);

  isa_ok($alpha, 'Number::Tolerant');
  isa_ok($beta,  'Number::Tolerant');

  my $choice = $alpha | $beta;

  isa_ok($choice,   'Number::Tolerant::Union', 'union');

  ok( 4 != $choice, ' ...  4 != $choice');
  ok( 5 == $choice, ' ...  5 == $choice');
  ok( 9 == $choice, ' ...  9 == $choice');
  ok(11 == $choice, ' ... 11 == $choice');
  ok(15 == $choice, ' ... 15 == $choice');
  ok(16 != $choice, ' ... 16 != $choice');

  my $gamma = Number::Tolerant->new(8 => to => 11);

  isa_ok($gamma, 'Number::Tolerant');

  my $limited = $choice & $gamma;

  ok(            1, ' ... survived union');

  ok( 4 != $limited, ' ...  4 != $limited');
  ok( 5 != $limited, ' ...  5 != $limited');
  ok( 9 == $limited, ' ...  9 == $limited');
  ok(11 == $limited, ' ... 11 == $limited');
  ok(15 != $limited, ' ... 15 != $limited');
  ok(16 != $limited, ' ... 16 != $limited');
}

{
  my $alpha = Number::Tolerant->new(5 => to => 10);
  my $beta  = Number::Tolerant->new(7 => to => 15);

  isa_ok($alpha, 'Number::Tolerant');
  isa_ok($beta,  'Number::Tolerant');

  my $choice = $alpha | $beta;

  isa_ok($choice,   'Number::Tolerant::Union', 'union');

  ok( 4 != $choice, ' ...  4 != $choice');
  ok( 5 == $choice, ' ...  5 == $choice');
  ok( 9 == $choice, ' ...  9 == $choice');
  ok(11 == $choice, ' ... 11 == $choice');
  ok(15 == $choice, ' ... 15 == $choice');
  ok(16 != $choice, ' ... 16 != $choice');

  my $limited = $choice & 10;

  ok(            1, ' ... survived union');

  ok( 4 != $limited, ' ...  4 != $limited');
  ok( 5 != $limited, ' ...  5 != $limited');
  ok( 9 != $limited, ' ...  9 != $limited');
  ok(10 == $limited, ' ... 10 == $limited');
  ok(11 != $limited, ' ... 11 != $limited');
  ok(15 != $limited, ' ... 15 != $limited');
  ok(16 != $limited, ' ... 16 != $limited');
}

{
  my $alpha = Number::Tolerant->new(5 => to => 10);
  my $beta  = Number::Tolerant->new(7 => to => 15);

  isa_ok($alpha, 'Number::Tolerant');
  isa_ok($beta,  'Number::Tolerant');

  my $choice = $alpha | $beta;

  my $limited = $choice & 100;

  is($limited, undef, " ... choice and this union is undef");
}
