#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 20;
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

note 'skipundef';
{
    $t->app->routes->post("/skipundef")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            unknown     => {type => 'int', skipundef => 1},
            unknown2    => {type => '~int'},
            int1        => {type => 'int', skipundef => 1},
            int2        => {type => 'int', skipundef => 1},
            int3        => {type => '~int'},
        );
        is_deeply \%params, {}, 'all skipundefped';

        is $self->verrors, 4, 'All errors';
        my %errors = $self->verrors;

        ok ! exists $params{unknown},    'unknown skipundefped and optional';
        ok   exists $errors{unknown},    'unknown not in errors';

        ok ! exists $params{unknown2},    'unknown skipundefped';
        ok ! exists $errors{unknown2},    'unknown in errors';

        ok ! exists $params{int1},       'int1 skipundefped';
        ok   exists $errors{int1},       'int1 in errors';

        ok ! exists $params{int2},       'int2 skipundefped';
        ok   exists $errors{int2},       'int2 in errors';

        ok ! exists $params{int3},       'int3 skipundefped';
        ok   exists $errors{int3},       'int3 in errors';

        is $self->vparam(unknown2 => 'int', skipundef => 1), undef,
            'unknown2 skipundefped';
        is $self->verror('unknown2'), 'Value is not defined',
            'unknown2 in errors';

        is_deeply
            $self->vparam(int_arr => 'int', array => 1, skipundef => 1),
            [1, 2, 4],
            'int_arr skip undefined values';
        is $self->verror('int_arr'), 1, 'int_arr in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/skipundef", form => {
        int1    => '',
        int2    => 'abc',
        int3    => 'cfg',
        int_arr => [1, 2, undef, 4],
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

