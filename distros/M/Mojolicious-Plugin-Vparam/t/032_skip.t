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

note 'skip';
{
    $t->app->routes->post("/skip")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            unknown  => {type => 'int', skip => 1},
            unknown3 => {type => 'int', skip => sub { 1 }},
            int1    => {type => 'int', skip => 1},
            int2    => {type => 'int', skip => 1},
        );
        is_deeply \%params, {}, 'all skipped';

        is $self->verrors, 0, 'No errors';
        my %errors = $self->verrors;

        ok ! exists $params{unknown},    'unknown skipped';
        ok ! exists $errors{unknown},    'unknown not in errors';

        ok ! exists $params{unknown3},   'unknown3 skipped';
        ok ! exists $errors{unknown3},   'unknown3 not in errors';

        ok ! exists $params{int1},       'int1 skipped';
        ok ! exists $errors{int1},       'int1 not in errors';

        ok ! exists $params{int2},       'int2 skipped';
        ok ! exists $errors{int2},       'int2 not in errors';

        is $self->vparam(unknown2 => 'int', skip => 1), undef,
            'unknown2 skipped';
        is $self->verror('unknown2'), 0,
            'unknown2 not in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/skip", form => {
        int1    => '',
        int2    => '111',
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

