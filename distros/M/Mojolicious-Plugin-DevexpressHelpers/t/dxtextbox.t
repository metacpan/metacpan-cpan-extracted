#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

# Disable epoll, kqueue and IPv6
BEGIN { $ENV{MOJO_POLL} = $ENV{MOJO_NO_IPV6} = 1 }

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
plugin 'DevexpressHelpers';
app->log->level('error'); #silence

# routes
get '/' => 'index';

# Test
my $t = Test::Mojo->new;

# GET / default
$t->get_ok('/')
  ->status_is(200)
  #TODO: check label existence...
  #->element_exists('html body div[id="program.name"]')
  ->element_exists('html body div[id="resource.name"]')
  ->text_is('script' => q{$(window).on("load",function(){
$("#resource\\\\.name").dxTextBox({name: "resource.name",
placeHolder: "Type a resource name",
value: "default value"});
});});

done_testing;

__DATA__
@@ index.html.ep
% layout 'main';
%= dxtextbox 'resource.name' => 'default value' => 'Name: ', { placeHolder => 'Type a resource name' }

@@ layouts/main.html.ep
<!doctype html>
<html>
    <head>
       <title>Test</title>
    </head>
    <body><%== content %>
%= dxbuild
</body>
</html>