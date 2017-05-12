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
    use_ok 'Encode',        qw(encode_utf8);
    use_ok 'Mojo::JSON',    qw(encode_json);
    use_ok 'Digest::MD5',   qw(md5_hex);
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'Mojolicious::Plugin::Vparam::Address';
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

note 'address';
{
    my ($full, $address, $lon, $lat, $md5, $id, $type, $lang, $opt) = (
        '  United States, New York : 42.93709 ,  -75.610703  ',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        undef,
        undef,
        undef,
        undef,
    );

    $t->app->routes->post("/test/address/vparam")->to(cb => sub {
        my ($self) = @_;
        my $address = $self->vparam(address => { type => 'address' });
        is $address => undef, 'address is not defined';
        is $self->vclass('address'), 'field-with-error', 'vclass';
        ok $self->verrors ? 1 : 0, 'verrors';

        $address = $self->vparam(address2 => { type => 'address', optional => 1 });
        is $address => undef, 'address2 is not defined';
        is $self->vclass('address2'), '', 'vclass is empty';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/vparam", form => {});

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

