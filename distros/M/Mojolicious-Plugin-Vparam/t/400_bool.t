#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 39;
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

note 'bool';
{
    $t->app->routes->post("/test/bool/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( bool0 => 'bool' ),    undef,  'bool0 wrong';
        is $self->verror('bool0'), 'Wrong format',      'bool0 error';

        is $self->vparam( bool1 => 'bool' ),    1,      'bool1 1';
        is $self->verror('bool1'),              0,      'bool1 no error';

        is $self->vparam( bool2 => 'bool' ),    1,      'bool2 True';
        is $self->verror('bool2'),              0,      'bool2 no error';

        is $self->vparam( bool3 => 'bool' ),    1,      'bool3 yes';
        is $self->verror('bool3'),              0,      'bool3 no error';

        is $self->vparam( bool4 => 'bool' ),    0,      'bool4 0';
        is $self->verror('bool4'),              0,      'bool4 no error';

        is $self->vparam( bool5 => 'bool' ),    0,      'bool5 faLse';
        is $self->verror('bool5'),              0,      'bool5 no error';

        is $self->vparam( bool6 => 'bool' ),    0,      'bool6 no';
        is $self->verror('bool6'),              0,      'bool6 no error';

        is $self->vparam( bool7 => 'bool' ),    0,      'bool7 empty';
        is $self->verror('bool7'),              0,      'bool7 no error';

        is $self->vparam( bool8 => 'bool' ),    1,      'bool8 True and whitespace';
        is $self->verror('bool8'),              0,      'bool8 no error';

        is $self->vparam( bool9 => 'bool' ),    0,      'bool9 whitespace';
        is $self->verror('bool9'),              0,      'bool9 no error';

        is $self->vparam( bool10 => 'bool' ),   1,      'bool10 OK';
        is $self->verror('bool10'),             0,      'bool10 no error';

        is $self->vparam( bool11 => 'bool' ),   0,      'bool11 FAIL';
        is $self->verror('bool11'),             0,      'bool11 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/bool/vparam", form => {
        bool0       => 'aaa',
        bool1       => '1',
        bool2       => 'True',
        bool3       => 'yes',
        bool4       => '0',
        bool5       => 'faLse',
        bool6       => 'no',
        bool7       => '',
        bool8       => '  True  ',
        bool9       => '   ',
        bool10      => 'OK',
        bool11      => 'FAIL',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'checkbox';
{
    $t->app->routes->post("/test/bool/unknown")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( checkbox1 => {type => 'bool', default => 1}),
            1,
            'checkbox1 default true';
        is $self->verror('checkbox1'),             0,   'checkbox1 no error';

        is $self->vparam( checkbox2 => {type => 'bool', default => 0}),
            0,
            'checkbox2 default false';
        is $self->verror('checkbox2'),             0,   'checkbox2 no error';

        is $self->vparam( checkbox3 => 'bool' ),
            0,
            'checkbox3 undefined';
        is $self->verror('checkbox3'),             0,   'checkbox3 no error';

        is $self->vparam( checkbox4 => '?bool'),
            0,
            'checkbox4 optional';
        is $self->verror('checkbox4'),             0,   'checkbox4 no error';

        is $self->vparam( checkbox5 => {type => 'bool', default => undef}),
            undef,
            'checkbox5 default undef';
        is $self->verror('checkbox5'),             0,   'checkbox5 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/bool/unknown", form => {
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

