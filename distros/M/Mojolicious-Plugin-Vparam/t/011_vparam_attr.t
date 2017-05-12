#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 7;
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

note 'not exists';
{
    $t->app->routes->post("/test/not_exists/vparam")->to( cb => sub {
        my ($self) = @_;

        SKIP: {
            skip 'need to fix', 1;

            eval{ $self->vparam( some => 'int', attr_unknown => 1 ) };
            ok $@, 'die on unknown attribute';
        }

        eval{ $self->vparam( some => 'unknown_type' ) };
        ok $@, 'die on unknown type';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/not_exists/vparam", form => {
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

