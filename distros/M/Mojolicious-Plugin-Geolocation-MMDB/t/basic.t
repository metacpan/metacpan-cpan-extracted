#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use Mojo::Base -strict;
use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

use Mojo::File qw(path);

plugin 'Geolocation::MMDB', {file => path(qw(t data Test-City.mmdb))};

get '/#ip_address' => {ip_address => undef} => sub {
  my $c = shift;

  my $ip_address = $c->param('ip_address');
  my $location   = $c->geolocation($ip_address);

  $c->render(json => $location);
};

local $ENV{MOJO_REVERSE_PROXY} = 1;

my $t = Test::Mojo->new;

$t->get_ok('/', {'X-Forwarded-For' => '176.9.54.163'})
  ->status_is(200)
  ->json_is('/city/names/en'    => 'Falkenstein')
  ->json_is('/country/names/en' => 'Germany');

$t->get_ok('/176.9.54.163')
  ->status_is(200)
  ->json_is('/city/names/lv'    => 'Falkenšteina')
  ->json_is('/country/names/lv' => 'Vācija');

done_testing;
