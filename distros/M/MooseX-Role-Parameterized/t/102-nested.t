use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use lib 't/lib';

{
    package Foo;
    use MooseX::Role::Parameterized;

    parameter 'outer' => (
        default => 'yep..',
    );

    role {
        with 'Bar', { include_is_bar => 0 };

        method is_foo => sub { 1 };
    };
}

{
    package Foo::Class;
    use Moose;
    ::is( ::exception {
        with 'Foo';
    }, undef, 'Can consume the Foo role without providing parameters');
}

{
    package Bar::Class;
    use Moose;
    ::is( ::exception {
        with 'Bar';
    }, undef, 'Can consume the Bar role without providing parameters');
}

my $foo = Foo::Class->meta->roles->[0];
ok($foo->has_method('is_foo'), 'Foo got the "is_foo" method');
ok(!$foo->has_method('is_bar'), 'Foo did not get the "is_bar" method from Bar');

my $bar = Bar::Class->meta->roles->[0];
ok($bar->has_method('is_bar'), 'Bar got the "is_bar" method');
ok(!$bar->has_method('is_foo'), 'Bar does not get "is_foo"');

ok(Foo->meta->has_parameter('outer'), 'Foo has outer param');
ok(Bar->meta->has_parameter('include_is_bar'), 'Bar has include_is_bar param');
ok(!Foo->meta->has_parameter('include_is_bar'), 'Foo does not have include_is_bar param');
ok(!Bar->meta->has_parameter('outer'), 'Bar does not have outer param');

done_testing;
