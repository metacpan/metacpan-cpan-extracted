use Test2::V0;

use PGObject;
use PGObject::Type::JSON;
use strict;
use warnings;
plan 6;

# We can theoretically grab any scalar here and just treat it as a scalar ref
# value.  This test case is totally arbitrary.
#

ok(PGObject::Type::JSON->register(), 'default registration');
ok(PGObject::Type::JSON->register(types => ['int8']), 'int8 registration');
ok(PGObject::Type::JSON->register(types => ['int8']),
                               'custom registry, int8 registration'),
ok(PGObject::Type::JSON->register(), 
                                'default types, custom registry');
my $registry;
if ($PGObject::VERSION =~ /^1\./){
    $registry = PGObject::get_type_registry();
} else {
    $registry = { map { $_ => PGObject::Type::Registry->inspect($_) } qw(default) };
}
for my $reg(qw(default)){
    for my $type (qw(int8 json)) {
        is($registry->{$reg}->{$type}, 'PGObject::Type::JSON');
    }
}
