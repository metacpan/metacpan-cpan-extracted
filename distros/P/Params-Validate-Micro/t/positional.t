#!perl

use Test::More 'no_plan';

BEGIN { use_ok('Params::Validate::Micro', ':all'); }

is_deeply(
  micro_validate([ 10, 20, 30 ], '$a $b $c'),
  { a => 10, b => 20, c => 30 },
  "basic three-scalar positional params",
);

is_deeply(
  micro_validate([ 10, [ 20 ], {3=>0} ], '$a @b %c'),
  { a => 10, b => [ 20 ], c => {3=>0} },
  "basic different-typed positional params",
);

is_deeply(
  micro_validate([ 10, [ 20 ], 30 ], 'a  b $c'),
  { a => 10, b => [ 20 ], c => 30 },
  "basic different-typed positional params with untypeds",
);

is_deeply(
  micro_validate([ ], q{}),
  { },
  "empty micro-signature validates empty list, provides {}",
);

is_deeply(
  micro_validate(undef, q{}),
  { },
  "empty micro-signature validates undef, provides {}",
);

is_deeply(
  micro_validate([ 1, 2, 3, 4, 5 ], q{$a $b $c d; e $f %g}),
  { qw(a 1 b 2 c 3 d 4 e 5) },
  "positional validation with optionals provided should work",
);

eval { micro_validate([ 10, [ 20 ], {3=>0} ], 'a  b $c'); };
ok($@, q{shouldn't validate: third arg wants $ but got %});

eval { micro_validate([ 1, 2, 3, 4, [5] ], q{$a $b $c d; $e $f %g}); };
ok($@, q{shouldn't validate: first optional arg wants $ but got @});

eval { micro_validate([ 1 ], '') };
like($@, qr/too many arguments/, "argument overrun");

eval { micro_validate([ ], '$text') };
like($@, qr/not enough arguments/, "argument underrun");
