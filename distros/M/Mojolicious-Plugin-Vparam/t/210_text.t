#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 14;
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

note 'text';
{
    $t->app->routes->post("/test/text/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( text0 => 'text' ),    '',     'text0 empty';
        is $self->verror('text0'),              0,      'text0 no error';

        is $self->vparam( text1 => 'text' ),    'aaa111bbb222 ccc333',
                                                        'text1 texting';
        is $self->verror('text1'),              0,      'text1 no error';

        is $self->vparam( text2 => 'text' ),    '   ',  'text2 whitespace';
        is $self->verror('text2'),              0,      'text2 no error';

        is $self->vparam( text3 => 'text' ),    '★абвгд★',
                                                        'text3 utf8';
        is $self->verror('text3'),          0,          'text3 no error';

        is $self->vparam( text4 => 'text' ),    ' aaa ','text4 whitespace and text';
        is $self->verror('text4'),              0,      'text4 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/text/vparam", form => {
        text0    => '',
        text1    => 'aaa111bbb222 ccc333',
        text2    => '   ',
        text3    => '★абвгд★',
        text4    => ' aaa ',
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

