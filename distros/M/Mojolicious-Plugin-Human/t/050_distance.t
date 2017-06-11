#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 13;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Human';
    use_ok 'DateTime';
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('Human');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

$t->app->routes->get("/test/human")->to( cb => sub {
    my ($self) = @_;

    is $self->human_distance('1234.5678'),  '1234.57',  'human_distance1';
    is $self->human_distance('1234.5638'),  '1234.56',  'human_distance2';
    is $self->human_distance('1234.0010'),  '1234',     'human_distance3';
    is $self->human_distance('1234.0100'),  '1234.01',  'human_distance4';
    is $self->human_distance('1234.0000'),  '1234',     'human_distance5';
    is $self->human_distance('1234'),       '1234',     'human_distance6';
    is $self->human_distance('1234.'),      '1234',     'human_distance7';

    $self->render(text => 'OK.');
});

$t->get_ok("/test/human")-> status_is( 200 );

diag decode utf8 => $t->tx->res->body unless $t->tx->success;

=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

