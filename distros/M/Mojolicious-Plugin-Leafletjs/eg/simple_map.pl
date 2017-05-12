#!/usr/bin/env perl
use Mojolicious::Lite;

# Documentation browser under "/perldoc"
plugin 'Leafletjs';

app->secret('testing a mojolicious plugin yo');

get '/' => sub {
    my $self = shift;
    $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<div><h1>Showing a simple map with markers, popups, and circles!</h1></div>
<div id="map"></div>
<%= leaflet {
    name      => 'map1',
    latitude => '35.9239',
    longitude  => '-78.4611',
    zoomLevel => 16,
    markers   => [
        {   name      => 'marker1',
            latitude => '35.9239',
            longitude  => '-78.4611',
            popup     => '<h3>Header</h3>A new message tada!',
        },
        {   name      => 'marker2',
            latitude => '35.9235',
            longitude  => '-78.4610',
            popup     => 'A second popup here!',
        }
    ],
    circles => [
        {   name        => 'circly',
            longitude   => '-78.4611',
            latitude    => '35.9239',
            color       => 'red',
            fillColor   => '#f03',
            fillOpacity => 0.5,
            radius      => 500,
        },
      ],

}
%>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
%= stylesheet begin
#map {
    height: 600px;
    width: 760px;
    border-radius: 5px;
}
%= end
  <body><%= content %></body>
</html>
