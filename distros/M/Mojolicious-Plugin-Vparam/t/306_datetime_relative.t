#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 36;
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
        $self->plugin('Vparam', {datetime => undef});
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'datetime relative simple';
{
    $t->app->routes->post("/test/datetime/relative/vparam")->to( cb => sub {
        my ($self) = @_;

        my $datetime0 = DateTime->now(time_zone => 'local')
            ->add(minutes => 15);
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '>=',
            $datetime0->clone->subtract(seconds => 5)->epoch,
            'datetime0';
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '<=',
            $datetime0->clone->add(seconds => 5)->epoch,
            'datetime0';
        is $self->verror('datetime0'), 0, 'datetime0 no error';

        my $datetime1 = DateTime->now(time_zone => 'local')
            ->subtract(minutes => 6);
        cmp_ok
            $self->vparam( datetime1 => 'datetime' )->epoch,
            '>=',
            $datetime1->clone->subtract(seconds => 5)->epoch,
            'datetime1';
        cmp_ok
            $self->vparam( datetime1 => 'datetime' )->epoch,
            '<=',
            $datetime1->clone->add(seconds => 5)->epoch,
            'datetime1';
        is $self->verror('datetime1'), 0, 'datetime1 no error';

        my $datetime2 = DateTime->now(time_zone => 'local')
            ->add(minutes => 800);
        cmp_ok
            $self->vparam( datetime2 => 'datetime' )->epoch,
            '>=',
            $datetime2->clone->subtract(seconds => 5)->epoch,
            'datetime2';
        cmp_ok
            $self->vparam( datetime2 => 'datetime' )->epoch,
            '<=',
            $datetime2->clone->add(seconds => 5)->epoch,
            'datetime2';
        is $self->verror('datetime2'), 0, 'datetime2 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/relative/vparam", form => {
        datetime0  => '+15',
        datetime1  => '-6',
        datetime2  => '+800',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'datetime relative with seconds';
{
    $t->app->routes->post("/test/datetime/seconds/vparam")->to( cb => sub {
        my ($self) = @_;

        my $datetime0 = DateTime->now(time_zone => 'local')
            ->add(minutes => 15, seconds => 50);
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '>=',
            $datetime0->clone->subtract(seconds => 5)->epoch,
            'datetime0';
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '<=',
            $datetime0->clone->add(seconds => 5)->epoch,
            'datetime0';
        is $self->verror('datetime0'), 0, 'datetime0 no error';

        my $datetime1 = DateTime->now(time_zone => 'local')
            ->subtract(minutes => 6, seconds => 45);
        cmp_ok
            $self->vparam( datetime1 => 'datetime' )->epoch,
            '>=',
            $datetime1->clone->subtract(seconds => 5)->epoch,
            'datetime1';
        cmp_ok
            $self->vparam( datetime1 => 'datetime' )->epoch,
            '<=',
            $datetime1->clone->add(seconds => 5)->epoch,
            'datetime1';
        is $self->verror('datetime1'), 0, 'datetime1 no error';

        my $datetime2 = DateTime->now(time_zone => 'local')
            ->add(seconds => 45);
        cmp_ok
            $self->vparam( datetime2 => 'datetime' )->epoch,
            '>=',
            $datetime2->clone->subtract(seconds => 5)->epoch,
            'datetime2';
        cmp_ok
            $self->vparam( datetime2 => 'datetime' )->epoch,
            '<=',
            $datetime2->clone->add(seconds => 5)->epoch,
            'datetime2';
        is $self->verror('datetime2'), 0, 'datetime2 no error';

        my $datetime3 = DateTime->now(time_zone => 'local')
            ->add(minutes => 400, seconds => 300);
        cmp_ok
            $self->vparam( datetime3 => 'datetime' )->epoch,
            '>=',
            $datetime3->clone->subtract(seconds => 5)->epoch,
            'datetime3';
        cmp_ok
            $self->vparam( datetime3 => 'datetime' )->epoch,
            '<=',
            $datetime3->clone->add(seconds => 5)->epoch,
            'datetime3';
        is $self->verror('datetime3'), 0, 'datetime3 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/seconds/vparam", form => {
        datetime0  => '+15:50',
        datetime1  => '-6:45',
        datetime2  => '+ 0:45',
        datetime3  => '+400:300',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'datetime relative with hours';
{
    $t->app->routes->post("/test/datetime/hours/vparam")->to( cb => sub {
        my ($self) = @_;

        my $datetime0 = DateTime->now(time_zone => 'local')
            ->add(hours => 2, minutes => 27, seconds => 36);
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '>=',
            $datetime0->clone->subtract(seconds => 5)->epoch,
            'datetime0';
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '<=',
            $datetime0->clone->add(seconds => 5)->epoch,
            'datetime0';
        is $self->verror('datetime0'), 0, 'datetime0 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/hours/vparam", form => {
        datetime0  => '+2:27:36',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'datetime relative with days';
{
    $t->app->routes->post("/test/datetime/days/vparam")->to( cb => sub {
        my ($self) = @_;

        my $datetime0 = DateTime->now(time_zone => 'local')
            ->add(days => 4, hours => 2, minutes => 27, seconds => 36);
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '>=',
            $datetime0->clone->subtract(seconds => 5)->epoch,
            'datetime0';
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '<=',
            $datetime0->clone->add(seconds => 5)->epoch,
            'datetime0';
        is $self->verror('datetime0'), 0, 'datetime0 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/days/vparam", form => {
        datetime0  => '+ 4 2:27:36',
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

