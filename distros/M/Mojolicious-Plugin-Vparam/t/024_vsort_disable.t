#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 11;
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
        $self->log->level( $ENV{MOJO_LOG_LEVEL} = 'warn' );
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'vsort default values';
{
    $t->app->routes->post("/test/default/vsort")->to( cb => sub {
        my ($self) = @_;

        $self->vconf(vsort_page => undef);
        $self->vconf(vsort_rws  => undef);
        $self->vconf(vsort_oby  => undef);
        $self->vconf(vsort_ods  => undef);

        my %params = $self->vsort( int1 => 'int' );
        ok( (not exists $params{page}),    'page disabled');
        ok( (not exists $params{oby}),     'oby disabled');
        ok( (not exists $params{ods}),     'ods disabled');
        ok( (not exists $params{rws}),     'rws disabled');

        is $params{int1},   123,        'int1';

        is $self->verrors, 0, 'no errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/default/vsort", form => {int1 => 123})-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

