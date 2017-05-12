#!perl

use Test::Most;

plan tests => 19;

use_ok('t::TryCatchAuto') or BAIL_OUT('');

is($My::Bar::caller, 0, 'caller=0');
is($My::Bar::cought, 0, 'cought=0');

lives_ok {
    is (t::TryCatchAuto::foo_bar(My::Foo->new), 'foo/My::Foo');
} 'foo_bar(My::Foo->new)';

is($My::Bar::caller, 1, 'caller=1');
is($My::Bar::cought, 0, 'cought=0');

lives_ok {
    is (t::TryCatchAuto::foo_bar(My::Bar->new), 'bar/My::Bar');
} 'foo_bar(My::Bar->new)';

is($My::Bar::caller, 2, 'caller=2');
is($My::Bar::cought, 1, 'cought=1');

lives_ok {
    is (t::TryCatchAuto::bar_foo(My::Foo->new), 'foo/My::Foo');
} 'foo_bar(My::Bar->new)';

is($My::Bar::caller, 3, 'caller=3');
is($My::Bar::cought, 1, 'cought=1');

lives_ok {
    is (t::TryCatchAuto::bar_foo(My::Bar->new), 'bar/My::Bar');
} 'foo_bar(My::Bar->new)';

is($My::Bar::caller, 4, 'caller=4');
is($My::Bar::cought, 2, 'cought=2');

done_testing;
