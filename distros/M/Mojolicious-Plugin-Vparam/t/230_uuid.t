#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 16;
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

note 'uuid';
{
    $t->app->routes->post("/test/uuid/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( uuid0 => 'uuid' ),    undef,
            'uuid0 empty';
        is $self->verror('uuid0'),
            'Value is not set',
            'uuid0 error';

        is $self->vparam( uuid1 => 'uuid' ),
            '11122233344455566677788899900011',
            'uuid1 good';
        is $self->verror('uuid1'),              0,
            'uuid1 no error';

        is $self->vparam( uuid2 => 'uuid' ),
            '11122233344455566677788899900011',
            'uuid2 whitespace';
        is $self->verror('uuid2'),              0,
            'uuid2 no error';

        is $self->vparam( uuid3 => 'uuid' ),    undef,
            'uuid3 wrong letter';
        is $self->verror('uuid3'),
            'Wrong format',
            'uuid3 error';

        is $self->vparam( uuid4 => 'uuid' ),
            '550e8400-e29b-41d4-a716-446655440000',
            'uuid4 striped';
        is $self->verror('uuid4'),              0,
            'uuid4 no error';

        is $self->vparam( uuid5 => 'uuid' ),
            '01234567890abcdefabcdef012345678',
            'uuid5 always low case';
        is $self->verror('uuid5'),              0,
            'uuid5 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/uuid/vparam", form => {
        uuid0    => '',
        uuid1    => '11122233344455566677788899900011',
        uuid2    => ' 11122233344455566677788899900011 ',
        uuid3    => '1112223334445556667778889990001ZZ',
        uuid4    => '550e8400-e29b-41d4-a716-446655440000',
        uuid5    => '01234567890abcdefABCDEF012345678',
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

