#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 8;
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

note 'load by default';
{
    $t->app->routes->post("/load")->to( cb => sub {
        my ($self) = @_;

        is( DateTime->can('new'), undef, 'DateTime not loaded');

        my %params = $self->vparams(
            int1        => {
                type    => 'int',
                load    => sub{ require DateTime },
            },
        );
        is $self->verrors, 0, 'no bugs';

        is $params{int1},       12345, 'int1';
        ok ref DateTime->can('new'), 'DateTime loaded';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/load", form => {
        int1    => '12345',
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

