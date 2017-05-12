#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 57;
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
        $self->log->level( $ENV{MOJO_LOG_LEVEL} = 'warn' );
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'unknown type';
{
    $t->app->routes->post("/test/errors/vparam")->to( cb => sub {
        my ($self) = @_;

        eval { $self->vparam( int1 => 'non_exiting_type') };
        ok $@, 'type not found';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/errors/vparam", form => {
        int1    => 111,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'default supress errors';
{
    $t->app->routes->post("/test/param/default/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int1 => {type => 'int', default => 111} ), 111,
            'int1 default value';
        is $self->verror('int1'), 0, 'int1 no error';

        is $self->vparam( int2 => {type => 'int', default => 222} ), 222,
            'int2 default value';
        is $self->verror('int12'), 0, 'int2 no error';

        is $self->verrors, 0, 'no bugs';
        my %errors = $self->verrors;

        ok !$errors{int1}, 'int1 not in errors';
        ok !$errors{int2}, 'int2 not in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/param/default/vparam", form => {
        int1    => 'ddd',
        int2    => '',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'param definition errors';
{
    $t->app->routes->post("/test/param/errors/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply { $self->vparams(
            int1 => 'int',
            int2 => 'int',
            int3 => 'int',
        )}, {
            int1 => undef,
            int2 => undef,
            int3 => undef,
        }, 'vparams';

        is $self->verror('int1'), 'Value is not defined', 'int1 error';
        is $self->verror('int2'), 'Value is not defined', 'int2 error';
        is $self->verror('int3'), 'Value is not defined', 'int3 error';

        is $self->vparam( int4 => {type => 'int'} ), undef, 'int4';
        is $self->verror('int4'), 'Value is not defined',   'int4 error';

        is $self->vparam( int5 => {type => 'int'} ), undef, 'int5';
        is $self->verror('int5'), 'Value is not defined',   'int5 error';

        is $self->verrors, 5, 'bugs';
        my %errors = $self->verrors;

        ok $errors{int1},               'error int1';
        is $errors{int1}{in}, 'aaa',  'error int1 in';
        is $errors{int1}{out}, undef,   'error int1 out';
        ok $errors{int2},               'error int2';
        is $errors{int2}{in}, 'bbb',  'error int2 in';
        is $errors{int2}{out}, undef,   'error int2 out';
        ok $errors{int3},               'error int3';
        is $errors{int3}{in}, 'ccc',  'error int3 in';
        is $errors{int3}{out}, undef,   'error int3 out';
        ok $errors{int4},               'error int4';
        is $errors{int4}{in}, '',     'error int4 in';
        is $errors{int4}{out}, undef,   'error int4 out';
        ok $errors{int5},               'error int5';
        is $errors{int5}{in}, 'aaa',  'error int5 in';
        is $errors{int5}{out}, undef,   'error int5 out';

#        note explain $self->verrors;

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/param/errors/vparam", form => {
        int1    => 'aaa',
        int2    => 'bbb',
        int3    => 'ccc',
        int4    => '',
        int5    => 'aaa',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'array errors';
{
    $t->app->routes->post("/test/param/array/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( int1 => '@int' ), [undef], 'int1';
        is $self->verror('int1'),    1, 'int1 has 1 errors';
        is $self->verror('int1', 0), 'Value is not defined', 'int1[0] error';

        is_deeply $self->vparam( int2 => '@int' ), [1, undef, 3, undef],
            'int2';
        is $self->verror('int2'),    2, 'int2 has 2 errors';
        is $self->verror('int2', 0), 0,                      'int2[0] no error';
        is $self->verror('int2', 1), 'Value is not defined', 'int2[0] error';
        is $self->verror('int2', 2), 0,                      'int2[2] no error';
        is $self->verror('int2', 3), 'Value is not defined', 'int2[0] error';

        is_deeply $self->vparam( unknown => '@int' ), [],   'unknown';

        my %errors = $self->verrors;
        is scalar keys %errors, 3, 'bugs';

        ok $errors{int1},       'int1 in errors';
        ok $errors{int2},       'int2 in errors';
        ok $errors{unknown},    'unknown in errors';

#        note explain \%errors;

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/param/array/vparam", form => {
        int1    => 'ddd',
        int2    => [1, 'aaa', 3, ''],
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}
=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

