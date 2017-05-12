#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 18;
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

note 'password';
{
    $t->app->routes->post("/test/password/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( password0 => 'password' ),    undef,
            'password0 empty';
        is $self->verror('password0'),
            'The length should be greater than 8',
            'password0 error';

        is $self->vparam( password1 => 'password' ),    'aaa111bbb222 ccc333',
            'password1 good';
        is $self->verror('password1'),                  0,
            'password1 no error';

        is $self->vparam( password2 => 'password' ),    ' akdhdheu339eenx ',
            'password2 whitespace';
        is $self->verror('password2'),                  0,
            'password2 no error';

        is $self->vparam( password3 => 'password' ),    undef,
            'password3 short';
        is $self->verror('password3'),
            'The length should be greater than 8',
            'password3 error';

        is $self->vparam( password4 => 'password' ),    undef,
            'password4 digests only';
        is $self->verror('password4'),
            'Value must contain characters and digits',
            'password4 error';

        is $self->vparam( password5 => 'password' ),    undef,
            'password5 digests only';
        is $self->verror('password5'),
            'Value must contain characters and digits',
            'password5 error';

        is $self->vparam( password6 => 'password' ),    '★абвгдеёжзийклм123★',
            'password6 utf8';
        is $self->verror('password6'),                  0,
            'password6 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/password/vparam", form => {
        password0   => '',
        password1   => 'aaa111bbb222 ccc333',
        password2   => ' akdhdheu339eenx ',
        password3   => 'akdSJ6',
        password4   => '1093846293747929474',
        password5   => 'akdhfdhweocAHSHDU',
        password6   => '★абвгдеёжзийклм123★',
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

