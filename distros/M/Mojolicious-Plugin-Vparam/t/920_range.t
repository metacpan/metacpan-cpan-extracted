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

note 'range';
{
    $t->app->routes->post("/test/range/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', range => [2, 4] ),
            undef,                                              'int0 empty';
        is $self->verror('int0'), 'Value is not defined',       'int0 error';

        is $self->vparam( int1 => 'int', range => [2, 4] ),
            3,                                                  'int1 string';
        is $self->verror('int1'), 0,                            'int1 no error';

        is $self->vparam( int2 => 'int', range => [2, 4] ),
            undef,                                              'int2 not match';
        is $self->verror('int2'), 'Value should not be greater than 2',
            'int2 error';

        is $self->vparam( int4 => 'int', range => [2, 4] ),
            undef,                                              'int4 not match';
        is $self->verror('int4'), 'Value should not be less than 4',
            'int4 error';

        is $self->vparam( int3 => 'int', range => [2, 4], default => 3 ),
            3,                                                  'int3 not match';
        is $self->verror('int3'), 0,
            'int3 no error, set default';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/range/vparam", form => {
        int0    => '',
        int1    => 3,
        int2    => 1,
        int4    => 5,
        int3    => 5,
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

