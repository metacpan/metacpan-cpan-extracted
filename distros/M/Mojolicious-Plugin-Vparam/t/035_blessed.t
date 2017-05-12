#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 15;
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

note 'blessed';
{
    $t->app->routes->post("/blessed")->to( cb => sub {
        my ($self) = @_;

        my $url1 = $self->vparam(url1 => 'url',  blessed => 1);
        isa_ok $url1, 'Mojo::URL';
        is $url1->to_string, 'http://abc.com', 'url1';

        my $url2 = $self->vparam(url2 => '@url',  blessed => 1);
        isa_ok $url2->[0], 'Mojo::URL';
        isa_ok $url2->[1], 'Mojo::URL';
        is_deeply
            [ $url2->[0]->to_string, $url2->[1]->to_string ],
            ['http://abc.com', 'http://def.com'],
            'url2'
        ;

        $self->render(text => 'OK.');
    });

    $t->post_ok("/blessed", form => {
        url1    => 'http://abc.com',
        url2    => ['http://abc.com', 'http://def.com'],
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'not blessed';
{
    $t->app->routes->post("/not/blessed")->to( cb => sub {
        my ($self) = @_;

        my $url1 = $self->vparam(url1 => 'url',  blessed => 0);
        is ref($url1), '', 'url1 scalar';
        is $url1, 'http://abc.com', 'url1';

        my $url2 = $self->vparam(url2 => '@url',  blessed => 0);
        is ref($url2->[0]), '', 'url2[0] scalar';
        is ref($url2->[1]), '', 'url2[1] scalar';
        is_deeply
            [ $url2->[0], $url2->[1] ],
            ['http://abc.com', 'http://def.com'],
            'url2'
        ;

        $self->render(text => 'OK.');
    });

    $t->post_ok("/not/blessed", form => {
        url1    => 'http://abc.com',
        url2    => ['http://abc.com', 'http://def.com'],
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

