#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 9;
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

note 'vparam';
{
    $t->app->routes->post("/test/complex/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int1 => 'int' ), undef,
            'int1 simple = undef';
        is $self->vparam( int1 => {type => 'int'} ), undef,
            'int1 full = undef';

        is $self->vparam( int1 => {type => 'int', default => 100500}), 100500,
            'int1 full = 100500';
        is $self->vparam( int1 => 'int', default => 100500), 100500,
            'int1 complex = 100500';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/complex/vparam", form => {
        int1    => '',
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

