#!/usr/bin/env perl
use Mojolicious::Lite;
use lib 'lib';
plugin 'surveil';
get '/' => 'index';
app->start;

__DATA__
@@ index.html.ep
<html>
<head>
<title>Test surveil over websocket</title>
</head>
<body>
<button id="submit_btn" class="btn active">Click me!</button>
</html>
