{

  package MooX::Types::MooseLike::Numeric::Test;
  use strict;
  use warnings FATAL => 'all';
  use Moo;
  use MooX::Types::MooseLike::Numeric qw(:all);

  has 'a_positive_number' => (
    is  => 'ro',
    isa => PositiveNum,
    );
  has 'a_nonnegative_number' => (
    is  => 'ro',
    isa => PositiveOrZeroNum,
    );
  has 'a_positive_integer' => (
    is  => 'ro',
    isa => PositiveInt,
    );
  has 'a_nonnegative_integer' => (
    is  => 'ro',
    isa => PositiveOrZeroInt,
    );
  has 'a_negative_number' => (
    is  => 'ro',
    isa => NegativeNum,
    );
  has 'a_nonpositive_number' => (
    is  => 'ro',
    isa => NegativeOrZeroNum,
    );
  has 'a_negative_integer' => (
    is  => 'ro',
    isa => NegativeInt,
    );
  has 'a_nonpositive_integer' => (
    is  => 'ro',
    isa => NegativeOrZeroInt,
    );
  has 'a_single_digit' => (
    is  => 'ro',
    isa => SingleDigit,
    );

}
{

  package main;
  use strict;
  use warnings FATAL => 'all';
  use Test::More;
  use Test::Fatal;
  use IO::Handle;
  use MooX::Types::MooseLike::Numeric qw(:all);

  ok(is_PositiveNum(1),           'is_PositiveNum');
  ok(!is_PositiveNum(0),          'is_PositiveNum fails on zero');
  ok(is_PositiveOrZeroNum(3.142), 'is_PositiveOrZeroNum');
  ok(!is_PositiveOrZeroNum(-1),   'is_PositiveOrZeroNum fails on -1');
  ok(is_PositiveInt(1),           'is_PositiveInt');
  ok(!is_PositiveInt(0),          'is_PositiveInt fails on zero');
  ok(is_PositiveOrZeroInt(0),     'is_PositiveOrZeroInt');
  ok(!is_PositiveOrZeroInt(-1),   'is_PositiveOrZeroInt fails on -1');

  ok(is_NegativeNum(-1),           'is_NegativeNum');
  ok(!is_NegativeNum(0),           'is_NegativeNum fails on zero');
  ok(is_NegativeOrZeroNum(-3.142), 'is_NegativeOrZeroNum');
  ok(!is_NegativeOrZeroNum(1),     'is_NegativeOrZeroNum fails on 1');
  ok(is_NegativeInt(-1),           'is_NegativeInt');
  ok(!is_NegativeInt(0),           'is_NegativeInt fails on zero');
  ok(is_NegativeOrZeroInt(0),      'is_NegativeOrZeroInt');
  ok(!is_NegativeOrZeroNum(1),     'is_NonPositiveNum fails on 1');

## PositiveNum
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_positive_number => 1),
    'PositiveNum');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_positive_number => undef);
    },
    qr/is not a positive number/,
    'undef is an exception when we want a positive number'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_positive_number => '');
    },
    qr/is not a positive number/,
    'empty string is an exception when we want a positive number'
    );

## PositiveOrZeroNum
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_nonnegative_number => 0),
    'PositiveOrZeroNum');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonnegative_number => -1);
    },
    qr/is not a positive number or zero/,
    '-1 is an exception when we want a non-negative number'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonnegative_number => undef);
    },
    qr/is not a positive number or zero/,
    'undef is an exception when we want a non-negative number'
    );

## PositiveInt
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_positive_integer => 1),
    'PositiveInt');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_positive_integer => '');
    },
    qr/is not a positive integer/,
    'empty string is an exception when we want a positive integer'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_positive_integer => undef);
    },
    qr/is not a positive integer/,
    'undef is an exception when we want a positive integer'
    );

## PositiveOrZeroInt
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_nonnegative_integer => 0),
    'PositiveOrZeroInt');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonnegative_integer => -1);
    },
    qr/is not a positive integer or zero/,
    '-1 is an exception when we want a non-negative integer'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonnegative_integer => undef);
    },
    qr/is not a positive integer or zero/,
    'undef is an exception when we want a non-negative integer'
    );

## NegativeNum
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_negative_number => -11),
    'NegativeNum');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_negative_number => '');
    },
    qr/is not a negative number/,
    'empty string is an exception when we want a negative number'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_negative_number => undef);
    },
    qr/is not a negative number/,
    'undef is an exception when we want a negative number'
    );

## NegativeOrZeroNum
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_nonpositive_number => 0),
    'NegativeOrZeroNum');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonpositive_number => 1);
    },
    qr/is not a negative number or zero/,
    '1 is an exception when we want a non-negative number'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonpositive_number => undef);
    },
    qr/is not a negative number or zero/,
    'undef is an exception when we want a non-negative number'
    );

## NegativeInt
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_negative_integer => -1),
    'NegativeInt');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_negative_integer => '');
    },
    qr/is not a negative integer/,
    'empty string is an exception when we want a negative integer'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_negative_integer => undef);
    },
    qr/is not a negative integer/,
    'undef is an exception when we want a negative integer'
    );

## NegativeOrZeroInt
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_nonpositive_integer => 0),
    'NegativeOrZeroInt');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonpositive_integer => 1);
    },
    qr/is not a negative integer or zero/,
    '1 is an exception when we want a non-positive integer'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_nonpositive_integer => undef);
    },
    qr/is not a negative integer or zero/,
    'undef is an exception when we want a non-positive integer'
    );

## SingleDigit
  ok(MooX::Types::MooseLike::Numeric::Test->new(a_single_digit => 0),
    'SingleDigit');
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_single_digit => 10);
    },
    qr/is not a single digit/,
    '10 is an exception when we want a single digit'
    );
  like(
    exception {
      MooX::Types::MooseLike::Numeric::Test->new(a_single_digit => undef);
    },
    qr/is not a single digit/,
    'undef is an exception when we want a single digit'
    );

eval q{ require Moose; require MooseX::Types::Common::Numeric; } or do {
    note "Moose or Type not available; skipping actual inflation tests";
    done_testing;
    exit;
};

is(
    exception { MooX::Types::MooseLike::Numeric::Test->new(a_positive_integer => 3) },
    undef,
    'Moose loaded; value which should not violate type constraint',
);

like(
    exception { MooX::Types::MooseLike::Numeric::Test->new(a_positive_integer => 0)},
    qr{isa check for "a_positive_integer" failed: 0 is not a positive integer},
    'Moose loaded; value which should violate type constraint',
);

my $tc = do {
    # Suppress distracting warnings from within Moose
    local $SIG{__WARN__} = sub { 0 };
    MooX::Types::MooseLike::Numeric::Test->meta->get_attribute('a_positive_integer')->type_constraint;
};

is(
    $tc->name,
    'MooseX::Types::Common::Numeric::PositiveInt',
    'type constraint inflation results in MooseX counterpart type',
);

ok($tc->check(1), 'Moose::Meta::TypeConstraint works (1)');
ok(!$tc->check(0), 'Moose::Meta::TypeConstraint works (3)');
ok(!$tc->check(-1), 'Moose::Meta::TypeConstraint works (3)');
ok(!$tc->check([]), 'Moose::Meta::TypeConstraint works (4)');
ok(!$tc->check(undef),'Moose::Meta::TypeConstraint works (5)');

  done_testing;
}
