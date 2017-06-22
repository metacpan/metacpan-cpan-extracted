#!perl

use strict;
use warnings;

use Test::More;

our $EXCEPTION;

BEGIN {

    package Service {
        use Moxie;

        has 'is_locked' => sub { 0 };
    }

    package WithClass {
        use Moxie;

        with 'Service';
    }

    package WithParameters {
        use Moxie;

        with 'Service';
    }

    package WithDependencies {
        use Moxie;

        with 'Service';
    }

    eval q[
        package ConstructorInjection {
            use Moxie;

            extends 'Moxie::Object';
               with 'WithClass', 'WithParameters', 'WithDependencies';
        }
    ];
    $EXCEPTION = $@;
}

is($EXCEPTION, '', '... this worked');

foreach my $role (map { MOP::Role->new( name => $_ ) } qw[
    WithClass
    WithParameters
    WithDependencies
]) {
    ok($role->has_slot('is_locked'), '... the is_locked slot is treated as a proper slot because it was composed from a role');
    ok($role->has_slot_alias('is_locked'), '... the is_locked slot is also an alias, because that is how we install things in roles');
    is_deeply(
        [ map { $_->name } $role->slots ],
        [ 'is_locked' ],
        '... these roles should then show the is_locked slot'
    );
};

done_testing;
