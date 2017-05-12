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

note 'barcode';
{
    $t->app->routes->post("/test/barcode/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( barcode0 => 'barcode' ),  undef,
            'barcode0 empty';
        is $self->verror('barcode0'),           'Value not set',
            'barcode0 error';

        is $self->vparam( barcode1 => 'barcode' ),  undef,
            'barcode1 bad';
        is $self->verror('barcode1'),           'Checksum error',
            'barcode1 error';

        is $self->vparam( barcode2 => 'barcode' ),  '4600051000057',
            'barcode2 EAN-13';
        is $self->verror('barcode2'),           0,
            'barcode2 no error';

        is $self->vparam( barcode3 => 'barcode' ),  '46009333',
            'barcode3 EAN-8';
        is $self->verror('barcode3'),           0,
            'barcode3 no error';

        is $self->vparam( barcode4 => 'barcode' ),  '041689300494',
            'barcode4 UTC-12';
        is $self->verror('barcode4'),           0,
            'barcode4 no error';

        is $self->vparam( barcode5 => 'barcode' ),  '98765432109213',
            'barcode5 ITF-14';
        is $self->verror('barcode5'),           0,
            'barcode5 no error';

        is $self->vparam( barcode6 => 'barcode' ),  '9781565924796',
            'barcode6 EAN 5';
        is $self->verror('barcode6'),           0,
            'barcode6 no error';

        is $self->vparam( barcode7 => 'barcode' ),  '9770317847001',
            'barcode7 EAN 2';
        is $self->verror('barcode7'),           0,
            'barcode7 no error';

        is $self->vparam( barcode8 => 'barcode' ),  '987654321098',
            'barcode8 UPC';
        is $self->verror('barcode8'),           0,
            'barcode8 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/barcode/vparam", form => {
        barcode0   => '',
        barcode1   => '4600051000058',
        barcode2   => '4600051000057',
        barcode3   => '46009333',
        barcode4   => '041689300494',
        barcode5   => '98765432109213',
        barcode6   => '9781565924796',
        barcode7   => '9770317847001',
        barcode8   => '987654321098',
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

