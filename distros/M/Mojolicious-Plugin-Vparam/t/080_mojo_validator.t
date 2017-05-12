#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 17;
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

note 'Mojo::Validator::Validation';
{
    $t->app->routes->post("/test/mojo/vparam")->to( cb => sub {
        my ($self) = @_;

        SKIP: {
            skip 'Validation from Mojo 4.42', 12
                if version->new($Mojolicious::VERSION) < version->new(4.42);

            is $self->vparam( int1 => 'int' ), undef,           'int1 empty';
            is $self->verror('int1'), 'Value is not defined',   'int1 error';
            is $self->validation->param('int3'), undef,         'int1 param';
            is $self->validation->has_error('int1'), 1,         'int1 has_error';

            is $self->vparam( int2 => 'int' ), undef,           'int2 empty';
            is $self->verror('int2'), 'Value is not defined',   'int2 error';
            is $self->validation->param('int2'), undef,         'int2 param';
            is $self->validation->has_error('int2'), 1,         'int2 has_error';

            is $self->vparam( int3 => 'int' ), 123,             'int3 empty';
            is $self->verror('int3'), 0,                        'int3 error';
            is $self->validation->param('int3'), 123,           'int3 param';
            is $self->validation->has_error('int3'), '',        'int3 has_error';
        }

#        note explain $self->validation;

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/mojo/vparam", form => {
        int1        => '',
        int2        => 'abc',
        int3        => 123,
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

