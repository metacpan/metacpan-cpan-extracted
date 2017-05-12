#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 25;
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

note 'jpath optional arrays';
{
    $t->app->routes->post("/test/jpath/optional/arrays")->to( cb => sub {
        my ($self) = @_;

        is
            $self->vparam(v1 => { type => '?str',  jpath => '/abc'}),
            'cde',
            'not array';
        ;
        is $self->verror('v1'), 0,   'v1 not error';

        is_deeply
            $self->vparam(v2 => { type => '?@str', jpath => '/def'}),
            ['hij'],
            'array from scalar';
        ;
        is $self->verror('v2'), 0,   'v2 not error';

        is_deeply
            $self->vparam(v3 => { type => '?@str', jpath => '/klm'}),
            ["nop", "qrs"],
            'array from array. we don`t support json multikey.'
        ;
        is $self->verror('v3'), 0,   'v3 not error';

        is_deeply
            $self->vparam(v4 => { type => '?@str', jpath => '/unknown'}),
            [],
            'empty array if optional not exists'
        ;
        is $self->verror('v4'), 0,   'v4 not error';

        is_deeply
            $self->vparam(v5 => { type => '?@str', jpath => '/cvb'}),
            [],
            'empty array'
        ;
        is $self->verror('v5'), 0,   'v5 not error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/jpath/optional/arrays", '{
       "abc": "cde",
       "def": "hij",
       "klm": [ "nop", "qrs" ],
       "cvb": []
    }');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'jpath required arrays';
{
    $t->app->routes->post("/test/jpath/required/arrays")->to( cb => sub {
        my ($self) = @_;

        is
            $self->vparam(v1 => { type => 'str',  jpath => '/abc'}),
            'cde',
            'not array';
        ;
        is $self->verror('v1'), 0,   'v1 not error';

        is_deeply
            $self->vparam(v2 => { type => '@str', jpath => '/def'}),
            ['hij'],
            'array from scalar';
        ;
        is $self->verror('v2'), 0,   'v2 not error';

        is_deeply
            $self->vparam(v3 => { type => '@str', jpath => '/klm'}),
            ["nop", "qrs"],
            'array from array. we don`t support json multikey.'
        ;
        is $self->verror('v3'), 0,   'v3 not error';

        is_deeply
            $self->vparam(v4 => { type => '@str', jpath => '/unknown'}),
            [],
            'empty array if optional not exists'
        ;
        is $self->verror('v4'), 1,   'v4 error';

        is_deeply
            $self->vparam(v5 => { type => '?@str', jpath => '/cvb'}),
            [],
            'empty array'
        ;
        is $self->verror('v5'), 0,   'v5 not error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/jpath/required/arrays", '{
       "abc": "cde",
       "def": "hij",
       "klm": [ "nop", "qrs" ],
       "cvb": []
    }');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

