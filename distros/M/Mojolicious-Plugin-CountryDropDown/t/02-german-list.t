#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 6;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown', { language => 'de' };

app->log->level('debug');

get '/de_helper' => 'de_helper';

get '/en_helper' => 'en_helper';

my $t = Test::Mojo->new;

$t->get_ok('/de_helper')->status_is(200)->content_like(qr/"DE"\s*>Deutschland<\/option>/);

$t->get_ok('/en_helper')->status_is(200)->content_like(qr/"DE"\s*>Germany<\/option>/);

#warn $t->get_ok('/en_helper')->_get_content($t->tx);

__DATA__

@@ de_helper.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field() %>
    </form>
  </body>
</html>

@@ en_helper.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field({ language => 'en' }) %>
    </form>
  </body>
</html>

