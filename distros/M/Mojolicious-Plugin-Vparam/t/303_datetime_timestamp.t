#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 8;
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

note 'datetime timestamp';
{
    my $now = DateTime->now(time_zone => 'local');

    $t->app->routes->post("/test/datetime/timestamp/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( datetime20 => 'datetime' ),
            $now->strftime('%F %T %z'),
            'datetime20';
        is $self->verror('datetime20'), 0, 'datetime20 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/timestamp/vparam", form => {
        datetime20  => $now->epoch,
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

