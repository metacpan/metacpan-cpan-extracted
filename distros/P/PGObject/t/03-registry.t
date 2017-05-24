package Serializer;

sub from_db {
    my ($pkg, $dbstring, $dbtype) = @_;
    return 4 unless $dbtype;
    return $dbtype;
}

package main;

use Test::More tests => 11;
use PGObject::Type::Registry;
use Test::Exception;

lives_ok {PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo', apptype => 'PGObject') },
        "Basic type registration";
lives_ok {PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo', apptype => 'PGObject') },
        "Repeat type registration";

throws_ok { PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo', apptype => 'main') }
    qr/different target/,
    "Repeat type registration, different type, fails";

throws_ok {PGObject::Type::Registry->register_type(
        registry => 'default', dbtype => 'foo2', apptype => 'Foobar') }
    qr/not yet loaded/,
    "Cannot register undefined type";


throws_ok{PGObject::Type::Registry->register_type(
        registry => 'foo', dbtype => 'foo', apptype => 'PGObject') }
 qr/Registry.*exist/, 
'Correction exception thrown, reregistering in nonexistent registry.';

lives_ok { PGObject::Type::Registry->new_registry('foo') }, 'Created registry';

is (PGObject::Type::Registry->deserialize(
        registry => 'foo', 'dbtype' => 'test', 'dbstring' => '10000'), 10000,
        'Deserialization of unregisterd type returns input straight');
lives_ok { PGObject::Type::Registry->register_type(
        registry => 'foo', dbtype => 'test', apptype => 'Serializer') },
        'registering serializer';

is (PGObject::Type::Registry->deserialize(
        registry => 'foo', 'dbtype' => 'test', 'dbstring' => '10000'), 'test',
        'Deserialization of registerd type returns from_db');

is_deeply([sort {$a cmp $b} qw(foo default)], [sort {$a cmp $b} PGObject::Type::Registry->list()], 'Registry as expected');

is(PGObject::Type::Registry->inspect('foo')->{test}, 'Serializer', "Correct inspection behavior");
