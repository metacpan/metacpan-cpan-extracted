#!/usr/bin/env perl
#
# CDplayer.pl
#
#	This is just a simple cd playing app that provides a simple
# graphical bar to play cd's with.

use SDL::App;
use SDL::Surface;
use SDL::Event;
use SDL::Cdrom;

# The next four lines create the application window

$img = new SDL::Surface -name => "cdplayer.png";
$app = new SDL::App 		-title => "CDplayer.pl",
			-icon => "cd-icon.png",
			-width => $img->width, 
			-height => $img->height;
$rect = new SDL::Rect -width => $img->width, -height => $img->height;
$img->blit($rect,$app,$rect);
$app->flip;

# Open the first cdrom drive on the machine

$cdrom = new SDL::Cdrom 0; # assume we only have one, this could get fancier
print $app->error;	# we've initilized everything, so print any config error

# what follows is the event loop for the entire program

$event = new SDL::Event;			# create a new Event
$event->set(SDL_SYSWMEVENT,SDL_IGNORE);		# ignore all wm events

# A variable to keep track what track index we are on.
$track = 0;
$left = $cdrom->num_tracks;	

# The cdplayer.png skin is made up of 6 equal areas
# known as eject, back, stop, play, pause, and forward.
# we scale this so that we can use different sized images
$w = $img->width / 6;

while (1) {
	$event->wait;				# wait for an event
	if ($event->type == SDL_QUIT ) { exit; } 	# quit on quit events 
	if ($event->type == SDL_MOUSEBUTTONDOWN ) {		# grab button events
		$x = $event->button_x;		# Get the position
		if ($x < $w ) { $cdrom->eject; print STDERR "Ejecting\n"; next;}
# eject
		if ($x < $w * 2 ) { 			# back
			if ( $track > 0 ) { 
				$track = $track - 1; 
				$left = $left + 1;
			}
			if ( $cdrom->status eq "playing" ) {	# if playing
				$cdrom->play($track,$left);	# keep playing
			}
			print STDERR "Track: $track\n";
			next;
		}
		if ($x < $w * 3 ) { 			# stop
			$cdrom->stop();
			print STDERR "Stopped\n";
			next;
		}
		if ($x < $w * 4 ) {  			# play
			$cdrom->play($track,$left);
			print STDERR "Track: $track\n";
			next;
		}		
		if ($x < $w * 5 ) { 			# pause/resume
			if ( $cdrom->status eq "playing" ) {	# if playing
				$cdrom->pause;			# pause
				print STDERR "Paused\n";
			} 
			elsif ( $cdrom->status eq "paused" ) {	# elif paused
				$cdrom->resume;			# resume
				print STDERR "Track: $track\n";
			}
			next;
		}
		else {  				# forward
			if ( $left != 0 ) {
				$left = $left - 1;
				$track = $track + 1;
			}
			if ( $cdrom->status eq "playing" ) {	# if playing
				$cdrom->play($track,$left);	# keep playing
			}
			print STDERR "Track: $track\n";
			next;	# we could just fall through but what the heck
		}		
	}
}

