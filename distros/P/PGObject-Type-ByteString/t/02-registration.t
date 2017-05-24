
use Test::More;

use PGObject;
use PGObject::Type::ByteString;
use DBD::Pg qw(:pg_types);
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

ok(PGObject::Type::ByteString->register(), 'default registration');
ok(PGObject::Type::ByteString->register(types => ['mybytes']), 'mybytes registration');
ok(PGObject::Type::ByteString->register(registry => 'test',
                                        types => ['mybytes']),
                               'custom registry, mybytes registration'),
ok(PGObject::Type::ByteString->register(registry => 'test'),
                                'default types, custom registry');
my $registry;

if ($PGObject::VERSION =~ /^1\./){
    $registry = PGObject::get_type_registry();
} else {
    $registry = { map {$_ => PGObject::Type::Registry->inspect($_) } 
                  qw(default test) };
}
for my $reg (qw(default test)){
    for my $type (PG_BYTEA, 'mybytes') {
        is($registry->{$reg}->{$type}, 'PGObject::Type::ByteString',
           "registry $reg, type $type correctly registered");
    }
}

done_testing;
