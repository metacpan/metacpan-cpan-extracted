#!/usr/bin/env perl
#
# Viewer.pl
#
#	This is just a simple image viewer that will load an image
# passed as an arg on the command line.
#
# usage: 	./Viewer.pl yomama.jpg
#
use SDL::App;
use SDL::Surface;
use SDL::Event;

my $fname = $ARGV[0];
if ("" eq $fname ) { 
	print "Usage:	./Viewer.pl filename\n"; 
	exit(1); 
}

$img = new SDL::Surface -name => $fname;

$app = new SDL::App -title => $fname, 
		-icon_title => "Viewer.pl",
		-icon => "wilbur.png",
		-width => $img->width, 
		-height => $img->height;

$srect = new SDL::Rect -height => $img->height, -width => $img->width;
$drect = new SDL::Rect -height => $img->height, -width => $img->width;

$img->blit($srect,$app,$drect);

$app->flip();

$event = new SDL::Event;
$event->set(SDL_SYSWMEVENT,SDL_IGNORE);
while (1) {
	$event->wait;
	if ( $event->type == SDL_QUIT ) { exit; }
	if ( $event->type == SDL_KEYDOWN ) {
		if ($event->key_sym() == SDLK_ESCAPE) { exit; }
	}
}

