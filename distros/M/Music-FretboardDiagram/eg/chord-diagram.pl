#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::File;

use Music::FretboardDiagram;
use MIME::Base64;

get '/:chord/:position' => sub {
    my $c = shift;

    my $dia = Music::FretboardDiagram->new(
        chord    => $c->param('chord'),
        position => $c->param('position'),
        frets    => 6,
        horiz    => 1,
        font     => '/opt/X11/share/fonts/TTF/VeraMono.ttf',
    );
    $dia->draw;

    my $mojo_file = Mojo::File->new('chord-diagram.png');
    my $raw_string = $mojo_file->slurp;
    my $image = sprintf 'data:image/png;base64,%s', encode_base64( $raw_string, '' );

    $c->stash( image => $image );

    $c->render( template => 'index' );
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Chord Diagram';
<img src="<%= $image %>"/>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
