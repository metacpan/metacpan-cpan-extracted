use Test::More tests => 19;
use ok 'Scalar::Defer';

my ($x, $y);
my $d = defer { ++$x };
my $l = lazy { ++$y };

is($d, $l, "1 == 1");
is($d, 2, "defer is now 2");
is($l, 1, "but lazy stays at 1");
isnt($d, $l, "3 != 1");

my $forced = force $d;
is($forced, 4, 'force($x) works');
is($forced, 4, 'force($x) is stable');
is(force $forced, 4, 'force(force($x)) is stable');

$SomeClass::VERSION = 42;
sub SomeClass::meth { 'meth' };
sub SomeClass::new { bless(\@_, $_[0]) }

my $obj = defer { SomeClass->new };

ok(!ref($obj), 'ref() returns false for deferred values');
is(ref(force $obj), 'SomeClass', 'ref() returns true for forced values');
is($obj->meth, 'meth', 'method call works on deferred objects');
is($obj->can('meth'), SomeClass->can('meth'), '->can works too');
ok($obj->isa('SomeClass'), '->isa works too');
is($obj->VERSION, SomeClass->VERSION, '->VERSION works too');

ok( Scalar::Defer->can("can"), "can('can') as a class method" );
ok( !Scalar::Defer::Deferred->can('blah'), "can('blah') is false as a class method" );

ok( $obj->can("can"), "can('can') as an object method" );
ok( $obj->can("meth"), "can('meth')");
ok( !$obj->can('blah'), "can('blah') is false as an object method" );
