#!/usr/bin/env perl
use Mojolicious::Lite;

plugin 'GoogleAnalytics';

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
  <title><%= title %></title>
  <%= analytics_inc 'UA-23169268-1' %>
  </head>
  <body><%= content %>
  </body>
</html>
