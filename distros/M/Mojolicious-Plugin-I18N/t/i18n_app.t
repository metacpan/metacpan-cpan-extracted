#!/usr/bin/env perl
use lib qw(t lib ../lib ../mojo/lib ../../mojo/lib);
use utf8;

use Mojo::Base -base;

# Disable Bonjour, IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_IOWATCHER} = 'Mojo::IOWatcher';
}

use Test::More;

use Mojolicious::Lite;

use Test::Mojo;

# I18N plugin
plugin 'I18N' => { namespace => 'App::I18N', default => 'ru', support_url_langs => [qw(ru en de en-us)] };

get '/' => 'index';

#

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)
  ->content_is("ПриветПривет дваru\n");

$t->get_ok('/ru')->status_is(200)
  ->content_is("ПриветПривет дваru\n");

$t->get_ok('/en')->status_is(200)
  ->content_is("helloHello twoen\n");

$t->get_ok('/de')->status_is(200)
  ->content_is("ПриветПривет дваru\n");

$t->get_ok('/en-us')->status_is(200)
  ->content_is("helloHello two USen-us\n");

$t->get_ok('/es')->status_is(404);

done_testing;

__DATA__
@@ index.html.ep
<%=l 'hello' %><%=l 'hello2' %><%= languages %>
