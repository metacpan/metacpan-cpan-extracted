#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 10;
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

note 'maestro';
{
    $t->app->routes->post("/test/maestro/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( maestro0 => 'maestro' ),  undef,
            'maestro0 empty';
        is $self->verror('maestro0'),           'Value not set',
            'maestro0 error';

        is $self->vparam( maestro1 => 'maestro' ),  '1234567812345678',
            'maestro1 not clear';
        is $self->verror('maestro1'),           0,
            'maestro1 no error';

        is $self->vparam( maestro2 => 'maestro' ),  '123456781234567812',
            'maestro2 not clear';
        is $self->verror('maestro2'),           0,
            'maestro2 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/maestro/vparam", form => {
        maestro0   => '',
        maestro1   => '1234-5678-1234-5678-AA',
        maestro2   => '1234-5678-1234-5678-12',
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

