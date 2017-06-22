#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 5;
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

note 'isa';
{
    $t->app->routes->post("/isa")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1 => {type   => 'int'},
            int2 => {isa    => 'int'},
        );
        is_deeply \%params, {int1 => 123, int2 => 234},   'isa';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/isa", form => {
        int1    => '  123  ',
        int2    => '  234  ',
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

