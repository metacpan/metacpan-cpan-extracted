#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 22;
use Encode qw(decode encode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Encode',        qw(encode_utf8);
    use_ok 'Mojo::JSON',    qw(encode_json);
    use_ok 'Digest::MD5',   qw(md5_hex);
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'Mojolicious::Plugin::Vparam::Address';
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

note 'address';
{
    my ($full, $address, $lon, $lat, $md5, $id, $type, $lang, $opt) = (
        '  United States, New York : 42.93709 ,  -75.610703  ',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        undef,
        undef,
        undef,
        undef,
    );

    $t->app->routes->post("/test/address/vparam")->to(cb => sub {
        my ($self) = @_;

        is_deeply
            $self->vparam( address1 => 'address' ),
            [$address, $lon, $lat, $md5, $full, $id, $type, $lang, $opt],
            'address1';

        my $a = $self->vparam( address1 => 'address' );
        is $a->address,     $address,   'address';
        is $a->lon,         $lon,       'lon';
        is $a->lat,         $lat,       'lat';
        is $a->md5,         $md5,       'md5';
        is $self->verror('address1'), 0, 'address1 no error';

        is $self->vparam( address2 => 'address' ), undef,
            'address2 empty';
        is $self->verror('address2'), 'Wrong format', 'address2 error';

        is $self->vparam( address3 => 'address' ), undef,
            'address3 mossiong lat';
        is $self->verror('address3'), 'Wrong format', 'address3 error';

        is $self->vparam( address4 => 'address' ), undef,
            'address4 missing path';
        is $self->verror('address4'), 'Wrong format', 'address4 error';

        is $self->vparam( address5 => 'address' ), undef,
            'address5 empty path';
        is $self->verror('address5'), 'Wrong format', 'address5 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/vparam", form => {
        address1    => "  $address : $lon ,  $lat  ",
        address2    => '',
        address3    => "  $address : $lon , ",
        address4    => "$lon ,  $lat  ",
        address5    => "  :  $lon ,  $lat  ",
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

