use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib/';
use Foo;
use Module::Functions;

ok(__PACKAGE__->can('foo'));
ok(!__PACKAGE__->can('catfile'));
is(foo(), '5963');
is_deeply([get_public_functions('Foo')], ['foo']);

done_testing;

