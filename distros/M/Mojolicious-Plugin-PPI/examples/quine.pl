#!/usr/bin/env perl

use Mojolicious::Lite;
use lib 'lib';

plugin 'PPI';
get '/' => sub {
  my $self = shift;
  $self->stash( file => __FILE__ );
  $self->render('quine');
};

app->start;

__DATA__

@@ quine.html.ep
% title 'A Mojolicious "Quine"';
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    %= ppi_css
  </head>
  <body>
    <h2><%= title %></h2>
    %= ppi $file
  </body>
</html>
