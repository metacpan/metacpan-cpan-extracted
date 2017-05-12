use Test::More tests => 30;
use ok 'Scalar::Defer', qw( defer lazy force is_deferred );

my ($x, $y);
my $d = defer { ++$x };
my $l = lazy { ++$y };

ok( is_deferred($d), 'is_deferred works for deferred values' );
ok( is_deferred($l), 'is_deferred works for lazy values' );

is($d, $l, "1 == 1");
ok( is_deferred($d), 'is_deferred works after 1st evaluation for deferred values' );
ok( is_deferred($l), 'is_deferred works after 1st evaluation for lazy values' );
is($d, 2, "defer is now 2");
ok( is_deferred($d), 'is_deferred works after 2nd evaluation for deferred values' );
is($l, 1, "but lazy stays at 1");
ok( is_deferred($l), 'is_deferred works after 2nd evaluation for lazy values' );
isnt($d, $l, "3 != 1");
ok( is_deferred($d), 'is_deferred works after 3rd evaluation for deferred values' );
ok( is_deferred($l), 'is_deferred works after 3rd evaluation for lazy values' );

{
  my $forced = force $d;
  ok( is_deferred($d), 'is_deferred works after force for deferred values' );
  ok( !is_deferred($forced), 'this forced value is not deferred' );
  is($forced, 4, 'force($x) works');
}

{
  my $forced = force $l;
  ok( is_deferred($l), 'is_deferred works after force for lazy values' );
  ok( !is_deferred($forced), 'this forced value is not deferred' );
  is($forced, 1, 'force($x) works');
}

{
  $SomeClass::VERSION = 42;
  sub SomeClass::meth { 'meth' };
  sub SomeClass::new { bless(\@_, $_[0]) }

  my $obj = defer { SomeClass->new };

  ok(!ref($obj), 'ref() returns false for deferred values');
  ok( is_deferred($obj), 'is_deferred' );
  my $forced = force $obj;
  ok( ref($forced), 'forced value is a ref' );
  ok( !is_deferred($forced), 'this forced value is not deferred');
}

ok( !is_deferred(1), 'integers are not deferred' );
ok( !is_deferred(0.1), 'floats are not deferred' );
ok( !is_deferred('string'), 'strings are not deferred' );
ok( !is_deferred(*STDIN), 'globs are not deferred' );
ok( !is_deferred({}), 'array refs are not deferred' );
ok( !is_deferred({}), 'hash refs are not deferred' );
ok( !is_deferred( bless((\my $id), 'SomeClass') ), 'blessed refs are not deferred' );
