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

note 'money';
{
    $t->app->routes->post("/test/money/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( money0 => 'money' ),  0,      'money0 zero';
        is $self->verror('money0'),             0,      'money0 no error';

        is $self->vparam( money1 => 'money' ),  111.22, 'money1 full decimal';
        is $self->verror('money1'),             0,      'money1 no error';

        is $self->vparam( money2 => 'money' ),  111.2,  'money2 short decimal';
        is $self->verror('money2'),             0,      'money2 no error';

        is $self->vparam( money3 => 'money' ),  111.0,  'money3 truncated decimal';
        is $self->verror('money3'),             0,      'money3 no error';

        is $self->vparam( money4 => 'money' ),  111.0,  'money4 zero decimal';
        is $self->verror('money4'),             0,      'money4 no error';

        is $self->vparam( money5 => 'money' ),  undef,  'money5 crop decimal';
        is $self->verror('money5'),             'Invalid fractional part',
                                                        'money5 error';

        is $self->vparam( money6 => 'money' ),  111.33, 'money6';
        is $self->verror('money6'),             0,      'money6 no error';

        is $self->vparam( money7 => 'money' ),  111.44, 'money7';
        is $self->verror('money7'),             0,      'money7 no error';

        is $self->vparam( money8 => 'money' ),  111.77, 'money8';
        is $self->verror('money8'),             0,      'money8 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/money/vparam", form => {

        # Don`t dowble check numeric

        money0    => 0,
        money1    => 111.22,
        money2    => 111.2,
        money3    => 111.,
        money4    => 111.0,
        money5    => 111.222,
        money6    => '111,33',
        money7    => ' 111.44 usd ',
        money8    => '111,77.88',
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

