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
    require_ok 'DateTime';
    require_ok 'DateTime::Format::DateParse';
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

note 'time';
{
    $t->app->routes->post("/test/time/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( time0 => 'time' ), undef,         'time0 empty';
        is $self->verror('time0'), 'Value is not defined',  'time0 error';

        is $self->vparam( time1 => 'time' ), '00:00:00',    'time1 rus date';
        is $self->verror('time1'), 0,                       'time1 no error';

        is $self->vparam( time2 => 'time' ), '00:00:00',    'time2 iso date';
        is $self->verror('time2'), 0,                       'time2 no error';

        is $self->vparam( time3 => 'time' ), '11:33:44',    'time3 rus datetime';
        is $self->verror('time3'), 0,                       'time3 no error';

        is $self->vparam( time4 => 'time' ), '11:33:44',    'time4 iso datetime';
        is $self->verror('time4'), 0,                       'time4 no error';

        is $self->vparam( time5 => 'time' ), '11:33:44',    'time5 time';
        is $self->verror('time5'), 0,                       'time5 no error';

        is $self->vparam( time6 => 'time' ), '11:33:44',    'time6 whitespace';
        is $self->verror('time6'), 0,                       'time6 no error';

        is $self->vparam( time7 => 'time' ), '11:33:00',    'time7 short time';
        is $self->verror('time7'), 0,                       'time7 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/time/vparam", form => {

        # Don`t dowble check datetime parser

        time0   => '',
        time1   => '29.02.2012',
        time2   => '2012-02-29',
        time3   => '29.02.2012 11:33:44',
        time4   => '2012-02-29 11:33:44',
        time5   => '11:33:44',
        time6   => '  11:33:44 ',
        time7   => '2.3.2012 11:33',
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

