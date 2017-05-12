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

note 'date';
{
    $t->app->routes->post("/test/date/vparam")->to( cb => sub {
        my ($self) = @_;

        my $now = DateTime->now(time_zone => 'local');
        my $tz  = $now->strftime('%z');

        is $self->vparam( date0 => 'date' ), undef,         'date0 empty';
        is $self->verror('date0'), 'Value is not defined',  'date0 error';

        is $self->vparam( date1 => 'date' ), '2012-02-29',  'date1 rus date';
        is $self->verror('date1'), 0,                       'date1 no error';

        is $self->vparam( date2 => 'date' ), '2012-02-29',  'date2 iso date';
        is $self->verror('date2'), 0,                       'date2 no error';

        is $self->vparam( date3 => 'date' ), '2012-02-29',  'date3 rus datetime';
        is $self->verror('date3'), 0,                       'date3 no error';

        is $self->vparam( date4 => 'date' ), '2012-02-29',  'date4 eng datetime';
        is $self->verror('date4'), 0,                       'date4 no error';

        my $default = DateTime->new(
            year        => $now->year,
            month       => $now->month,
            day         => $now->day,
            time_zone   => $tz,
        )->strftime('%F');
        is $self->vparam( date5 => 'date' ),  $default,     'time => date';
        is $self->verror('date5'), 0,                       'date5 no error';

        is $self->vparam( date6 => 'date' ), '2012-02-29',  'date6 whitespace';
        is $self->verror('date6'), 0,                       'date6 no error';

        is $self->vparam( date7 => 'date' ), '2012-03-02',  'date7 short';
        is $self->verror('date7'), 0,                       'date7 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/date/vparam", form => {

        # Don`t dowble check datetime parser

        date0   => '',
        date1   => '29.02.2012',
        date2   => '2012-02-29',
        date3   => '29.02.2012 11:33:44',
        date4   => '2012-02-29 11:33:44',
        date5   => '11:33:44',
        date6   => '   29.02.2012  ',
        date7   => '2.3.2012 11:33',
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

