use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

do {
    package MyRole::Storage;
    use MooseX::Role::Parameterized;

    ::like( ::exception {
        parameter()
    }, qr/^You must provide a name for the attribute/);

    role {
        ::like( ::exception {
            extends 'MyRole::Parameterized';
        }, qr/^Roles do not support 'extends' \(you can use 'with' to specialize a role\)/);
        ::like( ::exception {
            inner()
        }, qr/^Roles cannot support 'inner'/);
        ::like( ::exception {
            augment()
        }, qr/^Roles cannot support 'augment'/);
        ::like( ::exception {
            parameter()
        }, qr/^'parameter' may not be used inside of the role block/);
        ::like( ::exception {
            role {}
        }, qr/^'role' may not be used inside of the role block/);
    };
};

Moose::Meta::Class->create_anon_class(
    roles => ['MyRole::Storage'],
);

done_testing;
