#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 23;
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

note 'isin';
{
    $t->app->routes->post("/test/isin/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( isin0 => 'isin' ),  undef,
            'isin0 empty';
        is $self->verror('isin0'),           'Value not set',
            'isin0 error';

        is $self->vparam( isin1 => 'isin' ),  undef,
            'isin1 bad';
        is $self->verror('isin1'),           'Checksum error',
            'isin1 error';

        is $self->vparam( isin2 => 'isin' ),  '4000000000006',
            'isin2 not clear';
        is $self->verror('isin2'),           0,
            'isin2 no error';
        ok $self->vparam( isin2 => 'isin', regexp => qr{^4} ),
            'isin2 is Visa';

        is $self->vparam( isin3 => 'isin' ),  '5610000000000001',
            'isin3 full digits';
        is $self->verror('isin3'),           0,
            'isin3 no error';

        is $self->vparam( isin4 => 'isin' ),  'RU0007661625',
            'isin4 with letters';
        is $self->verror('isin4'),           0,
            'isin4 no error';

        is $self->vparam( isin5 => 'isin' ),  'DE0001136927',
            'isin5 with letters';
        is $self->verror('isin5'),           0,
            'isin5 no error';

        is $self->vparam( isin6 => 'isin' ),  'US0378331005',
            'isin6 with letters';
        is $self->verror('isin6'),           0,
            'isin6 no error';

        is $self->vparam( isin7 => 'isin' ),  'AU0000XVGZA3',
            'isin7 with letters';
        is $self->verror('isin7'),           0,
            'isin7 no error';

        is $self->vparam( isin8 => 'isin' ),  'GB0002634946',
            'isin8 with letters';
        is $self->verror('isin8'),           0,
            'isin8 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/isin/vparam", form => {
        isin0   => '',
        isin1   => '4000000000007',
        isin2   => '4000-0000-0000-6',
        isin3   => '5610000000000001',
        isin4   => 'RU0007661625',
        isin5   => 'de0001136927',
        isin6   => 'US0378331005',
        isin7   => 'AU0000XVGZA3',
        isin8   => 'GB0002634946',
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

