use SDL;
use SDL::Video;
use SDL::Surface;
use SDL::Rect;
use SDL::Event;
use SDL::Events;
use SDL::Image;

###no strict 'refs';

use lib '.';
use RogueQuest::room1;

# the size of the window box or the screen resolution if fullscreen
my $screen_width   = 800;
my $screen_height  = 600;

SDL::init(SDL_INIT_VIDEO);

# setting video mode
my $screen_surface = SDL::Video::set_video_mode($screen_width,
						$screen_height,
						32,
						SDL_ANYFORMAT);

# drawing a rectangle with the blue color
my $mapped_color   = SDL::Video::map_RGB($screen_surface->format(),
					 0, 0, 255);
my $event = SDL::Event->new();
        
my $quit  = 0;

my $x = 0, $y = 0;
my $room = RogueGame::room1->new(0,0);

while (!$quit) {
  # Updates the queue to recent events
  SDL::Events::pump_events();
  
  # process all available events
  while ( SDL::Events::poll_event($event) ) {
    
    my $key_name = SDL::Events::get_key_name( $event->key_sym );

    if ( $event->type == SDL_KEYDOWN )
      {
	$quit = 1 if $key_name =~ /q/;
	$quit = 1 if $event->key_sym == SDLK_ESCAPE; ### 27;

	if ($event->key_sym == SDLK_RIGHT) {
		$room->move_left;
	}

	if ($event->key_sym == SDLK_LEFT) {
		$room->move_right;
	}

	if ($event->key_sym == SDLK_UP) {
		$room->move_down;
	}

	if ($event->key_sym == SDLK_DOWN) {
		$room->move_up;
	}

	$room->update($screen_surface);

      }

    # check by Event type
    do_quit() if $event->type == SDL_QUIT;

SDL::Video::update_rect( $screen_surface, 0, 0, $screen_width, $screen_height );
SDL::Video::flip( $screen_surface );


  }
}

sub do_quit { $quit = 1 }
