use Test::More tests => 9;

use PGObject;
use PGObject::Type::JSON;
use strict;
use warnings;

# We can theoretically grab any scalar here and just treat it as a scalar ref
# value.  This test case is totally arbitrary.
#
ok(PGObject->new_registry('test'), 'creating test registry');

ok(PGObject::Type::JSON->register(), 'default registration');
ok(PGObject::Type::JSON->register(types => ['int8']), 'int8 registration');
ok(PGObject::Type::JSON->register(registry => 'test', types => ['int8']),
                               'custom registry, int8 registration'),
ok(PGObject::Type::JSON->register(registry => 'test'), 
                                'default types, custom registry');
my $registry = PGObject::get_type_registry();
for my $reg(qw(default test)){
    for my $type (qw(int8 json)) {
        is($registry->{$reg}->{$type}, 'PGObject::Type::JSON');
    }
}
