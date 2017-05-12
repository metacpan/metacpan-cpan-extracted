use strict;
use warnings;
use Test::More;
use Test::Fatal;

eval q{
	package Local::TypeLibrary;
	use Exporter 'import';
	use MooX::Types::MooseLike ();
	MooX::Types::MooseLike::register_types([{
		name    => 'Flibble',
		test    => sub { $_[0] =~ /^flibble$/i },
		message => sub { 'Unflibble' },
		inflate => 0,
	}], __PACKAGE__);
	$INC{'Local/TypeLibrary.pm'} = __FILE__;
	1;
} or die $@;

eval q{
	package Local::TestClass;
	use Moo;
	use Local::TypeLibrary 'Flibble';
	has flibble => (is => 'ro', isa => Flibble);
	1;
} or die $@;

is(
  exception { Local::TestClass->new(flibble => 'fliBBle') },
  undef,
  'value which should not violate type constraint',
  );

like(
  exception { Local::TestClass->new(flibble => 'monkey') },
  qr{^isa check for "flibble" failed: Unflibble},
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
  exception { Local::TestClass->new(flibble => 'monkey') },
  qr{^isa check for "flibble" failed: Unflibble},
  'Moose loaded; value which should violate type constraint',
  );

my $tc = do {

  # Suppress distracting warnings from within Moose
  local $SIG{__WARN__} = sub { 0 };
  Local::TestClass->meta->get_attribute('flibble')->type_constraint;
  };

is(
  $tc->name,
  '__ANON__',
  'type constraint inflation results in an anonymous type',
  );

ok($tc->check('Flibble'), 'Moose::Meta::TypeConstraint works (1)');
ok($tc->check('FLIBBLE'), 'Moose::Meta::TypeConstraint works (2)');
ok(!$tc->check('Monkey'), 'Moose::Meta::TypeConstraint works (3)');
ok(!$tc->check([]), 'Moose::Meta::TypeConstraint works (4)');

done_testing;
