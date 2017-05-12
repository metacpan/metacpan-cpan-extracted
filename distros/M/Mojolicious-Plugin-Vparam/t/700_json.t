#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 16;
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

note 'json';
{
    $t->app->routes->post("/test/json/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( json0 => 'json' ),    undef,  'json0 empty';
        is $self->verror('json0'), 'Wrong format',      'json0 error';

        is_deeply
            $self->vparam( json1 => 'json' ),
            {},                                         'json1 hash';
        is $self->verror('json1'),              0,      'json1 no error';

        is_deeply
            $self->vparam( json2 => 'json' ),
            [],                                         'json2 array';
        is $self->verror('json2'),              0,      'json2 no error';

        is $self->vparam( json3 => 'json' ),    undef,  'json3 null';
        is $self->verror('json3'), 'Wrong format',      'json3 error';

        is_deeply
            $self->vparam( json4 => 'json' ),
            {a => [1,2,3]},                             'json4 hash and values';
        is $self->verror('json4'),              0,      'json4 no error';

        is $self->vparam( json5 => 'json' ),    'string','json5 string';
        is $self->verror('json5'),              0,       'json5 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/json/vparam", form => {
        json0   => '',
        json1   => '{}',
        json2   => '[]',
        json3   => 'null',
        json4   => ' {"a":[1,2,3]}',
        json5   => '"string"',
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

