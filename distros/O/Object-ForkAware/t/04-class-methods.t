use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Object::ForkAware;

is(
    exception {
        ok(Object::ForkAware->isa('Object::ForkAware'), 'isa as a class method checks isa of class');

        ok(!Object::ForkAware->isa('Warble'), '..and correctly returns false');
    },
    undef,
    "isa as a class method doesn't crash",
);

SKIP: {
    skip 'perl 5.9.4 required for UNIVERSAL::DOES', 3 if "$]" < '5.009004';
    is(
        exception {
            ok(Object::ForkAware->DOES('Object::ForkAware'), 'DOES as a class method checks DOES of class');

            ok(!Object::ForkAware->DOES('Warble'), '..and correctly returns false');
        },
        undef,
        "DOES as a class method doesn't crash",
    );
}

is(
    exception {
        is(
            Object::ForkAware->can('can'),
            \&Object::ForkAware::can,
            'can as a class method returns correct sub',
        );

        ok(!Object::ForkAware->can('nomethod'), '..or undef');
    },
    undef,
    "can as a class method doesn't crash",
);

done_testing;
