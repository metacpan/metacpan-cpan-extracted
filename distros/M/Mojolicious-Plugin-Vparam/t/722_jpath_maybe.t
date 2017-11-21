#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 37;
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

note 'jpath? body empty';
{
    $t->app->routes->post("/test/jpath/empty/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', 'jpath?' => '/a/b/c' ),
            undef,                                          'int0 empty';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/jpath/empty/vparam", '');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'jpath? body object';
{
    $t->app->routes->post("/test/jpath/object/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', 'jpath?' => '/a/b/c' ),
            undef,                                          'int0 empty';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/jpath/object/vparam", '{}');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'jpath? not good';
{
    $t->app->routes->post("/test/jpath/not/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', 'jpath?' => '/a/b/c' ),
            undef,                                          'int0 empty';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/jpath/not/vparam", ' {"a":[1,2,3]} ');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
    
    $t->post_ok("/test/jpath/not/vparam", form => { a => '1' });
    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'jpath? or form good';
{
    $t->app->routes->post("/test/jpath/good/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', 'jpath?' => '/a/b/c' ),
            3,                                              'int0 ok';
        is $self->verror('int0'), 0,                        'int0 no error';

        my $reparse = 0;
        my $old = \&Mojolicious::Plugin::Vparam::JSON::parse_json;
        {
            no warnings 'redefine';
            *Mojolicious::Plugin::Vparam::JSON::parse_json = sub($){$reparse = 1};
        }


        is $self->vparam( int1 => 'int', 'jpath?' => '/a/b/d' ),
            4,                                              'int1 ok';
        is $self->verror('int0'), 0,                        'int1 no error';

        {
            no warnings 'redefine';
            *Mojolicious::Plugin::Vparam::JSON::parse_json = $old;
        }
        is $reparse, 0, 'Do not re-parse';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/jpath/good/vparam", '{"a":{"b":{"c":3, "d": 4}}}');

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;

    $t->post_ok('/test/jpath/good/vparam', form => { int0 => 3, int1 => 4 });
    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'jpath? invalid';
{
    $t->app->routes->post("/test/jpath/invalid/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int', 'jpath?' => '/a/b/c' ),
            undef,                                          'int0 empty';
        is $self->verror('int0'), 'Value is not defined',   'int0 error';

        is $self->vparam( int1 => 'int', 'jpath?' => '/a/b/d' ),
            undef,                                          'int0 empty';
        is $self->verror('int1'), 'Value is not defined',       'int0 error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/jpath/invalid/vparam", '{"a":{"b":{"c":"abc","d":""}}}');
    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
    
    $t->post_ok("/test/jpath/invalid/vparam",
                        form => { int0 => 'abc', int1 => '' });
    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

