#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 28;
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

note 'array';
{
    $t->app->routes->post("/test/array/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( array1 => 'int' ), [1,2,3], 'array1 = [1,2,3]';
        is_deeply $self->vparam( array2 => 'int' ), 1,       'array2 not array';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/array/vparam", form => {

        array1      => [1, 2, 3],
        array2      => [1],

    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'force array';
{
    $t->app->routes->post("/test/farray/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( 'array2' => 'int', array => 1 ), [2],
            'array2';
        is_deeply $self->vparam( 'array3' => {type => 'int', array => 1} ), [3],
            'array3';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/farray/vparam", form => {

        array2      => 2,
        array3      => 3,

    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'preudo type @...';
{
    $t->app->routes->post("/test/parray/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( 'array1' => '@int' ), [1],
            'array1';
        is_deeply $self->vparam( 'array2' => '@int' ), [2, 3],
            'array2';
        is_deeply $self->vparam( 'array3' => '@numeric' ), [3.33],
            'array3';
        is_deeply $self->vparam( 'array4' => '@str' ), ['aaa'],
            'array4';
        is_deeply $self->vparam( 'array5' => '@int' ), [5],
            'array5';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/parray/vparam", form => {

        array1      => 1,
        array2      => [2, 3],
        array3      => 3.33,
        array4      => 'aaa',
        array5      => [5],
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'preudo type array[...]';
{
    $t->app->routes->post("/test/aarray/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( 'array3' => 'array[int]' ), [3],
            'array3';
        is_deeply $self->vparam( 'array4' => 'array[int]' ), [4, 5],
            'array4';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/aarray/vparam", form => {

        array3      => 3,
        array4      => [4, 5],

    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'broken array';
{
    $t->app->routes->post("/test/barray/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( 'array1' => 'int', array => 1 ), [undef],
            'array1';
        is_deeply $self->vparam( 'array2' => 'int', array => 1 ), [undef],
            'array2';
        is_deeply $self->vparam( 'array3' => 'int', array => 1 ), [1,2,undef,4],
            'array2';

        is_deeply $self->vparam( 'unknown' => 'int', array => 1 ), [],
            'unknown';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/barray/vparam", form => {

        array1      => '',
        array2      => 'aaa',
        array3      => [1, 2, 'aaa', 4],

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

