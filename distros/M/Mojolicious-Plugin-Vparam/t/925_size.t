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

note 'size';
{
    $t->app->routes->post("/test/size/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str0 => 'str', size => [2, 4] ),
            undef,                                              'str0 empty';
        is $self->verror('str0'), 'Value is not set',           'str0 error';

        is $self->vparam( str1 => 'str', size => [2, 4] ),
            'abc',                                              'str1 string';
        is $self->verror('str1'), 0,                            'str1 no error';

        is $self->vparam( str2 => 'str', size => [2, 4] ),
            undef,                                              'str2 not match';
        is $self->verror('str2'), 'Value should not be less than 2',
            'str2 error';

        is $self->vparam( str4 => 'str', size => [2, 4] ),
            undef,                                              'str4 not match';
        is $self->verror('str4'), 'Value should not be longer than 4',
            'str4 error';

        is $self->vparam( str3 => 'str', size => [2, 4], default => 'abc' ),
            'abc',                                              'str3 not match';
        is $self->verror('str3'), 0,
            'str3 no error, set default';

        is $self->vparam( unknown => 'str', size => [2, 4] ), undef,
            'unknown not match';
        is $self->verror('unknown'), 'Value is not defined',
            'unknown error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/size/vparam", form => {
        str0    => '',
        str1    => 'abc',
        str2    => 'a',
        str4    => 'abcde',
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

