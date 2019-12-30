#!/usr/bin/perl

package t::basic;

use Test2::V0;

use Test::Deep ();

use parent qw( Test::Class::Tiny );

if (!caller) {
    __PACKAGE__->runtests();
    done_testing;
}

sub T1_test_ok {
    ok(1, "pass");
    # ok(23, 'extra');
}

sub T1_test_bare_ok {
    ok 1;
}

sub T1_todo {
    todo 'not going to pass' => sub {
        ok 0, 'fail but that’s ok';
    };
}

sub T3_skip {
    my ($self) = @_;

    ok 1, 'this is good';

    SKIP: {
        skip 'pass up', $self->num_tests() - 1;
        ok 0;
        ok 1;
    }
}

# sub T1_blows_up {
#    ok(1, "pass");
#    die 123123;
#}

sub T0_not_counted {
    Test::Deep::cmp_deeply(
        [ 1, 2, 3 ],
        [ 1, 2, 3 ],
        'deep, old stuff',
    );
}

1;
