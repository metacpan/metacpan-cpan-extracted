#!/usr/bin/env perl
#
#	Flicker.pl
#
#	This is just a brain dead slide show that demonstrates 
#	the SDL_FULLSCREEN flag, and Cursor::show(0) for hiding
#	the cursor.  It quits as soon as you move the mouse.
 
use SDL::App;
use SDL::Surface;
use SDL::Event;
use SDL::Cursor;

$app = new SDL::App 	-title => "Flicker", 
		-icon => "wilbur.png",
		-flags => SDL_FULLSCREEN,
		-width => 800,
		-height => 600;

@files = split(/\s+\n*/,`ls`);

$e = new SDL::Event;
$e->set(SDL_SYSWMEVENT,SDL_IGNORE);

SDL::Cursor::show(0);

while(1) {

for $f (@files) {

	my ($name,$ext) = split(/\./,$f);
	if ( ($ext eq "gif") || ($ext eq "jpg") || ($ext eq "png")) {
		$img = new SDL::Surface -name => $f;
		if ($drect) { $app->fill($drect,0); }
		$rect = new SDL::Rect -height => $img->height, -width => $img->width;
		$drect = new SDL::Rect 	-height => $img->height,
					-width => $img->width,
					-x => 400 - $img->width / 2,
					-y => 300 - $img->height /2;
		$img->blit($rect,$app,$drect);
		$app->flip();
	} else { next; }

for ( 1 .. 10 ) {
	$e->pump;
	$e->poll;
	if ($e->type == SDL_MOUSEMOTION) { exit; }	
	$app->delay(200);
}
}
}
