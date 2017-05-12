#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 61;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'required by default';
{
    $t->app->routes->post("/required")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1        => {type => 'int'},
            int2        => {type => 'int'},
            int3        => {type => '!int', optional => 1},
            int4        => {type => '!@int', optional => 1},
            int5        => {type => 'require[int]', optional => 1},
            int6        => {type => 'required[int]', optional => 1},

            int_ok1     => {type => 'int'},
            int_ok2     => {type => 'int', default => 222},

            unknown     => {type => 'int'},
        );
        is $self->verrors, 7, 'total bugs';
        my %errors = $self->verrors;

        is $params{int1},       undef, 'int1';
        ok $errors{int1},       'int1 in errors';

        is $params{int2},       undef, 'int2';
        ok $errors{int2},       'int2 in errors';

        is $params{int3},       undef, 'int3 failed by shortcut';
        ok $errors{int3},       'int3 in errors';

        is_deeply $params{int4}, [undef], 'int4 failed array by shortcut';
        ok $errors{int4},       'int4 in errors';

        is $params{int5},       undef, 'int5 failed by shortcut';
        ok $errors{int5},       'int5 in errors';

        is $params{int6},       undef, 'int6 failed by shortcut';
        ok $errors{int6},       'int6 in errors';

        is $params{int_ok1},    111, 'int_ok1';
        ok !$errors{int_ok1},   'int_ok1 not in errors';

        is $params{int_ok2},    222, 'int_ok2';
        ok !$errors{int_ok2},   'int_ok2 not in errors';

        is $params{unknown},    undef, 'unknown';
        ok $errors{unknown},    'unknown in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/required", form => {
        int1    => '',
        int2    => '   ',
        int3    => '',
        int4    => [''],
        int5    => '',
        int6    => '',

        int_ok1 => 111,
        int_ok2 => '',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'optional';
{
    $t->app->routes->post("/optional")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1        => {type => 'int', optional => 1},
            int2        => {type => 'int', optional => 1},

            int_ok1     => {type => 'int', optional => 1},
            int_ok2     => {type => 'int', optional => 1, default => 222},
            int_ok3     => {type => '?int'},
            int_ok4     => {type => '?@int'},
            int_ok5     => {type => 'maybe[int]'},
            int_ok6     => {type => 'optional[int]'},

            int_fail1   => {type => 'int', optional => 1},

            int_parser1 => {type => '!?required[optional[int]]'},

            unknown     => {type => 'int', optional => 1},
        );

        is $self->verrors, 1, 'bugs';
        my %errors = $self->verrors;

        is $params{int1},       undef, 'int1';
        ok !$errors{int1},      'int1 not in errors';

        is $params{int2},       undef, 'int2';
        ok !$errors{int2},      'int2 not in errors';

        is $params{int_ok1},    111, 'int_ok1';
        ok !$errors{int_ok1},   'int_ok1 not in errors';

        is $params{int_ok2},    222, 'int_ok2';
        ok !$errors{int_ok2},   'int_ok2 not in errors';

        is $params{int_ok3},    333, 'int_ok3 by shortcat';
        ok !$errors{int_ok3},   'int_ok3 not in errors';

        is_deeply $params{int_ok4}, [1, 2], 'int_ok4 array by shortcat';
        ok !$errors{int_ok4},   'int_ok4 not in errors';

        is $params{int_ok5},    555, 'int_ok5 by shortcat';
        ok !$errors{int_ok5},   'int_ok5 not in errors';

        is $params{int_ok6},    666, 'int_ok5 by shortcat';
        ok !$errors{int_ok6},   'int_ok5 not in errors';

        is $params{int_fail1},  undef, 'int_fail1';
        ok $errors{int_fail1},  'int_fail1 in errors';

        is $params{int_parser1},    123, 'int_parser1 by shortcat';
        ok !$errors{int_parser1},   'int_parser1 not in errors';

        is $params{unknown},    undef, 'unknown';
        ok !$errors{unknown},    'unknown not in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/optional", form => {
        int1    => '',
        int2    => '   ',

        int_ok1 => 111,
        int_ok2 => '',
        int_ok3 => 333,
        int_ok4 => [1, 2],
        int_ok5 => 555,
        int_ok6 => 666,
        int_ok7 => 777,

        int_fail1 => 'ddd',

        int_parser1 => 123,
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'full optional';
{
    $t->app->routes->post("/foptional")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            -optional   => 1,
            int1        => {type => 'int'},
            int2        => {type => 'int'},

            int_ok1     => {type => 'int'},
            int_ok2     => {type => 'int', default => 222},

            int_fail1   => {type => 'int', optional => 1},

            unknown     => {type => 'int', optional => 1},
        );
        is $self->verrors, 1, 'bugs';
        my %errors = $self->verrors;

        is $params{int1},       undef, 'int1';
        ok !$errors{int1},      'int1 not in errors';

        is $params{int2},       undef, 'int2';
        ok !$errors{int2},      'int2 not in errors';

        is $params{int_ok1},    111, 'int_ok1';
        ok !$errors{int_ok1},   'int_ok1 not in errors';

        is $params{int_ok2},    222, 'int_ok2';
        ok !$errors{int_ok2},   'int_ok2 not in errors';

        is $params{int_fail1},  undef, 'int_fail1';
        ok $errors{int_fail1},  'int_fail1 in errors';

        is $params{unknown},    undef, 'unknown';
        ok !$errors{unknown},    'unknown not in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/foptional", form => {
        int1    => '',
        int2    => '   ',

        int_ok1 => 111,
        int_ok2 => '',

        int_fail1 => 'ddd',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

