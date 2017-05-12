#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 14;
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

note 'str';
{
    $t->app->routes->post("/test/str/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str0 => 'str' ), '',      'str0 empty';
        is $self->verror('str0'),          0,       'str0 no error';

        is $self->vparam( str1 => 'str' ), 'aaa111bbb222 ccc333',
                                                    'str1 string';
        is $self->verror('str1'),          0,       'str1 no error';

        is $self->vparam( str2 => 'str' ), '',      'str2 whitespace';
        is $self->verror('str2'),          0,       'str2 no error';

        is $self->vparam( str3 => 'str' ), '★абвгд★',
                                                    'str3 utf8';
        is $self->verror('str3'),          0,       'str3 no error';

        is $self->vparam( unknown => 'str' ), undef,
            'unknown not match';
        is $self->verror('unknown'), 'Value is not defined',
            'unknown error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/str/vparam", form => {
        str0    => '',
        str1    => 'aaa111bbb222 ccc333',
        str2    => '   ',
        str3    => '★абвгд★',
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

