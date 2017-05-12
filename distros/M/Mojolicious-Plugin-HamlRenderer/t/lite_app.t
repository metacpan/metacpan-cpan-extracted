#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

use Test::Mojo;
use Mojolicious::Lite;

# Silence
app->log->level('fatal');

# Load plugin
plugin 'haml_renderer';

# Set default handler
app->renderer->default_handler('haml');

get '/' => 'root';

get '/error' => 'error';

get '/with_wrapper' => 'with_wrapper';

my $t = Test::Mojo->new;

# No cache
$t->get_ok('/')->status_is(200)->content_is("<foo>1 + 1 &lt; 2</foo>\n");

# Cache hit
$t->get_ok('/')->status_is(200)->content_is("<foo>1 + 1 &lt; 2</foo>\n");

# With wrapper
$t->get_ok('/with_wrapper')->status_is(200)->content_is("<foo>Hello!\n</foo>\n");

# Cache with wrapper
$t->get_ok('/with_wrapper')->status_is(200)->content_is("<foo>Hello!\n</foo>\n");

# Not found
$t->get_ok('/foo')->status_is(404)->content_is("Not found\n");

# Error
$t->get_ok('/error')->status_is(500)->content_like(qr/^Exception:.+syntax error/s);

1;
__DATA__

@@ root.html.haml
%foo 1 + 1 < 2

@@ error.html.haml
= 1 + {

@@ exception.html.haml
Exception:
= $exception

@@ not_found.html.haml
Not found

@@ with_wrapper.html.haml
- layout 'wrapper';
Hello!

@@ layouts/wrapper.html.haml
%foo= content
