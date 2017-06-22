#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 12;
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

note 'rename';
{
    $t->app->routes->post("/rename/simple")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1        => {type => 'int', as => 'my1'},
            int2        => {type => 'int', as => 'my2'},
            unknown     => {type => 'int', as => 'my3'},
        );
        is_deeply
            \%params,
            {my1 => undef, my2 => 123, my3 => undef},
            'all params renamed'
        ;

        is $self->vparam(int1       => 'int'), undef,   'int1';
        is $self->vparam(int2       => 'int'), 123,     'int2';
        is $self->vparam(unknown    => 'int'), undef,   'int3';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/rename/simple", form => {
        int1    => '',
        int2    => '123',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'rename json';
{
    $t->app->routes->post("/rename/json")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1    => {type => 'int', jpath => '/a/b', as => 'my0'},
            str1    => {type => 'str', jpath => '/a/c', as => 'my1'},
        );

        is_deeply \%params, {my0 => 123, my1 => 'abc'}, 'json rename';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/rename/json", ' {"a":{"b":123,"c":"abc"}}');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'rename xpath';
{
    $t->app->routes->post("/rename/xpath")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            Name => {type => 'str', xpath => '/Person/FirstName', as => 'name'},
        );

        is_deeply \%params, {name => 'Some Name'}, 'json xpath';

        $self->render(text => 'OK.');
    });

    $t->post_ok(
        "/rename/xpath",
        q{<?xml version="1.0" encoding="utf-8"?>
            <Person>
                <FirstName>
                    Some Name
                </FirstName>
            </Person>
        }
    );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

