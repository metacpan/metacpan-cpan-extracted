#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 12;
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

    ok $self->human_suffix('', 0, '1','2','100500') eq '100500',
        'human_suffix 0';
    ok $self->human_suffix('', 1, '1','2','100500') eq '1',
        'human_suffix 1';
    for my $count (2..4) {
        ok $self->human_suffix('', $count, '1','2','100500') eq '2',
            "human_suffix $count";
    }
    ok $self->human_suffix('', 6, '1','2','100500') eq '100500',
        'human_suffix 6';

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

