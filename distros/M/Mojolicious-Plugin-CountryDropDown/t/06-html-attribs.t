#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 21;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown';

app->log->level('debug');

get '/helper1' => 'helper1';

get '/helper2' => 'helper2';

get '/helper3' => sub {
    my $app = shift;

    # name attr will be overwritten in template
    $app->csf_conf( { language => 'de', html_attr => { name => 'test' }, } );
    $app->render;
};

get '/helper4' => sub {
    my $app = shift;

    $app->csf_conf( {} );
    $app->render( template => 'helper3' );
};

my $t = Test::Mojo->new;

$t->get_ok('/helper1')->status_is(200)->content_like(qr/<select id="country" name="country">/)
    ->content_like(qr/>Germany</);

$t->get_ok('/helper2')->status_is(200)->content_like(qr/<select id="myid" name="myname">/);

$t->get_ok('/helper3')->status_is(200)->content_like(qr/<select[^>]+class="somecssclass"/)
    ->content_unlike(qr/<select[^>]+id="myid"/)->content_like(qr/<select[^>]+name="country"/)
    ->content_like(qr/<select[^>]+data-wtf="xxx"/)->content_like(qr/>Deutschland</);

$t->get_ok('/helper4')->status_is(200)->content_like(qr/<select[^>]+class="somecssclass"/)
    ->content_unlike(qr/<select[^>]+id="myid"/)->content_like(qr/<select[^>]+name="country"/)
    ->content_like(qr/<select[^>]+data-wtf="xxx"/)->content_like(qr/>Germany</);
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
      <%= country_select_field({ html_attr => { id => "myid", name => "myname" } }) %>
    </form>
  </body>
</html>

@@ helper3.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field({ html_attr => { id => undef, class => "somecssclass", "data-wtf" => "xxx" } }) %>
    </form>
  </body>
</html>

