#!/usr/bin/env perl
use Mojolicious::Lite;

use lib '../lib';

plugin 'Util::Endpoint';

get '/test' => sub {
  shift->render( text => 'Mounted.' );
};

(get '/probe')->to(
  cb => sub {
    shift->render( text => 'Mounted Endpoint.' )
  })->endpoint('probe');

get '/get-ep' => sub {
  my $c = shift;
  return $c->render( text => $c->endpoint('probe') );
};

get '/get-url' => sub {
  my $c = shift;
  return $c->render( text => $c->url_for('probe') );
};

app->start;
