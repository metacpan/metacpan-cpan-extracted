#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 8;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown', { prefer => [ 'DE', 'AT', 'CH', ] };

app->log->level('debug');

get '/helper1' => 'helper1';

get '/helper2' => 'helper2';

my $t = Test::Mojo->new;

$t->get_ok('/helper1')->status_is(200)->content_like(qr/<option[^>]+value="DE"[^>]*>Germany<.+>Germany</);

$t->get_ok('/helper2')->status_is(200)->content_like(qr/<option[^>]+selected="selected"[^>]*>Germany</)
    ->content_like( qr/>Germany<\/option>.+>Austria<\/option>.+>Switzerland<\/option>.+>Germany</ )
    ->content_like(qr/<option[^>]+disabled="disabled"[^>]*>-----<\/option>/);

#warn $t->get_ok('/helper2')->_get_content($t->tx);

__DATA__

@@ helper1.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field() %>
	</form>
  </body>
</html>

@@ helper2.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field({ select => 'DE' }) %>
	</form>
  </body>
</html>

