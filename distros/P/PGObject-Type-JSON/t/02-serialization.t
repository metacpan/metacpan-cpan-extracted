use Test2::V0;
use PGObject::Type::JSON;

use Carp::Always;

plan 25;

use strict;
use warnings;

my $nulltest = 'null';
my $undeftest = undef;
my $hashtest = '{"foo": 1, "bar": 2}';
my $hashtest2 = '{"bar": 2, "foo": 1}';
my $arraytest = '[1,2,3]';
my $literaltest = 'a123abc"\u0000"';
my $inttest = 123;
my ($undef, $null, $hash, $array, $literal, $int);

# not allowing coderefs
ok(dies { PGObject::Type::JSON->new( sub { 1 } ) }, 'dies on coderef');

# string 'null', should serialize as 'null', not the same as db null
ok($null = PGObject::Type::JSON->new(PGObject::Type::JSON->from_db($nulltest)), 'Instantiate null');
ok($null->isa('PGObject::Type::JSON'), "Null is a JSON object");
is($null->reftype, 'SCALAR', 'Null is a scalar');
is($null->to_db, 'null', 'Serializes to db as null');
ok(!$null->is_null, 'Null is not undef');

# undef, db null, should serialize as undef
ok($undef = PGObject::Type::JSON->from_db($undeftest), 'Instantiate undef');
ok($undef->isa('PGObject::Type::JSON'), 'Undef isa JSON object');
is($undef->reftype, 'SCALAR', 'Undef is scalar');
is($undef->to_db, undef, 'Serializes to db as undef');
ok($undef->is_null, 'undef is undef');

#hashref, should serialize exactly as it is
ok($hash = PGObject::Type::JSON->from_db($hashtest), 'Instantiate hashref');
ok($hash->isa('PGObject::Type::JSON'), "Hashref is a JSON object");
is($hash->reftype, 'HASH', 'Hashref is a HASH');
like($hash->to_db, qr/(\{"bar":2,"foo":1\}|\{"foo":1,"bar":2\})/, 'Serialization of hashtest works');
is($hash->{foo}, 1, 'Hash foo element is 1');
is($hash->{bar}, 2, 'Hash bar element is 2');

#arrayref should serialize as it is
ok($array = PGObject::Type::JSON->from_db($arraytest), 'Instantiate arrayref');
is($array->reftype, 'ARRAY', 'Array is ARRAY');
is($array, [1, 2, 3], 'Array is correct array');
is($array->to_db, $arraytest, 'Array serializes to db correctly');

#int ref, should be a scalar ref, serializing as it is
is(PGObject::Type::JSON->from_db($inttest), $inttest,
     'Instantiate literal int');
is(PGObject::Type::JSON->new($inttest)->to_db, qq($inttest), 'Literal serializes correctly');
#literal ref, should be a scalar ref, serializing as it is
is(PGObject::Type::JSON->new($literaltest)->to_db, '"a123abc\"\\\\u0000\""', 'Serialization test');
ok($literal = PGObject::Type::JSON->from_db(PGObject::Type::JSON->new($literaltest)->to_db), $literaltest, 'basic round trip for complex literal');
