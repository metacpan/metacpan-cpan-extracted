use strict;
use warnings;
use Test::More;
use Object::Proto;

Object::Proto::define('TE', 'i:Int', 'n:Num', 'o:Object', 'any:Any', 'd:Defined');

my $t = TE->new;

eval { $t->i('') };
like($@, qr/Type constraint failed for 'i': expected Int/, 'Int rejects the empty string');
eval { $t->i(undef) };
like($@, qr/expected Int/, 'Int rejects undef');
eval { $t->i(1.5) };
like($@, qr/expected Int/, 'Int rejects a float');
eval { $t->i([]) };
like($@, qr/expected Int/, 'Int rejects a reference');
$t->i('42');
is($t->i, 42, 'Int takes a numeric string');

eval { $t->n(undef) };
like($@, qr/expected Num/, 'Num rejects undef');
eval { $t->n({}) };
like($@, qr/expected Num/, 'Num rejects a reference');
eval { $t->n('') };
like($@, qr/expected Num/, 'Num rejects the empty string');
$t->n('1.5');
is($t->n, 1.5, 'Num takes a numeric string');

my $obj = bless {}, 'TE::Thing';
$t->o($obj);
is($t->o, $obj, 'Object takes a blessed reference');
eval { $t->o({}) };
like($@, qr/expected Object/, 'Object rejects a plain reference');
eval { $t->o('TE::Thing') };
like($@, qr/expected Object/, 'Object rejects a class name');

is(Object::Proto::slot_info('TE', 'any')->{type}, 'Any', 'an Any slot reports its type name');
$t->any(undef);
ok(!defined $t->any, 'and takes undef');
eval { $t->d(undef) };
like($@, qr/expected Defined/, 'Defined rejects undef');

ok(Object::Proto::register_simple_custom_op("op$_"), "custom op op$_ registered") for 1 .. 7;
ok(Object::Proto::register_simple_custom_op('op3'), 'registering a name again is fine');
eval { Object::Proto::register_simple_custom_op('op8') };
like($@, qr/registry is full \(max 8\)/, 'the ninth custom op name is one too many');
eval { Object::Proto::register_simple_custom_op('') };
like($@, qr/name must not be empty/, 'an empty custom op name is refused');
eval { Object::Proto::register_simple_custom_op() };
like($@, qr/Usage: Object::Proto::register_simple_custom_op/, 'and no name at all');

done_testing;
