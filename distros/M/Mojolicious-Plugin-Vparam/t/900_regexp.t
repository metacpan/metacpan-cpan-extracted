#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 21;
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

note 'regexp vparam';
{
    $t->app->routes->post("/test/regexp/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str0 => 'str', regexp => qr{abc} ),
            undef,                                              'str0 empty';
        is $self->verror('str0'), 'Wrong format',               'str0 error';

        is $self->vparam( str1 => 'str', regexp => qr{abc} ),
            'abcdef',                                           'str1 string';
        is $self->verror('str1'), 0,                            'str1 no error';

        is $self->vparam( str2 => 'str', regexp => qr{abc} ),
            undef,                                              'str2 not match';
        is $self->verror('str2'), 'Wrong format',               'str2 error';

        is $self->vparam( str3 => 'str', regexp => qr{www}, default => 'cde' ),
            'cde',                                              'str3 not match';
        is $self->verror('str3'), 0,
            'str3 no error, set default';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/regexp/vparam", form => {
        str0    => '',
        str1    => 'abcdef',
        str2    => '123456',
        str3    => 'abcdef',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'regexp vparams';
{
    $t->app->routes->post("/test/regexp/vparam")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            str0 => { regexp => qr{abc} },
            str1 => { regexp => qr{abc} },
            str2 => { regexp => qr{abc} },
            str3 => { regexp => qr{www}, default => 'cde' },
        );
        my %errors = $self->verrors;

        is $params{str0}, undef,                                'str0 empty';
        is $errors{str0}{message}, 'Wrong format',              'str0 error';

        is $params{str1}, 'abcdef',                             'str1 string';
        ok not(exists $errors{str1}),                           'str1 no error';

        is $params{str2}, undef,                                'str2 not match';
        is $errors{str2}{message}, 'Wrong format',              'str2 error';

        is $params{str3}, 'cde',                'str3 not match';
        ok not(exists $errors{str3}),           'str3 no error, set default';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/regexp/vparam", form => {
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

