#!/usr/bin/env perl
use Mojolicious::Lite;

plugin 'Disqus::Tiny';

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

<%= disqus_inc 'astokes' %>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
  <title><%= title %></title>
  </head>
  <body><%= content %>
  </body>
</html>
