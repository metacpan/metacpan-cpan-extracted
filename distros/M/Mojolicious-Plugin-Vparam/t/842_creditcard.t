#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 14;
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

note 'creditcard';
{
    $t->app->routes->post("/test/creditcard/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( creditcard0 => 'creditcard' ),  undef,
            'creditcard0 empty';
        is $self->verror('creditcard0'),           'Value not set',
            'creditcard0 error';

        is $self->vparam( creditcard1 => 'creditcard' ),  undef,
            'creditcard1 empty';
        is $self->verror('creditcard1'),           'Wrong format',
            'creditcard1 error';

#        is $self->vparam( creditcard1 => 'creditcard' ),  '1234567812345678',
#            'creditcard1 not clear';
#        is $self->verror('creditcard1'),           0,
#            'creditcard1 no error';

        is $self->vparam( creditcard2 => 'creditcard' ),  '123456781234567812',
            'creditcard2 not clear';
        is $self->verror('creditcard2'),           0,
            'creditcard2 no error';

        is $self->vparam( creditcard3 => 'creditcard' ),  '5610000000000001',
            'creditcard3 isin';
        is $self->verror('creditcard3'),           0,
            'creditcard3 no error';

        is $self->vparam( creditcard4 => 'creditcard' ),  undef,
            'creditcard4 isin not creditcard';
        is $self->verror('creditcard4'),           'Wrong format',
            'creditcard4 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/creditcard/vparam", form => {
        creditcard0   => '',
        creditcard1   => '1234-5678-1234-5678-AA',
        creditcard2   => '1234-5678-1234-5678-12',
        creditcard3   => '5610-0000-0000-0001',
        creditcard4   => 'RU0007661625',
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

