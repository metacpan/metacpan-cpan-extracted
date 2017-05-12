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
  ->element_exists('html body div[id=dxctl1]')
  ->text_is('script' => q{$(window).on("load",function(){
$("#dxctl1").dxPopup({contentTemplate: "Sample content",
title: "Test popup"});
});});

done_testing;

__DATA__
@@ index.html.ep
% layout 'main';
%= dxpopup undef, 'Test popup' => 'Sample content'

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