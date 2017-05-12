#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 26;
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

note 'phone';
{
    $t->app->routes->post("/test/phone/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( phone1 => 'phone' ),  '+71234567890',
            'phone1 good';
        is $self->verror('phone1'),             0, 'phone1 no error';

        is $self->vparam( phone2 => 'phone' ),  '+71234567890',
            'phone2 fix: add +';
        is $self->verror('phone2'),             0, 'phone2 no error';

        is $self->vparam( phone3 => 'phone' ),  undef,
            'phone3 no codes';
        is $self->verror('phone3'), 'Value not defined', 'phone3 no error';

        is $self->vparam( phone4 => 'phone' ),  undef, 'phone4 empty';
        is $self->verror('phone4'), 'Value not defined', 'phone4 error';

        is $self->vparam( phone5 => 'phone' ),  undef, 'phone5 not a phone';
        is $self->verror('phone5'), 'Value not defined', 'phone5 error';

        is $self->vparam( phone6 => 'phone' ),  undef, 'phone6 too long';
        is $self->verror('phone6'),
            'The number should be no more than 16 digits', 'phone6 error';

        is $self->vparam( phone7 => 'phone' ),  '+74954567890w123',
            'phone7 additional wait';
        is $self->verror('phone7'),             0, 'phone7 no error';

        is $self->vparam( phone8 => 'phone' ),  '+71234567890w1234',
            'phone8 additional wait .';
        is $self->verror('phone8'),             0, 'phone8 no error';

        is $self->vparam( phone9 => 'phone' ),  '+71234567890w1234',
            'phone9 additional wait ,';
        is $self->verror('phone9'),             0, 'phone9 no error';

        is $self->vparam( phone10 => 'phone' ),  '+71234567890w1234',
            'phone10 additional wait something';
        is $self->verror('phone10'),            0, 'phone10 no error';

        is $self->vparam( phone11 => 'phone' ),  '+71234567890p12',
            'phone11 additional pause';
        is $self->verror('phone11'),            0, 'phone11 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/phone/vparam", form => {
        phone1      => '+71234567890',
        phone2      => '71234567890',
        phone3      => '4567890',
        phone4      => '',
        phone5      => 'asddf ',
        phone6      => '123456789829893839839389383839',
        phone7      => '7 (495) 456-78-90w12-3',
        phone8      => '+71234567890,1234',
        phone9      => '+71234567890.1234',
        phone10     => '+71234567890, доб. 1234',
        phone11      => '+71234567890p12',
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

