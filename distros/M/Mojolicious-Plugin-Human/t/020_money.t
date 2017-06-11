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

$t->app->routes->get("/test/human/full")->to( cb => sub {
    my ($self) = @_;

    is $self->human_money,                  undef,      'human_money undefined';
    is $self->human_money(''),              undef,      'human_money empty';
    is $self->human_money('12345678.00'),   '12,345,678.00',  'human_money';

    is $self->human_money('%d' => 12345678.50), '12,345,678',
        'formatted human_money';

    $self->render(text => 'OK.');
});
$t->get_ok("/test/human/full")-> status_is( 200 );
diag decode utf8 => $t->tx->res->body unless $t->tx->success;

$t->app->routes->get("/test/human/short")->to( cb => sub {
    my ($self) = @_;

    is $self->human_money_short,                  undef,
        'human_money_short undefined';
    is $self->human_money_short(''),              undef,
        'human_money_short empty';
    is $self->human_money_short('12345678.00'),   '12,345,678',
        'human_money_short';

    is $self->human_money_short('%d' => 12345678.50), '12,345,678',
        'formatted human_money_short';

    $self->render(text => 'OK.');
});
$t->get_ok("/test/human/short")-> status_is( 200 );
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

