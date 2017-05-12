#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 22;
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

note 'hash';
{
    $t->app->routes->post("/test/hash/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply
            $self->vparam( hash1 => 'int', hash => '::' ),
            {a => 1, b => 2, c => 3},
            'hash1 = {a => 1, b => 2, c => 3}';

        is_deeply
            $self->vparam( hash2 => 'int', hash => 1 ),
            {a => 1, b => 2, c => 3},
            'hash2 = {a => 1, b => 2, c => 3}';

        is_deeply
            $self->vparam( hash3 => 'int', hash => 1 ),
            {a => 1},
            'hash3 = {a => 1}';

        is_deeply
            $self->vparam( hash4 => 'str' ),
            'a=>1',
            'hash4 not hash';

        is_deeply
            $self->vparam( hash5 => 'int', hash => '_' ),
            {a => 1, b => 2, c => 3},
            'hash5 = {a => 1, b => 2, c => 3}';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/hash/vparam", form => {

        hash1      => ['a::1', 'b::2', 'c::3'],
        hash2      => ['a=>1', 'b=>2', 'c=>3'],
        hash3      => 'a=>1',
        hash4      => 'a=>1',
        hash5      => ['a_1', 'b_2', 'c_3'],

    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'preudo type %...';
{
    $t->app->routes->post("/test/phash/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply
            $self->vparam( hash1 => '%int' ),
            {a => 1, b => 2, c => 3},
            'hash1 = {a => 1, b => 2, c => 3}';

        is_deeply
            $self->vparam( hash2 => '%int' ),
            {a => 1},
            'hash2 = {a => 1}';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/phash/vparam", form => {

        hash1      => ['a=>1', 'b=>2', 'c=>3'],
        hash2      => 'a=>1',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'broken hash';
{
    $t->app->routes->post("/test/bhash/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( 'hash1' => 'int', hash => 1 ), {},
            'hash1';
        is_deeply $self->vparam( 'hash2' => 'int', hash => 1 ), {},
            'hash2';
        is_deeply $self->vparam( 'hash3' => 'int', hash => 1 ),
            {a => 1, b => 2, c => undef, d => 4},
            'hash3';
        is_deeply $self->vparam( 'hash4' => 'int', hash => 1 ),
            {a => 1, b => 2, d => 4},
            'hash4';
        is_deeply $self->vparam( 'hash5' => 'int', hash => 1, skipundef => 1 ),
            {a => 1, b => 2, d => 4},
            'hash5';

        is_deeply $self->vparam( 'unknown' => 'int', hash => 1 ), {},
            'unknown';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/bhash/vparam", form => {

        hash1      => '',
        hash2      => 'aaa',
        hash3      => ['a=>1', 'b=>2', 'c=>aaa', 'd=>4'],
        hash4      => ['a=>1', 'b=>2', 'bbb', 'd=>4'],
        hash5      => ['a=>1', 'b=>2', 'c=>ddd', 'd=>4'],

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

