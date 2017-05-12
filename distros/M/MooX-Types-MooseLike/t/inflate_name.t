use strict;
use warnings;
use Test::More;
use Test::Fatal;

eval q{
    package Local::TypeLibrary;
    use Exporter 'import';
    use MooX::Types::MooseLike ();
    MooX::Types::MooseLike::register_types([{
        name    => 'Defined',
        test    => sub { defined $_[0] },
        message => sub { 'Not defined' },
    }], __PACKAGE__);
    $INC{'Local/TypeLibrary.pm'} = __FILE__;
    1;
} or die $@;

eval q{
    package Local::TestClass;
    use Moo;
    use Local::TypeLibrary 'Defined';
    has flibble => (is => 'ro', isa => Defined);
    1;
} or die $@;

is(
  exception { Local::TestClass->new(flibble => 'fliBBle') },
  undef,
  'value which should not violate type constraint',
  );

like(
  exception { Local::TestClass->new(flibble => undef) },
  qr{^isa check for "flibble" failed: Not defined},
  'value which should violate type constraint',
  );

eval q{ require Moose } or do {
  note "Moose not available; skipping actual inflation tests";
  done_testing;
  exit;
  };

is(
  exception { Local::TestClass->new(flibble => 'fliBBle') },
  undef,
  'Moose loaded; value which should not violate type constraint',
  );

like(
  exception { Local::TestClass->new(flibble => undef) },
  qr{^isa check for "flibble" failed: Not defined},
  'Moose loaded; value which should violate type constraint',
  );

my $tc = do {

  # Suppress distracting warnings from within Moose
  local $SIG{__WARN__} = sub { 0 };
  Local::TestClass->meta->get_attribute('flibble')->type_constraint;
  };

is(
  $tc->name,
  'Defined',
  'type constraint inflation results in built in Defined type',
  );

ok($tc->check('Flibble'), 'Moose::Meta::TypeConstraint works (1)');
ok(!$tc->check(undef), 'Moose::Meta::TypeConstraint works (2)');

done_testing;
