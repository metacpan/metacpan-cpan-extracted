#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 31;
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
        $self->log->level( $ENV{MOJO_LOG_LEVEL} = 'warn' );
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'regexp';
{
    $t->app->routes->post("/test/regexp/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str1 => qr{^[\w\s]{10,20}$} ),
            'aaa111bbb222 ccc333',                      'str1 match';
        is $self->verror('str1'),               0,      'str1 no error';

        is $self->vparam( str2 => qr{^[\w\s]{10,20}$} ),
            undef,                                      'str2 not match';
        is $self->verror('str2'), 'Wrong format',       'str2 error';

        is $self->vparam( str3 => qr{^[\w\s]{10,20}$} ),
            undef,                                      'str3 empty';
        is $self->verror('str3'), 'Wrong format',       'str3 error';

        is $self->vparam( str4 => qr{^(www)$}, default => 'abc' ),
            'abc',                                      'str4 default';
        is $self->verror('str4'), 0,                    'str4 no error';

        is $self->vparam(
            str5    => qr{^(online_)?(all|free|busy|auto)$},
            default => 'all',
        ), 'auto',                                      'str5 regexp';
        is $self->verror('str5'), 0,
            'str5 no error, set default';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/regexp/vparam", form => {
        str1    => 'aaa111bbb222 ccc333',
        str2    => '...',
        str3    => '',
        str4    => 'uuu',
        str5    => 'auto',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'callback';
{
    $t->app->routes->post("/test/callback/vparam")->to( cb => sub {
        my ($self) = @_;

        my $mysub = sub { $_[1] && $_[1] eq '123abc' ? $_[1] : undef };

        is $self->vparam( str1 => $mysub ),     '123abc',  'str1 match';
        is $self->verror('str1'),               0,         'str1 no error';

        is $self->vparam( str2 => $mysub ),     undef,      'str2 not match';
        is $self->verror('str2'),               0,          'str2 manual check';

        is $self->vparam( str3 => $mysub ),     undef,      'str3 empty';
        is $self->verror('str3'),               0,          'str3 manual check';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/callback/vparam", form => {
        str1    => '123abc',
        str2    => 'kldiew',
        str3    => '',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'arrayref';
{
    $t->app->routes->post("/test/arrayref/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int1 => [1,2,3] ),    2,      'int1 in array';
        is $self->verror('int1'),               0,      'int1 no error';

        is $self->vparam( int2 => [1,2,3] ),    undef,  'int2 not in array';
        is $self->verror('int2'), 'Wrong value',        'int2 error';

        is $self->vparam( int3 => [1,2,3] ),    undef,  'int3 empty';
        is $self->verror('int3'), 'Wrong value',        'int3 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/arrayref/vparam", form => {
        int1    => 2,
        int2    => 5,
        int3    => '',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

