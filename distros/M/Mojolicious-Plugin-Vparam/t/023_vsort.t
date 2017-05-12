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
        $self->log->level( $ENV{MOJO_LOG_LEVEL} = 'warn' );
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'vsort default values';
{
    $t->app->routes->post("/test/default/vsort")->to( cb => sub {
        my ($self) = @_;

        is $self->vsort()->{page}, 1,                'page = 1';
        is $self->vsort()->{oby}, 1,                 'oby = 1';
        is $self->vsort()->{ods}, 'ASC',             'ods = ASC';
        is $self->vsort()->{rws}, 25,                'rws = 25';

        is $self->vsort(-sort => ['col1', 'col2'])->{oby}, 'col1',
            'oby = "col1"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/default/vsort", form => {})-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort not default values';
{
    $t->app->routes->post("/test/nodefault/vsort")->to( cb => sub {
        my ($self) = @_;

        is $self->vsort()->{page}, 2,       'page = 2';
        is $self->vsort()->{oby}, '4',      'oby = 4';
        is $self->vsort()->{ods}, 'DESC',   'ods = DESC';
        is $self->vsort()->{rws}, 53,       'rws = 53';

        is $self->vsort(
            -sort => ['col1', 'col2', 'col3', 'col4']
        )->{oby}, 'col4', 'oby="col4"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/nodefault/vsort", form => {
        page    => 2,
        oby     => 3,
        ods     => 'desc',
        rws     => 53,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort errors';
{
    $t->app->routes->post("/test/errors/vsort")->to( cb => sub {
        my ($self) = @_;

        my $exception = '';
        local $SIG{__DIE__} = sub { $exception = $_[0] };

        eval { $self->vsort(-sort => '') };
        ok $exception, 'exception';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/errors/vsort", form => {})-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

