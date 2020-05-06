#!/usr/bin/perl

package t::basic;

use Test2::V0;

use Test::Deep ();

use parent qw( Test::Class::Tiny );

my @order;

if (!caller) {
    __PACKAGE__->runtests();

    is(
        \@order,
        [
            't::basic::foo_T_startup',

            't::basic::foo_T_setup',
            't::basic::not_counted_T0',
            't::basic::foo_T_teardown',

            't::basic::foo_T_setup',
            't::basic::skip_T3',
            't::basic::foo_T_teardown',

            't::basic::foo_T_setup',
            't::basic::test_bare_ok_T1',
            't::basic::foo_T_teardown',

            't::basic::foo_T_setup',
            't::basic::test_ok_T1',
            't::basic::foo_T_teardown',

            't::basic::foo_T_setup',
            't::basic::todo_T1',
            't::basic::foo_T_teardown',

            't::basic::foo_T_shutdown',
        ],
        'method execution order',
    );

    done_testing;
}

sub foo_T_startup {
    push @order, (caller 0)[3];
}

sub foo_T_setup {
    push @order, (caller 0)[3];
}

sub foo_T_teardown {
    push @order, (caller 0)[3];
}

sub foo_T_shutdown {
    push @order, (caller 0)[3];
}

sub test_ok_T1 {
    push @order, (caller 0)[3];
    ok(1, "pass");
}

sub test_bare_ok_T1 {
    push @order, (caller 0)[3];
    ok 1;
}

sub todo_T1 {
    push @order, (caller 0)[3];

    todo 'not going to pass' => sub {
        ok 0, 'fail but that’s ok';
    };
}

sub skip_T3 {
    my ($self) = @_;

    push @order, (caller 0)[3];

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

sub not_counted_T0 {
    push @order, (caller 0)[3];

    Test::Deep::cmp_deeply(
        [ 1, 2, 3 ],
        [ 1, 2, 3 ],
        'deep, old stuff',
    );
}

1;
