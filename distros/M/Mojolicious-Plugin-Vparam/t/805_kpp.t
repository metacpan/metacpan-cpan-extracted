#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 12;
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

note 'kpp';
{
    $t->app->routes->post("/test/kpp/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( kpp0 => 'kpp' ),  undef,
            'kpp0 empty';
        is $self->verror('kpp0'),           'Value not set',
            'kpp0 error';

        is $self->vparam( kpp1 => 'kpp' ),  undef,
            'kpp1 not a number';
        is $self->verror('kpp1'),           'Wrong format',
            'kpp1  error';

        is $self->vparam( kpp2 => 'kpp' ),  '370601001',
            'kpp2 length 9';
        is $self->verror('kpp2'),           0,
            'kpp2 no error';

        is $self->vparam( kpp3 => 'kpp' ),  undef,
            'kpp3 length 10';
        is $self->verror('kpp3'),           'Wrong format',
            'kpp3 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/kpp/vparam", form => {
        kpp0    => '',
        kpp1    => 'aaa111bbb222 ccc333',
        kpp2    => ' 370601001 ',
        kpp3    => ' 3706010012  ',
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

