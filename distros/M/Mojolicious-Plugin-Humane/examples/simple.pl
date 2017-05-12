#!/usr/bin/env perl

use Mojolicious::Lite;

BEGIN {
  for ( qw{ lib ../lib } ) {
    unshift @INC, $_ if -d;
  }
}

plugin 'Humane';

get '/' => sub {
  my $self = shift;
  $self->humane_stash( 'Who are you?' );
  $self->render( 'simple' );
};

app->start;


__DATA__

@@ simple.html.ep
% humane_stash 'Just me';
<!DOCTYPE html>
<html>
  <head><title>Simple</title></head>
  <body>
    Got a question?
  </body>
</html>

