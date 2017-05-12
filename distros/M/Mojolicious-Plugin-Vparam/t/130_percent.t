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

note 'percent';
{
    $t->app->routes->post("/test/percent/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( percent0 => 'percent' ),  0,      'percent0 zero';
        is $self->verror('percent0'),               0,      'percent0 no error';

        is $self->vparam( percent1 => 'percent' ),  100,    'percent1 100';
        is $self->verror('percent1'),               0,      'percent1 no error';

        is $self->vparam( percent2 => 'percent' ),  55.66,  'percent2 55.66';
        is $self->verror('percent2'),               0,      'percent2 no error';

        is $self->vparam( percent3 => 'percent' ),  undef,  'percent3 truncated decimal';
        is $self->verror('percent3'), 'Value must be greater than 0',
            'percent3 error';

        is $self->vparam( percent4 => 'percent' ),  undef,  'percent4 zero decimal';
        is $self->verror('percent4'), 'Value must be less than 100',
            'percent4 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/percent/vparam", form => {

        # Don`t dowble check numeric

        percent0    => 0,
        percent1    => 100,
        percent2    => 55.66,
        percent3    => -1,
        percent4    => 101,
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

