use strict;
use warnings;

use Test::Arrow;

my $arr = Test::Arrow->new;

$arr->isa_ok($arr => 'Test::Arrow', 'Name');
$arr->isa_ok($arr => 'Test::Arrow');

$arr->name('Name')
    ->expected('Test::Arrow')
    ->got($arr)
    ->isa_ok;

$arr->expected('Test::Arrow')
    ->got($arr)
    ->isa_ok;

$arr->expected('HASH')
    ->got({})
    ->isa_ok;

FROM_TEST_MORE: {
    $arr->isa_ok(bless([], 'Foo'), 'Foo');
    $arr->isa_ok([], 'ARRAY');
    $arr->isa_ok(\42, 'SCALAR');
    {
        local %Bar::;
        local @Foo::ISA = 'Bar';
        $arr->isa_ok('Foo', 'Bar');
    }

    # can_ok() & isa_ok should call can() & isa() on the given object, not 
    # just class, in case of custom can()
    {
        local *Foo::can;
        local *Foo::isa;
        *Foo::can = sub { $_[0]->[0] };
        *Foo::isa = sub { $_[0]->[0] };
        my $foo = bless([0], 'Foo');
        $arr->ok(!$foo->can('bar'));
        $arr->ok(!$foo->isa('bar'));
        $foo->[0] = 1;
        $arr->can_ok($foo, 'blah');
        $arr->isa_ok($foo, 'blah');
    }
}

$arr->done_testing;
