use strict;
use warnings;
use Test::More;
use Test::Fatal;

eval q{
	package Local::TestClass;
	use Moo;
	use MooX::Types::MooseLike::Base qw( Enum AnyOf Str ArrayRef ScalarRef HashRef HasMethods );
	has chipmunk => (is => 'ro', isa => Enum[qw(Alvin Simon Theodore)]);
	has songs    => (is => 'ro', isa => AnyOf[ Str, ArrayRef[Str] ]);
	has complex  => (is => 'ro', isa => HashRef[ArrayRef[ScalarRef[HasMethods[qw/foo bar/]]]]);
	1;
} or die $@;

is(
  exception { Local::TestClass->new(chipmunk => 'Simon', songs => []) },
  undef,
  'values which should not violate type constraints',
  );

like(
  exception { Local::TestClass->new(chipmunk => 'Romeo') },
  qr{^isa check for "chipmunk" failed: Romeo is not any of the possible values},
  'value which should violate Enum type constraint',
  );

like(
  exception { Local::TestClass->new(songs => {}) },
  qr{^isa check for "songs" failed: HASH\(.+?\) is not any of the types},
  'value which should violate AnyOf type constraint',
  );

eval q{ require Moose } or do {
  note "Moose not available; skipping actual inflation tests";
  done_testing;
  exit;
  };

my $tc = do {
  $SIG{__WARN__} = sub { 0 };
  Local::TestClass->meta->get_attribute('chipmunk')->type_constraint;
  };

is(
  exception { Local::TestClass->new(chipmunk => 'Simon') },
  undef,
  'Moose loaded; value which should not violate type constraint',
  );

like(
  exception { Local::TestClass->new(chipmunk => 'Romeo') },
  qr{^isa check for "chipmunk" failed: Romeo is not any of the possible values},
  'Moose loaded; value which should violate type constraint',
  );

isa_ok($tc, 'Moose::Meta::TypeConstraint::Enum');
is_deeply($tc->values, [qw/Alvin Simon Theodore/], '$tc->values');

my $tc2 = do {
  $SIG{__WARN__} = sub { 0 };
  Local::TestClass->meta->get_attribute('songs')->type_constraint;
  };

ok(
  $tc2->name eq 'ArrayRef[Str]|Str' || $tc2->name eq 'Str|ArrayRef[Str]',
  'complex type constraint (union of Str and ArrayRef[Str]) correctly inflated',
  );

my $tc3 = do {
  $SIG{__WARN__} = sub { 0 };
  Local::TestClass->meta->get_attribute('complex')->type_constraint;
  };

is(
  $tc3->name,
  'HashRef[ArrayRef[ScalarRef[__ANON__]]]',
  'very complex type constraint correctly inflated',
  );

isa_ok(
  $tc3->type_parameter->type_parameter->type_parameter,
  'Moose::Meta::TypeConstraint::DuckType',
  );

is_deeply(
  [sort @{$tc3->type_parameter->type_parameter->type_parameter->methods}],
  [sort qw/foo bar/],
  'duck type has correct methods'
  );

done_testing;
