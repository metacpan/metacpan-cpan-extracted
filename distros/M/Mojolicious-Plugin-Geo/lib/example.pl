#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojolicious::Plugin::Geo;

plugin 'geo';


get '/google_is_where' => sub {
  my $self = shift;
  
  $self->render({ json => $self->geo('8.8.8.8') });
};

app->start;
