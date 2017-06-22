#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 18;
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

note 'strings';
{
    $t->app->routes->post("/test/strings/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str0 => 'str', 'lt' => 'B' ), 'A',    'str0 lt';
        is $self->verror('str0'), 0,           'str0 no error';

        is $self->vparam( str1 => 'str', 'gt' => 'B' ), 'C',    'str1 gt';
        is $self->verror('str1'), 0,           'str1 no error';

        is $self->vparam( str2 => 'str', 'le' => 'B' ), 'B',    'str2 le';
        is $self->verror('str2'), 0,           'str2 no error';

        is $self->vparam( str3 => 'str', 'ge' => 'B' ), 'B',    'str3 ge';
        is $self->verror('str3'), 0,           'str3 no error';

        is $self->vparam( str4 => 'str', 'cmp' => 'B' ), 'B',    'str4 cmp';
        is $self->verror('str4'), 0,           'str4 no error';

        is $self->vparam( str5 => 'str', 'eq' => 'B' ), 'B',    'str5 eq';
        is $self->verror('str5'), 0,           'str5 no error';

        is $self->vparam( str6 => 'str', 'ne' => 'B' ), 'A',    'str6 ne';
        is $self->verror('str6'), 0,           'str6 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/strings/vparam", form => {
        str0    => 'A',
        str1    => 'C',
        str2    => 'B',
        str3    => 'B',
        str4    => 'B',
        str5    => 'B',
        str6    => 'A',
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

