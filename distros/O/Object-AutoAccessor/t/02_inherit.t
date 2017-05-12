use strict;
use Test::More tests => 7;

use lib 't/lib';
use Foo;

my $foo = Foo->new;

BEGIN { use_ok('Foo'); }

ok($foo->isa('Object::AutoAccessor'));

$foo->test('abc123');

is($foo->test, 'abc123');

$foo->renew();

ok($foo->isa('Object::AutoAccessor'));

$foo->test('def456');

is($foo->test, 'def456');

$foo->test(Object::AutoAccessor->new);

ok($foo->is_node('test'));

$foo->test(Foo->new);

ok($foo->is_node('test'));
