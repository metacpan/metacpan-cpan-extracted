#!/usr/bin/env perl
use strict;
use warnings;

# Usage:
# http://$host/:chord/:position[?showname={0,Chord+Name}]
# Examples:
# http://localhost:5000
# http://localhost:5000/002220/1
# http://localhost:5000/012340/1?showname=0
# http://localhost:5000/012340/3?showname=Xb+dim

use Dancer2;
use lib '/Users/gene/sandbox/Music-FretboardDiagram/lib';
use Music::FretboardDiagram;
use Imager;

get '/' => sub { redirect '/x02220/1' };

get '/:chord/:position' => sub {
    my $dia = Music::FretboardDiagram->new(
        chord    => route_parameters->get('chord'),
        position => route_parameters->get('position'),
        showname => query_parameters->get('showname') // 1,
        frets    => 6,
        horiz    => 1,
        image    => 1,
        font     => '/opt/X11/share/fonts/TTF/VeraMono.ttf',
    );
    my $i = $dia->draw;

    my $data;
    $i->write( data => \$data, type => $dia->type )
        or die "Can't write to memory: ", $i->errstr;

    send_file( \$data, content_type => 'image/' . $dia->type );
};

start;
