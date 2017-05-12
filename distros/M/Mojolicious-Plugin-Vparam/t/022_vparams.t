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

note 'vparams';
{
    $t->app->routes->post("/test/1/vparams")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vparams(int6 => 'int', str5 => 'str'), 'HASH';
        is $self->vparams(int6 => 'int', str5 => 'str')->{int6}, 555,
            'int6=555';
        is $self->vparams(int6 => 'int', str5 => 'str')->{str5}, 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/1/vparams", form => {
        int6    => 555,
        str5    => 'kkll',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'more vparams';
{
    $t->app->routes->post("/test/2/vparams")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vparams(int6 => 'int', str5 => 'str'), 'HASH';
        is $self->vparams(int6 => 'int', str5 => 'str')->{int6}, 555,
            'int6=555';
        is $self->vparams(int6 => 'int', str5 => 'str')->{str5}, 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/2/vparams", form => {
        int6    => 555,
        str5    => 'kkll',
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

