#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 21;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'Mojo::URL';
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

note 'url';
{
    $t->app->routes->post("/test/url/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( url1 => 'url' ),  undef,      'url1 empty';
        is $self->verror('url1'), 'Value is not set',   'url1 error';

        is $self->vparam( url2 => 'url' ),  undef,      'url2 no host';
        is $self->verror('url2'), 'Host not set',       'url2 error';

        is $self->vparam( url3 => 'url' ),
            'http://a.ru',                              'url3 http';
        is $self->verror('url3'),           0,          'url3 no error';

        is $self->vparam( url4 => 'url' ),
            'https://a.ru',                             'url4 https';
        is $self->verror('url4'),           0,          'url4 no error';

        SKIP: {
            skip 'New mojo don`t make lowercase. This is not important.', 2;

        is $self->vparam( url5 => 'url' ),
            'http://aa-bb.cc.ru?b=1',                   'url5 lower case query';
        is $self->verror('url5'),           0,          'url5 no error';
        }

        is $self->vparam( url6 => 'url' ),
            'http://a.ru?b=1',                          'url6 whitespace';
        is $self->verror('url6'),           0,          'url6 no error';

        is $self->vparam( url7 => 'url' ), undef,       'url7 no proto';
        is $self->verror('url7'), 'Protocol not set',   'url7 error';

        is $self->vparam( unknown1 => 'url' ), undef,       'unknown1';
        is $self->verror('unknown1'), 'Value not defined',  'unknown1 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/url/vparam", form => {
        url1        => '',
        url2        => 'http://',
        url3        => 'http://a.ru',
        url4        => 'https://a.ru',
        url5        => 'http://aA-bB.Cc.ru?b=1',
        url6        => '  http://a.ru?b=1  ',
        url7        => 'a.ru'
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

