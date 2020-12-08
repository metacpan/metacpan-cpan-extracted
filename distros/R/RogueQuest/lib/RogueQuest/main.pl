use SDL;
use SDL::Video;
use SDL::Surface;
use SDL::Rect;
use SDL::Event;
use SDL::Events;
use SDL::Image;

###no strict 'refs';

use lib '.';
use RogueGame::room1;
###use RogueGame::entity;

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
#SDL::Video::fill_rect($screen_surface,
#		      SDL::Rect->new($screen_width / 4, $screen_height / 4,
#				     $screen_width / 2, $screen_height / 2),
#		      $mapped_color);

# update an area on the screen so it&#39;s visible
#SDL::Video::update_rect($screen_surface, 0, 0,
#			$screen_width, $screen_height);

my $event = SDL::Event->new();
        
my $quit  = 0;
my $image = SDL::Image::load("./pics/gargoyle1.png");
SDL::Video::set_color_key($image, SDL_RLEACCEL, $image->format->colorkey);

###SDL::Video::blit_surface( $image, SDL::Rect->new(0, 0, $image->w, $image->h), 
###                           $screen_surface,  SDL::Rect->new(0, 0, $screen_surface->w,  $screen_surface->h) );

 SDL::Video::update_rect( $screen_surface, 0, 0, $screen_surface_width, $screen_surface_height );

my $x = 0, $y = 0;
my $room = RogueGame::room1->new(0,0);
##my $entity = RogueGame::entity->new(100,100,48,48);
##print "---> " . $entity . " ---> " . $entity->{imagestates} . "\n";
##$entity->{imagestates}->add("./pics/gargoyle1.png");

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

	###SDL::Video::blit_surface( $image, SDL::Rect->new($x--, $y--, $image->w, $image->h), 	$screen_surface,  SDL::Rect->new(0,0, $screen_surface->w,  $screen_surface->h) );
	#
	###$x++;
	###SDL::Video::blit_surface( $image, SDL::Rect->new(0,0, $image->w, $image->h), 	$screen_surface,  SDL::Rect->new($x,0, $screen_surface->w,  $screen_surface->h) ); 

	$room->update($screen_surface);

      }

    # check by Event type
    do_quit() if $event->type == SDL_QUIT;

SDL::Video::update_rect( $screen_surface, 0, 0, $screen_width, $screen_height );
SDL::Video::flip( $screen_surface );


  }
}

sub do_quit { $quit = 1 }
