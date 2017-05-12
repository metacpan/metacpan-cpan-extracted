#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 62;

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'Digest::MD5', qw(md5_hex);
    use Encode qw(decode encode encode_utf8);
}

note 'address not signed';
{
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

    my ($full, $address, $lon, $lat, $id, $type, $lang, $opt) = (
        'United States, New York:42.93709,-75.610703 ',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        undef,
        undef,
        undef,
    );
    my $md5 = md5_hex 'SECRET' . $full;

    $t->app->routes->post("/test/address/vparam")->to( cb => sub {
        my ($self) = @_;

        my $a1 = $self->vparam( address1 => 'address' );
        is $a1->address,    $address,   'address1';
        is $a1->lon,        $lon,       'lon';
        is $a1->lat,        $lat,       'lat';
        is $a1->md5,        undef,      'md5';
        is $self->verror('address1'), 0, 'address1 no error';

        my $a2 = $self->vparam( address2 => 'address' );
        is $a2->address,    $address,   'address2';
        is $a2->lon,        $lon,       'lon';
        is $a2->lat,        $lat,       'lat';
        is $a2->md5,        '',         'md5';
        is $self->verror('address2'), 0, 'address2 no error';

        my $a3 = $self->vparam( address3 => 'address' );
        is $a3->address,    $address,   'address3';
        is $a3->lon,        $lon,       'lon';
        is $a3->lat,        $lat,       'lat';
        is $a3->md5,        $md5,       'md5';
        is $self->verror('address3'), 0, 'address3 no error';

        my $a4 = $self->vparam( address4 => 'address' );
        is $a4->address,    $address,   'address4';
        is $a4->lon,        $lon,       'lon';
        is $a4->lat,        $lat,       'lat';
        is $a4->md5,        'BAD',      'md5';
        is $self->verror('address4'), 0, 'address4 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/vparam", form => {
        address1    => "$address:$lon,$lat",
        address2    => "$address:$lon,$lat []",
        address3    => "$address:$lon,$lat [$md5]",
        address4    => "$address:$lon,$lat [BAD]",
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address signed';
{
    {
        package MyApp2;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('Vparam', {address_secret => 'SECRET'});
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp2');
    ok $t, 'Test Mojo created with address signing';

    my ($full, $address, $lon, $lat, $id, $type, $lang, $opt) = (
        'United States, New York:42.93709,-75.610703 ',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        undef,
        undef,
        undef,
    );
    my $md5 = md5_hex 'SECRET' . $full;

    $t->app->routes->post("/test/saddress/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( address1 => 'address' ), undef,
            'address1';
        is $self->verror('address1'), 'Unknown source', 'address1 error';

        is $self->vparam( address2 => 'address' ), undef,
            'address2';
        is $self->verror('address2'), 'Unknown source', 'address2 error';

        my $a3 = $self->vparam( address3 => 'address' );
        is $a3->address,    $address,   'address3';
        is $a3->lon,        $lon,       'lon';
        is $a3->lat,        $lat,       'lat';
        is $a3->md5,        $md5,       'md5';
        is $self->verror('address3'), 0, 'address3 no error';

        is $self->vparam( address4 => 'address' ), undef,
            'address4';
        is $self->verror('address1'), 'Unknown source', 'address4 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/saddress/vparam", form => {
        address1    => "$address:$lon,$lat",
        address2    => "$address:$lon,$lat []",
        address3    => "$address:$lon,$lat [$md5]",
        address4    => "$address:$lon,$lat [BAD]",
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address signed utf8';
{
    {
        package MyApp4;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('Vparam', {address_secret => 'SECRET'});
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp4');
    ok $t, 'Test Mojo created with address signing';

    my ($full, $address, $lon, $lat, $id, $type, $lang, $opt) = (
        'Российская Федерация, Москва, Радужная улица, 10:37.669342, 55.860691 ',
        'Российская Федерация, Москва, Радужная улица, 10',
        37.669342,
        55.860691,
        undef,
        undef,
        undef,
        undef,
    );
    my $md5 = md5_hex( encode_utf8( 'SECRET' . $full ) );

    $t->app->routes->post("/test/address/utf8/vparam")->to( cb => sub {
        my ($self) = @_;

        my $a1 = $self->vparam( address1 => 'address' );
        is $a1->address,    $address,   'address1';
        is $a1->lon,        $lon,       'lon';
        is $a1->lat,        $lat,       'lat';
        is $a1->md5,        $md5,       'md5';
        is $self->verror('address1'), 0, 'address1 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/utf8/vparam", form => {
        address1 => "$address:$lon, $lat [$md5]",
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address real examples';
{
    {
        package MyApp3;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('Vparam', {
                address_secret => 'jinEbAupnillejotcoiletKidgoballOacGaiWyn'
            });
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp3');
    ok $t, 'Test Mojo created with address signing';

    $t->app->routes->post("/test/address/real/vparam")->to( cb => sub {
        my ($self) = @_;

        my $a1 = $self->vparam( address1 => 'address' );
        is $a1->address,    'Россия, Москва, Радужная улица, 10',   'address1';
        is $a1->lon,        '37.669342',                            'lon';
        is $a1->lat,        '55.860691',                            'lat';
        is $a1->md5,        'bd5511e30b99ea1275e91c1b47299c6d',     'md5';
        is $self->verror('address1'), 0, 'address1 no error';

        my $a2 = $self->vparam( address2 => 'address' );
        is $a2->address,    'Россия, Москва, Радужная улица, 10',   'address2';
        is $a2->lon,        '37.669342',                            'lon';
        is $a2->lat,        '55.860691',                            'lat';
        is $a2->md5,        '14cbc10460ac83061e11ed27a3683604',     'md5';
        is $self->verror('address2'), 0, 'address2 no error';

        my $a3 = $self->vparam( address3 => 'address' );
        is $a3->address,    'Россия, Москва, Воронежская улица, 10','address3';
        is $a3->lon,        '37.726834',                            'lon';
        is $a3->lat,        '55.609024',                            'lat';
        is $a3->md5,        '251de495d398119e0146bb1b1bb02810',     'md5';
        is $self->verror('address3'), 0, 'address3 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/real/vparam", form => {
        address1 =>
            'Россия, Москва, Радужная улица, 10:37.669342, 55.860691'.
            '[bd5511e30b99ea1275e91c1b47299c6d]',
        address2 =>
            'Россия, Москва, Радужная улица, 10:37.669342,55.860691'.
            '[14cbc10460ac83061e11ed27a3683604]',
        address3 =>
            'Россия, Москва, Воронежская улица, 10:37.726834, 55.609024'.
            '[251de495d398119e0146bb1b1bb02810]',
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

