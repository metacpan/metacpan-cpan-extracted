#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 16;
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

note 'unknown';
{
    $t->app->routes->post("/unknown")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( unknown1 => 'int' ),  undef,
            'unknown1 undefined';
        is $self->verror('unknown1'), 'Value is not defined',
            'unknown1 int is in erros';

        is $self->vparam( unknown2 => 'bool' ),  0,
            'unknown2 0';
        is $self->verror('unknown2'), 0,
            'unknown2 bool not in erros';

        is $self->vparam( unknown_logic => 'logic' ),  undef,
            'unknown logic undefined';
        is $self->verror('unknown_logic'), 'Value is not defined',
            'unknown logic in erros';

        is $self->vparam( unknown3 => 'str' ),  undef,
            'unknown3 undefined';
        is $self->verror('unknown3'), 'Value is not defined',
            'unknown3 str is in erros';

        is $self->vparam( unknown4 => 'str', default => 'aaa' ),  'aaa',
            'unknown4 set';
        is $self->verror('unknown4'), 0,
            'unknown4 str with default is in erros';

        is $self->vparam( unknown5 => 'str', default => 'aaa', optional => 1 ),
            'aaa',
            'unknown5 set';
        is $self->verror('unknown5'), 0,
            'unknown5 str optional not in erros';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/unknown", form => {
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

