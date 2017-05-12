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

note 'vfilter';
{
    $t->app->routes->post("/test/vfilter")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vfilter(myfilter => sub {
                $_[1] eq $_[2] ? 0 : 'Invalid'
        } ), 'CODE', 'myfilter set';

        is $self->vparam( param1 => {myfilter => '123'} ), 123,
            'param1 equal';
        is $self->verror( 'param1'), 0,
            'param1 no error';

        is $self->vparam( param2 => {myfilter => '123'} ), undef,
            'param2 not equal';
        is $self->verror( 'param2'), 'Invalid',
            'param2 error';

        isa_ok $self->vfilter('myfilter'), 'CODE', 'myfilter get';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/vfilter", form => {
        param1    => '123',
        param2    => '321',
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

