#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 10;
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

    is $self->human_interval(undef),    undef,          'undef';
    is $self->human_interval(0),        '00:00:00',     '0 seconds';
    is $self->human_interval(1),        '00:00:01',     '1 seconds';
    is $self->human_interval(839485),   '9 17:11:25',   '839485 seconds';

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

