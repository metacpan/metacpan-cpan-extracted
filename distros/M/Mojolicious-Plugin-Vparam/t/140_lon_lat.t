#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 21;
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

note 'lon';
{
    $t->app->routes->post("/test/lon/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( lon0 => 'lon' ),  0,      'lon0 zero';
        is $self->verror('lon0'),           0,      'lon0 no error';

        is $self->vparam( lon1 => 'lon' ),  11.22,  'lon1 11.22';
        is $self->verror('lon1'),           0,      'lon1 no error';

        is $self->vparam( lon2 => 'lon' ),  undef,  'lon2 less';
        is $self->verror('lon2'), 'Value should not be less than -180°',
            'lon2 error';

        is $self->vparam( lon3 => 'lon' ),  undef,  'lon3 greater';
        is $self->verror('lon3'), 'Value should not be greater than 180°',
            'lon3 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/lon/vparam", form => {

        # Don`t dowble check numeric

        lon0    => 0,
        lon1    => '11.22',
        lon2    => '-200',
        lon3    => '200',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'lat';
{
    $t->app->routes->post("/test/lat/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( lat0 => 'lat' ),  0,      'lat0 zero';
        is $self->verror('lat0'),           0,      'lat0 no error';

        is $self->vparam( lat1 => 'lat' ),  11.22,  'lat1 11.22';
        is $self->verror('lat1'),           0,      'lat1 no error';

        is $self->vparam( lat2 => 'lat' ),  undef,  'lat2 less';
        is $self->verror('lat2'), 'Value should not be less than -90°',
            'lat2 error';

        is $self->vparam( lat3 => 'lat' ),  undef,  'lat3 greater';
        is $self->verror('lat3'), 'Value should not be greater than 90°',
            'lat3 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/lat/vparam", form => {

        # Don`t dowble check numeric

        lat0    => 0,
        lat1    => '11.22',
        lat2    => '-100',
        lat3    => '100',
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

