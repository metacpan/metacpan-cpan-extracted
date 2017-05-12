#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 13;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'Mail::RFC822::Address';
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

note 'email';
{
    $t->app->routes->post("/test/email/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( email1 => 'email' ),  undef,      'email1 empty';
        is $self->verror('email1'), 'Value is not set',     'email1 error';

        is $self->vparam( email2 => 'email' ),  undef,      'email2 string';
        is $self->verror('email2'), 'Wrong format',         'email2 error';

        is $self->vparam( email3 => 'email' ),  'a@b.ru',   'email3 = "a@b.ru"';
        is $self->verror('email3'),             0,          'email3 no error';

        is $self->vparam( email4 => 'email' ),  'a@b.ru',   'email4 = "a@b.ru"';
        is $self->verror('email4'),             0,          'email4 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/email/vparam", form => {
        email1      => '',
        email2      => 'aaa',
        email3      => 'a@b.ru',
        email4      => '  a@b.ru  ',
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

