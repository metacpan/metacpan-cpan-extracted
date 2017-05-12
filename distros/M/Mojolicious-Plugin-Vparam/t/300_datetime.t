#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 37;
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

note 'datetime';
{
    my $now = DateTime->now(time_zone => 'local');
    my $tz  = $now->strftime('%z');

    $t->app->routes->post("/test/datetime/parse/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( datetime0 => 'datetime' ), undef,
            'datetime0 empty';
        is $self->verror('datetime0'), 'Value is not defined',
            'datetime0 error';

        my $datetime1 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            time_zone   => $tz,
        )->strftime('%F %T %z');
        is $self->vparam( datetime1 => 'datetime' ), $datetime1,
            'datetime1 rus date';
        is $self->verror('datetime1'), 0, 'datetime1 no error';

        is $self->vparam( datetime2 => 'datetime' ), $datetime1,
            'datetime2 iso date';
        is $self->verror('datetime2'), 0, 'datetime2 no error';

        my $datetime3 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => $tz
        )->strftime('%F %T %z');
        is $self->vparam( datetime3 => 'datetime' ), $datetime3,
            'datetime3 rus datetime';
        is $self->verror('datetime3'), 0, 'datetime3 no error';

        is $self->vparam( datetime4 => 'datetime' ), $datetime3,
            'datetime4 iso datetime';
        is $self->verror('datetime4'), 0, 'datetime4 no error';

        is $self->vparam( datetime5 => 'datetime' ), $datetime3,
            'datetime5 whitespace';
        is $self->verror('datetime5'), 0, 'datetime5 no error';

        my $datetime6 = DateTime->new(
            year        => $now->year,
            month       => $now->month,
            day         => $now->day,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => $tz,
        )->strftime('%F %T %z');
        is $self->vparam( datetime6 => 'datetime' ), $datetime6,
            'time => datetime';
        is $self->verror('datetime6'), 0, 'datetime6 no error';

        my $datetime7 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => '+0300',
        )->set_time_zone( $tz )->strftime('%F %T %z');
        is $self->vparam( datetime7 => 'datetime' ), $datetime7,
            'datetime7 rus with time zone';
        is $self->verror('datetime7'), 0, 'datetime7 no error';

        is $self->vparam( datetime8 => 'datetime' ), $datetime7,
            'datetime8 iso with time zone';
        is $self->verror('datetime8'), 0, 'datetime8 no error';

        my $datetime9 = DateTime->new(
            year        => 2013,
            month       => 3,
            day         => 27,
            hour        => 15,
            minute      => 55,
            second      => 00,
            time_zone   => '+0400',
        )->set_time_zone( $tz )->strftime('%F %T %z');
        is $self->vparam( datetime9 => 'datetime' ), $datetime9,
            'datetime9 browser';
        is $self->verror('datetime9'), 0, 'datetime9 no error';

        my $datetime10 = DateTime->new(
            year        => 2012,
            month       => 3,
            day         => 2,
            hour        => 11,
            minute      => 33,
            second      => 00,
            time_zone   => $tz
        )->strftime('%F %T %z');
        is $self->vparam( datetime10 => 'datetime' ), $datetime10,
            'datetime10 short';
        is $self->verror('datetime10'), 0, 'datetime10 no error';

        is $self->vparam( datetime11 => 'datetime' ), undef,
            'datetime11 not valid';
        is $self->verror('datetime11'), 'Value is not defined',
            'datetime11 error';

        my $datetime12 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => '-0200',
        )->set_time_zone( $tz )->strftime('%F %T %z');
        is $self->vparam( datetime12 => 'datetime' ), $datetime12,
            'datetime12 browser';
        is $self->verror('datetime12'), 0, 'datetime12 no error';

        is $self->vparam( unknown => 'datetime' ), undef,
            'unknown empty';

        is $self->vparam(
            unknown2    => 'datetime',
            default     => '2012-02-29 11:33:44 +0500'
        ), '2012-02-29 11:33:44 +0500',
            'unknown2 set default by string';

        my $unknown3 = DateTime->now(time_zone => 'local');
        is $self->vparam(
            unknown3    => 'datetime',
            default     => $unknown3,
        ), $unknown3->strftime('%F %T %z'),
            'unknown2 set default by object';

        my $datetime13 = DateTime->new(
            year        => 2016,
            month       => 8,
            day         => 13,
            hour        => 6,
            minute      => 56,
            second      => 2,
            time_zone   => $tz,
        )->strftime('%F %T %z');
        is $self->vparam( datetime13 => 'datetime' ), $datetime13,
            'datetime13 rus date truncated';
        is $self->verror('datetime13'), 0, 'datetime13 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/parse/vparam", form => {
        datetime0   => '',
        datetime1   => '29.02.2012',
        datetime2   => '2012-02-29',
        datetime3   => '29.02.2012 11:33:44',
        datetime4   => '2012-02-29 11:33:44',
        datetime5   => '   2012-02-29   11:33:44  ',
        datetime6   => '11:33:44',
        datetime7   => '29.02.2012 11:33:44 +0300',
        datetime8   => '2012-02-29 11:33:44 +0300',
        datetime9   => 'Wed Mar 27 2013 15:55:00 GMT+0400 (MSK)',
        datetime10  => '2.3.2012 11:33',
        datetime11  => '2012-22-29',
        datetime12  => '2012-02-29 11:33:44 -0200',
        datetime13  => '13.8.16 6:56:02',
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

