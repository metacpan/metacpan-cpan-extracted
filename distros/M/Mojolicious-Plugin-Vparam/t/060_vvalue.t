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
        $self->log->level( $ENV{MOJO_LOG_LEVEL} = 'warn' );
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'vvalue';
{
    $t->app->routes->post("/test/vvalue")->to( cb => sub {
        my ($self) = @_;

        is $self->vvalue('before1'), undef,
            'before1 first time use return undef';
        is $self->vvalue('before2', 'abcdf'), 'abcdf',
            'before2 first time use return default';

        ok ! $self->vparam( int1 => 'int'),
            'int1 no value';
        is $self->vvalue('int1'), 'abc',
            'int1 vvalue original';

        is $self->vparam( int2 => 'int'), '123',
            'int2 has value';
        is $self->vvalue('int2'), '123',
            'int2 vvalue original';

        is_deeply $self->vparam( int3 => 'int'), [1,2,3],
            'int3 has array value';
        is_deeply $self->vvalue('int3'), [1,2,3],
            'int3 vvalue original';

        is $self->vparam( unknown => 'int'), undef,
            'unknown has no value';
        is $self->vvalue('unknown'), undef,
            'unknown vvalue no value';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/vvalue", form => {
        int1    => 'abc',
        int2    => '123',
        int3    => [1,2,3],
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

