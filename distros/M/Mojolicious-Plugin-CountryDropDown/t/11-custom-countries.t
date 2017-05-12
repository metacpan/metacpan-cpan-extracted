#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 23;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown', {
	select => 'FOO',
	names  => { FOO => 'foo-country', BAR => 'bar-country', BAZ => 'baz-country', }
};

app->log->level('debug');

get '/form'        => 'form';
get '/form_pref_a' => 'form_pref_a';
get '/form_pref_b' => 'form_pref_b';
get '/form_de'     => 'form_de';

my $t = Test::Mojo->new;

$t->get_ok('/form')
  ->status_is(200)
  ->content_like(qr/<option value="BAR">bar-country</)
  ->content_like(qr/<option value="BAZ">baz-country</)
  ->content_like(qr/<option selected="selected" value="FOO">foo-country</)
  ->content_unlike(qr/<option value="FOO">foo-country</)
  ->content_like(qr/<option value="DE">Germany</);

#warn $t->get_ok('/form')->_get_content($t->tx);

$t->get_ok('/form_pref_a')
  ->status_is(200)
  ->content_like(qr/<select id="country" name="country"><option selected="selected" value="FOO">foo-country<\/option><option value="BAR">bar-country<\/option><option value="BAZ">baz-country<\/option><option disabled="disabled" value="">-----<\/option>/)
  ->content_like(qr/<option value="FOO">foo-country</)
  ->content_like(qr/<option value="DE">Germany</);

$t->get_ok('/form_pref_b')
  ->status_is(200)
  ->content_like(qr/<select id="country" name="country"><option value="BAZ">baz-country<\/option><option value="BAR">bar-country<\/option><option selected="selected" value="FOO">foo-country<\/option><option disabled="disabled" value="">-----<\/option>/)
  ->content_like(qr/<option value="FOO">foo-country</)
  ->content_like(qr/<option value="DE">Germany</);

$t->get_ok('/form_de')
  ->status_is(200)
  ->content_like(qr/<option value="FOO">foo-country</)
  ->content_like(qr/<option value="BAR">bar-country</)
  ->content_like(qr/<option value="BAZ">baz-country</)
  ->content_like(qr/<option selected="selected" value="DE">Deutschland<\/option>/);

__DATA__

@@ form.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field() %>
	</form>
  </body>
</html>

@@ form_pref_a.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field({ prefer => [ 'FOO', 'BAR', 'BAZ', ], }) %>
	</form>
  </body>
</html>

@@ form_pref_b.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field({ prefer => [ 'BAZ', 'BAR', 'FOO', ], }) %>
	</form>
  </body>
</html>

@@ form_de.html.ep
<html>
  <head></head>
  <body>
    <form>
      <%= country_select_field({ language => 'DE', select => 'DE', }) %>
	</form>
  </body>
</html>

