#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 24;
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

note 'numeric';
{
    $t->app->routes->post("/test/numeric/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( numeric0 => 'numeric' ),  0,      'numeric0 zero';
        is $self->verror('numeric0'),               0,      'numeric0 no error';

        is $self->vparam( numeric1 => 'numeric' ),  111.222,'numeric1 number';
        is $self->verror('numeric1'),               0,      'numeric1 no error';

        is $self->vparam( numeric2 => 'numeric' ),  222,    'numeric2 text and number';
        is $self->verror('numeric2'),               0,      'numeric2 no error';

        is $self->vparam( numeric3 => 'numeric' ),  333.444,'numeric3 more text and number';
        is $self->verror('numeric3'),               0,      'numeric3 no error';

        is $self->vparam( numeric4 => 'numeric' ),  undef,  'numeric4 text';
        is $self->verror('numeric4'),               'Value is not defined',
                                                            'numeric4 error';

        is $self->vparam( numeric5 => 'numeric' ),  undef,  'numeric5 empty';
        is $self->verror('numeric5'),               'Value is not defined',
                                                            'numeric5 error';

        is $self->vparam( numeric6 => 'numeric' ),  333,    'numeric6 whitespace';
        is $self->verror('numeric6'),               0,      'numeric6 no error';

        is $self->vparam( numeric7 => 'numeric' ),  -333.444,'numeric7 signed';
        is $self->verror('numeric7'),               0,      'numeric7 no error';

        is $self->vparam( numeric8 => 'numeric' ),  333.444,'numeric8 plus';
        is $self->verror('numeric8'),           0,          'numeric8 no error';

        is $self->vparam( numeric9 => 'numeric' ),  0.1,    'numeric9 dot';
        is $self->verror('numeric9'),           0,          'numeric9 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/numeric/vparam", form => {

        numeric0    => 0,
        numeric1    => 111.222,
        numeric2    => '222aaa',
        numeric3    => 'bbb333.444bbb',
        numeric4    => 'ccc',
        numeric5    => '',
        numeric6    => ' 333. ',
        numeric7    => ' -333.444 ',
        numeric8    => ' +333.444 ',
        numeric9    => ' .1 ',
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

