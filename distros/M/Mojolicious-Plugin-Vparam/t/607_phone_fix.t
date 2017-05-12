#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 10;
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
        $self->plugin('Vparam', {phone_fix => 'ru'});
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'phone default values';
{
    $t->app->routes->post("/test/phone/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( phone0 => 'phone' ),  '+71234567890',
            'phone0 good';
        is $self->verror('phone0'),             0, 'phone0 no error';

        is $self->vparam( phone1 => 'phone' ),  '+81234567890',
            'phone1 nothng to fix';
        is $self->verror('phone1'),             0, 'phone1 no error';

        is $self->vparam( phone2 => 'phone' ),  '+71234567890',
            'phone2 fixed : ru';
        is $self->verror('phone2'),             0, 'phone2 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/phone/vparam", form => {
        phone0      => '+71234567890',
        phone1      => '+81234567890',

        phone2      => '81234567890',

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

