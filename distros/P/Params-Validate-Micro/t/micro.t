#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use Params::Validate::Micro qw(:all);
use Params::Validate qw(:types);

sub micro_is {
  my $spec = shift;
  $spec = ref($spec) eq 'ARRAY' ? $spec : [ $spec ];
  is_deeply(
    { micro_translate(@$spec) },
    shift,
    shift,
  );
}

micro_is(
  q{},
  { },
  'empty spec string',
);

micro_is(
  q{$text},
  { text => { type => SCALAR | OBJECT } },
  'single scalar',
);

micro_is(
  q{@arr; %hash},
  {
    arr => { type => ARRAYREF },
    hash => { type => HASHREF, optional => 1 },
  },
  'array and optional hash',
);

micro_is(
  [ q{foo}, { foo => { can => "bar" } } ],
  { foo => { can => "bar" } },
  'merging with extra and no string',
);

# check for order
is_deeply(
  [ micro_translate(q{foo bar baz quux}) ],
  [ foo => 1, bar => 1, baz => 1, quux => 1 ],
  'order from micro_translate',
);

eval {
  micro_translate(q{$foo; $bar; $baz});
};
like($@, qr/multiple semicolons/,
     "multiple semicolons");

eval {
  micro_validate(
    { foo => bless({}, "Foo") },
    '$foo',
  );
};
is($@, "", "validate with object");

eval {
  micro_validate(
    { foo => 1 },
    '$foo; $bar',
  );
};
is($@, "", "validate with optional");

eval {
  micro_validate(
    { foo => 1 },
    q{$foo},
    {
      foo => {
        callbacks => {
          'more than 1' => sub {
            shift > 1
          },
        },
      },
    },
  );
};
like($@, qr/did not pass.+more than 1/,
     "validate with extra");

eval {
  micro_validate(
    { },
    q{; foo},
    {
      foo => { type => SCALAR },
    },
  );
};
is($@, "", "validate with extra (merge)");

eval { micro_validate([], q{foo}) };
like($@, qr/not enough arguments for 'foo'/, "validate with empty arrayref");
