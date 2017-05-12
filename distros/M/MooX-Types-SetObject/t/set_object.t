{

  package MooX::Types::MooseLike::Test;
  use strict;
  use warnings FATAL => 'all';
  use Moo;
  use MooX::Types::MooseLike::Base qw/ Int /;
  use MooX::Types::SetObject qw/ SetObject /;

  has set_object_of_ints => (
    is  => 'ro',
    isa => SetObject[Int],
    );
}

package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;

BEGIN {
  eval { require Set::Object };
  plan skip_all => 'SetObject tests need Set::Object'
    if $@;
}

# Set::Object
ok(
  MooX::Types::MooseLike::Test->new(
    set_object_of_ints => Set::Object->new(1, 2, 3),
    ),
  'Set::Object of integers'
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(
      set_object_of_ints => Set::Object->new('fREW'),);
  },
  qr(fREW is not an integer),
  'Int eror mesage is triggered when validation fails'
  );

eval q{ require Moose } or do {
    note "Moose not available; skipping actual inflation tests";
    done_testing;
    exit;
};

my $tc = do {
    $SIG{__WARN__} = sub { 0 };
    MooX::Types::MooseLike::Test->meta->get_attribute('set_object_of_ints')->type_constraint;
};

is(
    exception { MooX::Types::MooseLike::Test->new(set_object_of_ints => Set::Object->new(1..4)) },
    undef,
    'Moose loaded; value which should not violate type constraint',
);
like(
    exception { MooX::Types::MooseLike::Test->new(set_object_of_ints => Set::Object->new(1.1, 2.0, 4)) },
    qr{set_object_of_ints" failed: 1.1 is not an integer},
    'Moose loaded; value which should violate type constraint',
);

is(
    $tc->name,
    '__ANON__',
    'type constraint inflation results in an anonymous type',
);

ok($tc->check(Set::Object->new(16..18)), 'Moose::Meta::TypeConstraint works (1)');
ok($tc->check(Set::Object->new(0,1)), 'Moose::Meta::TypeConstraint works (2)');
ok(!$tc->check('Monkey'), 'Moose::Meta::TypeConstraint works (3)');
ok(!$tc->check([1,2]), 'Moose::Meta::TypeConstraint works (4)');
ok(!$tc->check(Set::Object->new(0,1.1)), 'Moose::Meta::TypeConstraint works (5)');

done_testing;
