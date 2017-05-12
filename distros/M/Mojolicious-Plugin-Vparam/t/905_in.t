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

note 'in';
{
    $t->app->routes->post("/test/in/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str0 => 'str', in => ['abcdef', 'cde'] ),
            undef,                                              'str0 empty';
        is $self->verror('str0'), 'Wrong value',               'str0 error';

        is $self->vparam( str1 => 'str', in => ['abcdef', 'cde'] ),
            'abcdef',                                           'str1 string';
        is $self->verror('str1'), 0,                            'str1 no error';

        is $self->vparam( str2 => 'str', in => ['abcdef', 'cde'] ),
            undef,                                              'str2 not match';
        is $self->verror('str2'), 'Wrong value',               'str2 error';

        is $self->vparam( str3 => 'str', in => ['a', 'cde'], default => 'cde' ),
            'cde',                                              'str3 not match';
        is $self->verror('str3'), 0,
            'str3 no error, set default';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/in/vparam", form => {
        str0    => '',
        str1    => 'abcdef',
        str2    => '123456',
        str3    => 'abcdef',
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

