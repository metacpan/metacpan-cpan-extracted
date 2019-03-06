#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::File;

use Music::FretboardDiagram;
use Imager;

get '/:chord/:position' => sub {
    my $c = shift;

    my $dia = Music::FretboardDiagram->new(
        chord    => $c->param('chord'),
        position => $c->param('position'),
        frets    => 6,
        horiz    => 1,
        image    => 1,
        font     => '/opt/X11/share/fonts/TTF/VeraMono.ttf',
    );
    my $i = $dia->draw;

    my $data;
    $i->write( data => \$data, type => 'png' )
        or die "Can't write to memory: ", $i->errstr;

    $c->render( data => $data, format => 'png' );
};

app->start;
