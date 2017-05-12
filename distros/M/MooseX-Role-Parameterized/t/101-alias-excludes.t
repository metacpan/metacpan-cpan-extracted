use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

do {
    package MyRole;
    use MooseX::Role::Parameterized;

    ::is( ::exception {
        parameter 'alias';
    }, undef);

    ::is( ::exception {
        parameter 'excludes';
    }, undef);

    role { }
};

do {
    package MyClass;
    use Moose;

    ::is( ::exception {
        with MyRole => {
            alias => 1,
        };
    }, undef);

    ::is( ::exception {
        with MyRole => {
            excludes => 1,
        };
    }, undef);
};

do {
    package OrdinaryRole;
    use MooseX::Role::Parameterized;

    sub code { 'originally code' }

    sub other_code { 'originally other_code' }

    role { }
};

do {
    package OrdinaryClass;
    use Moose;

    with OrdinaryRole => {
        -alias    => { code => 'new_code' },
        -excludes => [ 'other_code' ],
    };
};

ok(!OrdinaryClass->can('other_code'));
is(OrdinaryClass->code, 'originally code');
is(OrdinaryClass->new_code, 'originally code');

done_testing;
