use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Class::Load 'is_class_loaded';

{
    package MyClass;
    use Moose;
    use MooseX::Types::LoadableClass qw/LoadableClass LoadableRole/;

    has foobar_class => (
        is     => 'ro',
        isa    => LoadableClass,
        coerce => 1,
    );

    has foobar_role => (
        is     => 'ro',
        isa    => LoadableRole,
        coerce => 1,
    );
}

ok(!is_class_loaded('FooBarTestClass'), 'class is not loaded');
is(
    exception { MyClass->new(foobar_class => 'FooBarTestClass') },
    undef,
    'LoadableClass validates',
);
ok(is_class_loaded('FooBarTestClass'), 'now class is loaded');

like(
    exception { MyClass->new(foobar_class => 'FooBarTestClassDoesNotExist') },
    qr/Validation failed/,
    'LoadableClass does not validate with another class name',
);

ok(!is_class_loaded('FooBarTestRole'), 'role is not loaded');
is(
    exception { MyClass->new(foobar_role => 'FooBarTestRole') },
    undef,
    'LoadableRole validates',
);
ok(is_class_loaded('FooBarTestRole'), 'now role is loaded');

like(
    exception { MyClass->new(foobar_role => 'FooBarTestClass') },
    qr/Validation failed/,
    'LoadableRole does not validate with another role name',
);

like(
    exception { MyClass->new(foobar_role => 'FooBarTestRoleDoesNotExist') },
    qr/Validation failed/,
    'and again',
);

use MooseX::Types::LoadableClass qw/LoadableClass LoadableRole/;

for my $name (qw(Non::Existent::Module ::Syntactically::Invalid::Name)) {
    for my $tc (LoadableClass, LoadableRole) {
        for (0..1)
        {
            is(
                exception { ok(! $tc->check($name), $tc->name . ", $name: validation failed") },
                undef,
                $tc->name . ", $name: does not die"
            );
        }
    }
}

done_testing;
