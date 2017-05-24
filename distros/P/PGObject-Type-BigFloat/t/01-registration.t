
use Test::More tests => 13;

use PGObject;
use PGObject::Type::BigFloat;
use strict;
use warnings;

# Theoretically we could grab ints as well, and this makes a nice test case.
# The tests here are:
# 1.  Registration with the default registry, default types
# 2.  Registration with the default registry, int8 type
# 3.  Registration with custom registry 'test', int8 type
# 4.  Registration with custom registry 'test', default types
# 5.  Registry properly lists all appropriate types.

ok(PGObject->new_registry('test'), 'creating test registry');

ok(PGObject::Type::BigFloat->register(), 'default registration');
ok(PGObject::Type::BigFloat->register(types => ['int8']), 'int8 registration');
ok(PGObject::Type::BigFloat->register(registry => 'test', types => ['int8']),
                               'custom registry, int8 registration'),
ok(PGObject::Type::BigFloat->register(registry => 'test'), 
                                'default types, custom registry');
my $registry;
if ($PGObject::VERSION =~ /^1\./){
    $registry = PGObject::get_type_registry();
} else {
    $registry = {map {$_ => PGObject::Type::Registry->inspect($_)} qw(default test) };
}
for my $reg(qw(default test)){
    for my $type (qw(int8 float8 float4 numeric)) {
        is($registry->{$reg}->{$type}, 'PGObject::Type::BigFloat');
    }
}
