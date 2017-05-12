#!/usr/bin/env perl

# Copyright (C) 2009, Pascal Gaudette.

use strict;
use warnings;

use Test::More;
use MojoX::UserAgent;

plan skip_all => 'set TEST_NET to enable this test (must have Internet connectivity)'
  unless $ENV{TEST_NET};
plan tests => 15;

my $ua = MojoX::UserAgent->new;

isa_ok($ua, "MojoX::UserAgent");
isa_ok($ua, "Mojo::Base");

$ua->get(
    'http://labs.kraih.com',
    sub {
        my ($ua_r, $tx) = @_;

        isa_ok($ua_r, "MojoX::UserAgent");
        isa_ok($tx, "MojoX::UserAgent::Transaction");
        is($ua, $ua_r, "User-Agent object match");

        is($tx->res->code, 200, "labs.kraih.com - Status 200");
        is($tx->hops, 1, "labs.kraih.com - 1 hop");
    }
);

$ua->run_all;

$ua->get(
    'http://www.djembe.ca',
    sub {
        my ($ua_r, $tx) = @_;
        is($tx->res->code, 200, "www.djembe.ca - Status 200");
        is($tx->hops, 2, "www.djembe.ca - 2 hops");
    }
);

$ua->get(
    'http://search.cpan.org/dist/Mojo/',
    sub {
        my ($ua_r, $tx) = @_;
        is($tx->res->code, 200, "search.cpan.org - Status 200");
        is($tx->hops, 0, "search.cpan.org - no hops");
    }
);

$ua->get(
    'http://mojolicious.org',
    sub {
        my ($ua_r, $tx) = @_;
        is($tx->res->code, 200, "mojolicious.org - Status 200");
        is($tx->hops, 0, "mojolicious.org - no hops");
    }
);

$ua->run_all;

$ua->get(
    'http://www.google.ca',
    sub {
        my ($ua_r, $tx) = @_;
        is($tx->res->code, 200, "www.google.ca - Status 200");
    }
);

$ua->run_all;

# Should have picked up two cookies at this point

is($ua->cookie_jar->size, 2, "Picked up two cookies so far");
