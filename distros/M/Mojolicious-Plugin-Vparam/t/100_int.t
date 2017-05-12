#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 26;
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

note 'int';
{
    $t->app->routes->post("/test/int/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int' ),  0,      'int0 zero';
        is $self->verror('int0'),           0,      'int0 no error';

        is $self->vparam( int1 => 'int' ),  111,    'int1 clear number';
        is $self->verror('int1'),           0,      'int1 no error';

        is $self->vparam( int2 => 'int' ),  222,    'int2 text and number';
        is $self->verror('int2'),           0,      'int2 no error';

        is $self->vparam( int3 => 'int' ),  333,    'int3 more text and number';
        is $self->verror('int3'),           0,      'int3 no error';

        is $self->vparam( int4 => 'int' ),  undef,  'int4 text only';
        is $self->verror('int4'),           'Value is not defined',
                                                    'int4 error';

        is $self->vparam( int5 => 'int' ),  undef,  'int5 empty';
        is $self->verror('int5'),           'Value is not defined',
                                                    'int5 error';

        is $self->vparam( int6 => 'int' ),  333,    'int6 whitespace';
        is $self->verror('int6'),           0,      'int6 no error';

        is $self->vparam( int7 => 'int' ), -333,    'int7 signed';
        is $self->verror('int7'),           0,      'int7 no error';

        is $self->vparam( int8 => 'int' ),  333,    'int8 plus';
        is $self->verror('int8'),           0,      'int8 no error';

        is $self->vparam( int9 => 'int' ),  111,    'int9 numeric';
        is $self->verror('int9'),           0,      'int9 no error';

        is $self->vparam( int10 => 'int' ), undef,  'int10 like placeholder';
        is $self->verror('int10'),          'Value is not defined',
                                                    'int10 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/int/vparam", form => {

        int0    => 0,
        int1    => 111,
        int2    => '222aaa',
        int3    => 'bbb333bbb',
        int4    => 'ccc',
        int5    => '',
        int6    => ' 333 ',
        int7    => ' -333 ',
        int8    => ' +333 ',
        int9    => 111.222,
        int10   => ':id',
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

