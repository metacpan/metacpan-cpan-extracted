#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 22;
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

note 'opath not good';
{
    $t->app->routes->any("/test/opath/not/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', opath => '/a/c' ),
            undef,                                          'int0 wrong path';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        is $self->vparam( int1 => '?int', opath => '/a/c' ),
            undef,                                  'int1 optional wrong path';
        is $self->verror('int1'), 0,                'int1 no error';

        is $self->vparam( int2 => 'int', opath => '/d/e' ),
            undef,                                          'int2 not number';
        is $self->verror('int2'), 'Value is not defined',   'int2 error';

        $self->render(text => 'OK.');
    });

    my $url = $t->app->url_for("/test/opath/not/vparam")->to_string;
    $url .= '?' . join '&',
        'object1[a][b]=1',
        'object1[d][e]=abc',
    ;

    $t->get_ok($url)-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'opath good';
{
    $t->app->routes->any("/test/opath/good/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( object1 => 'int', opath => '/a/b' ),
            1,                                              'int0 ok';
        is $self->verror('object1'), 0,                     'int0 no error';

        is $self->vparam( object1 => 'int', opath => '/a/c' ),
            2,                                              'int1 ok';
        is $self->verror('object1'), 0,                     'int1 no error';

        is $self->vparam( object1 => 'int', opath => '/d/0/e' ),
            3,                                              'int2 ok';
        is $self->verror('object1'), 0,                     'int2 no error';

        my $reparse = 0;
        my $old = \&Mojolicious::Plugin::Vparam::Object::parse_object;
        {
            no warnings 'redefine';
            *Mojolicious::Plugin::Vparam::Object::parse_object =
                sub($){$reparse = 1};
        }

        is $self->vparam( object1 => 'int', opath => '/d/0/f' ),
            4,                                              'int3 ok';
        is $self->verror('object1'), 0,                     'int3 no error';

        {
            no warnings 'redefine';
            *Mojolicious::Plugin::Vparam::Object::parse_object = $old;
        }
        is $reparse, 0, 'Do not re-parse';

        $self->render(text => 'OK.');
    });

    my $url = $t->app->url_for("/test/opath/good/vparam")->to_string;
    $url .= '?' . join '&',
        'object1[a][b]=1',
        'object1[a][c]=2',
        'object1[d][0][e]=3',
        'object1[d][0][f]=4',
    ;
    $t->get_ok($url)-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

