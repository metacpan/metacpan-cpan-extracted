#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 8;
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
        $self->plugin('Vparam', {phone_country => 7, phone_region => 495});
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'phone default values';
{
    $t->app->routes->post("/test/phone/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( phone1 => 'phone' ),  '+71234567890',
            'phone1 good';
        is $self->verror('phone1'),             0, 'phone1 no error';

        is $self->vparam( phone2 => 'phone' ),  '+74959876543',
            'phone2 auto add country and region';
        is $self->verror('phone2'),             0, 'phone2 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/phone/vparam", form => {
        phone1      => '+71234567890',
        phone2      => '9876543',
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

