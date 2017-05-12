#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 18;
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

note 'inn';
{
    $t->app->routes->post("/test/inn/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( inn0 => 'inn' ),  undef,
            'inn0 empty';
        is $self->verror('inn0'),           'Value not set',
            'inn0 error';

        is $self->vparam( inn1 => 'inn' ),  undef,
            'inn1 not a number';
        is $self->verror('inn1'),           'Wrong format',
            'inn1  error';

        is $self->vparam( inn2 => 'inn' ),  '7804337423',
            'inn2 length 10';
        is $self->verror('inn2'),           0,
            'inn2 no error';

        is $self->vparam( inn3 => 'inn' ),  '110102185800',
            'inn3 length 12';
        is $self->verror('inn3'),           0,
            'inn3 no error';

        is $self->vparam( inn4 => 'inn' ),  undef,
            'inn4 error length';
        is $self->verror('inn4'),           'Wrong format',
            'inn4 error';

        is $self->vparam( inn5 => 'inn' ),  undef,
            'inn5 crc length 10';
        is $self->verror('inn5'),           'Checksum error',
            'inn5 error';

        is $self->vparam( inn6 => 'inn' ),  undef,
            'inn6 crc length 12';
        is $self->verror('inn6'),           'Checksum error',
            'inn6 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/inn/vparam", form => {
        inn0    => '',
        inn1    => 'aaa111bbb222 ccc333',
        inn2    => ' 7804337423 ',
        inn3    => ' 110102185800  ',
        inn4    => '1101021858002',
        inn5    => '0000000001',
        inn6    => '000000000001',
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

