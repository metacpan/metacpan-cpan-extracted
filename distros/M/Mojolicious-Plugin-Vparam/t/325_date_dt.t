#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 12;
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

note 'date get as DateTime';
{
    $t->app->routes->post("/test/date/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vconf(date => undef), undef, 'drop date format';

        isa_ok
            my $dt = $self->vparam( date1 => 'date' ),
            'DateTime',
            'date1';
        is $self->verror('date1'), 0,
            'date1 no error';

        is $dt->year, 2012, 'year';
        is $dt->month, 2, 'month';
        is $dt->day, 29, 'day';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/date/vparam", form => {
        date1   => '2012-02-29',
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

