#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 11;
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

note 'vclass';
{
    $t->app->routes->post("/test/vclass")->to( cb => sub {
        my ($self) = @_;

        ok ! $self->vparam( int1 => 'int'),
            'int1 no value';
        is $self->vclass('int1'), 'field-with-error',
            'int1 vclass not empty';
        is $self->vclass('int1', 'invalid', 'error'),
            'field-with-error invalid error', 'int1 vclass additional classes';

        is $self->vparam( int2 => 'int'), 123,
            'int2 has value';
        is $self->vclass('int2'), '',
            'int1 vclass empty string';
        is $self->vclass('int2', 'invalid', 'error'), '',
            'int1 vclass steel empty string';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/vclass", form => {
        int1    => 'abc',
        int2    => '123',
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

