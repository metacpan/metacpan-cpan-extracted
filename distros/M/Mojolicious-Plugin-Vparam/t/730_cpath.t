#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 20;
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

note 'cpath body empty';
{
    $t->app->routes->post("/test/cpath/empty/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', cpath => 'a > b > c' ),
            undef,                                          'int0 empty';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/cpath/empty/vparam", '');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cpath not good';
{
    $t->app->routes->post("/test/cpath/not/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', cpath => 'a > b > c' ),
            undef,                                          'int0 empty';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok(
        "/test/cpath/not/vparam",
        q{<?xml version="1.0" encoding="utf-8"?>
            <a>
                <b>
                </b>
            </a>
        }
    );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cpath good';
{
    $t->app->routes->post("/test/cpath/good/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', cpath => 'a > b > c' ),
            3,                                              'int0 ok';
        is $self->verror('int0'), 0,                        'int0 no error';

        my $reparse = 0;
        my $old = \&Mojolicious::Plugin::Vparam::DOM::parse_dom;
        {
            no warnings 'redefine';
            *Mojolicious::Plugin::Vparam::DOM::parse_dom = sub($){$reparse = 1};
        }


        is $self->vparam( int1 => 'int', cpath => 'a > b > d' ),
            4,                                              'int1 ok';
        is $self->verror('int0'), 0,                        'int1 no error';

        {
            no warnings 'redefine';
            *Mojolicious::Plugin::Vparam::DOM::parse_dom = $old;
        }
        is $reparse, 0, 'Do not re-parse';

        $self->render(text => 'OK.');
    });

    $t->post_ok(
        "/test/cpath/good/vparam",
        q{<?xml version="1.0" encoding="utf-8"?>
            <a>
                <b>
                    <c>3</c>
                    <d>4</d>
                </b>
            </a>
        }
    );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cpath invalid';
{
    $t->app->routes->post("/test/cpath/invalid/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', cpath => 'a > b > c' ),
            undef,                                          'int0 empty';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        is $self->vparam( int1 => 'int', cpath => 'a > b > d' ),
            undef,                                          'int0 empty';
        is $self->verror('int1'), 'Value is not defined',   'int0 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok(
        "/test/cpath/invalid/vparam",
        q{<?xml version="1.0" encoding="utf-8"?>
            <a>
                <b>
                    <c>abc</c>
                    <d></d>
                </b>
            </a>
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

