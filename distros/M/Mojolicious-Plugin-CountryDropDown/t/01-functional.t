#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 6;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown';

app->log->level('debug');

get '/helper' => 'helper';

get '/deprecated' => 'deprecated';

my $t = Test::Mojo->new;

$t->get_ok('/helper')->status_is(200)->content_like(qr/"DE"\s*>Germany<\/option>/);

$t->get_ok('/deprecated')->status_is(200)->content_like(qr/"DE"\s*>Germany<\/option>/);

__DATA__

@@ helper.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field() %>
    </form>
  </body>
</html>

@@ deprecated.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_drop_down() %>
    </form>
  </body>
</html>

