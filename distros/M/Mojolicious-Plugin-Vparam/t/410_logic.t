#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 43;
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

note 'logic';
{
    $t->app->routes->post("/test/logic/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( logic0 => 'logic' ),    undef,  'logic0 wrong';
        is $self->verror('logic0'), 'Wrong format',      'logic0 error';

        is $self->vparam( logic1 => 'logic' ),    1,      'logic1 1';
        is $self->verror('logic1'),              0,      'logic1 no error';

        is $self->vparam( logic2 => 'logic' ),    1,      'logic2 True';
        is $self->verror('logic2'),              0,      'logic2 no error';

        is $self->vparam( logic3 => 'logic' ),    1,      'logic3 yes';
        is $self->verror('logic3'),              0,      'logic3 no error';

        is $self->vparam( logic4 => 'logic' ),    0,      'logic4 0';
        is $self->verror('logic4'),              0,      'logic4 no error';

        is $self->vparam( logic5 => 'logic' ),    0,      'logic5 faLse';
        is $self->verror('logic5'),              0,      'logic5 no error';

        is $self->vparam( logic6 => 'logic' ),    0,      'logic6 no';
        is $self->verror('logic6'),              0,      'logic6 no error';

        is $self->vparam( logic7 => 'logic' ), undef,     'logic7 empty';
        is $self->verror('logic7'),              0,      'logic7 no error';

        is $self->vparam( logic8 => 'logic' ),    1,      'logic8 True and whitespace';
        is $self->verror('logic8'),              0,      'logic8 no error';

        is $self->vparam( logic9 => 'logic' ), undef,    'logic9 whitespace';
        is $self->verror('logic9'),              0,      'logic9 no error';

        is $self->vparam( logic10 => 'logic' ),   1,      'logic10 OK';
        is $self->verror('logic10'),             0,      'logic10 no error';

        is $self->vparam( logic11 => 'logic' ),   0,      'logic11 FAIL';
        is $self->verror('logic11'),             0,      'logic11 no error';

        is $self->vparam( logic12 => 'logic' ),  undef,   'logic12 null';
        is $self->verror('logic12'),             0,         'logic12 no error';

        is $self->vparam( logic13 => 'logic' ),  undef,   'logic13 undef';
        is $self->verror('logic13'),             0,         'logic13 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/logic/vparam", form => {
        logic0       => 'aaa',
        logic1       => '1',
        logic2       => 'True',
        logic3       => 'yes',
        logic4       => '0',
        logic5       => 'faLse',
        logic6       => 'no',
        logic7       => '',
        logic8       => '  True  ',
        logic9       => '   ',
        logic10      => 'OK',
        logic11      => 'FAIL',
        logic12      => 'null',
        logic13      => 'undef',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'select';
{
    $t->app->routes->post("/test/logic/unknown")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( select1 => {type => 'logic', default => 1}),
            1,
            'select1 default true';
        is $self->verror('select1'),             0,   'select1 no error';

        is $self->vparam( select2 => {type => 'logic', default => 0}),
            0,
            'select2 default false';
        is $self->verror('select2'),             0,   'select2 no error';

        is $self->vparam( select3 => 'logic' ),
            undef,
            'select3 undefined';
        is
            $self->verror('select3'),
            'Value is not defined',
            'select3 error'
        ;

        is $self->vparam( select4 => '?logic'),
            undef,
            'select4 default false';
        is $self->verror('select4'),             0,   'select4 no error';

        is $self->vparam( select5 => {type => 'logic', default => undef}),
            undef,
            'select5 default undef';
        is $self->verror('select5'),             0,   'select5 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/logic/unknown", form => {
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

