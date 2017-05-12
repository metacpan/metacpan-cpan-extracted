#!/usr/bin/perl

use strict;
use lib 'lib';

use SDLx::Coro::REPL;
use SDLx::Controller::Coro;


use Coro;
use Coro::EV;
use AnyEvent;

use SDL;
use SDLx::App;
use SDLx::Rect;
use SDL::Event;
use SDL::Audio;
use SDL::Mixer;
use SDL::Mixer::Music;

our $app;
our $pixel_format;

sub init_video {

  SDL::init( SDL_INIT_AUDIO | SDL_INIT_VIDEO );

  $app = SDLx::App->new(
    -title => 'rectangle',
    -width => 640,
    -height => 480,
  );
   
  # Initial background
  $pixel_format = $app->format;
  my $blue_pixel = SDL::Video::map_RGB( $pixel_format, 0x00, 0x00, 0xff );
  my $rect = SDL::Rect->new( 0,0, $app->w, $app->h);
  SDL::Video::fill_rect( $app, $rect, $blue_pixel );

}


sub init_audio {
  SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 1024 );
  my ( $status, $freq, $format, $channels ) = @{ SDL::Mixer::query_spec() };
  # my $audiospec =
    # sprintf( "%s, %s, %s, %s\n", $status, $freq, $format, $channels );
  # print ' Asked for freq, format, channels ',
    # join( ' ', ( 44100, AUDIO_S16, 2, ) ),
    # "\n";
  # print ' Got back status, freq, format, channels ',
    # join( ' ', ( $status, $freq, $format, $channels ) ),
    # "\n";
}

# Make an async box
sub make_box {
  my ($speed, $initial_x, $initial_y) = @_;
  my $color = SDL::Video::map_RGB( $pixel_format, int rand 256, int rand 256, int rand 256 );
 
  async {
    my $grect = SDLx::Rect->new($initial_x, $initial_y, 10, 10);
    my $x_direction = 1;
    my $y_direction = 1;
    while(1) {
      #$grect = $grect->move($x_direction,$y_direction);
      $grect->x($grect->x + $x_direction);
      $grect->y($grect->y + $y_direction);
      # print "X: " . $grect->x . " Y: " . $grect->y . " speed: $speed\n";
      $x_direction = -1*$x_direction if $grect->x > 630 || $grect->x < 1;
      $y_direction = -1*$y_direction if $grect->y > 470 || $grect->y < 1;
      SDL::Video::fill_rect( $app, $grect, $color );
      # SDL::Video::update_rect($app, 0, 0, 640, 480);

      my $done = AnyEvent->condvar;
      my $delay = AnyEvent->timer( after => $speed, cb => sub { $done->send;  } );
      $done->recv;
    }
  };

}

sub main {
  init_video();
  # init_audio();

  print q{

Welcome to the REPL!

Here is something for you to try:

   make_box(0.01,63,400)

or if that gets boring, try:

  make_box(rand, int rand 640, int rand 400) for 1..100

... have fun!
};

  my $repl = SDLx::Coro::REPL::start();

  my $game = SDLx::Controller::Coro->new;

  $game->add_event_handler( sub {
    my $event = shift;
    # print STDERR "In event handler\n";
    if($event->type == SDL_QUIT) {
      print "All done!\n";
      exit;
    }
    if($event->type == SDL_MOUSEBUTTONDOWN) {
      print "New Box Time!\n";
      make_box(0.01, (int rand 630) + 1, (int rand 470) + 1);
    }
    return 1;
  });

  $game->add_show_handler( sub {
    SDL::Video::update_rect($app, 0, 0, 640, 480);
  });

  # Give the REPL access to the $app
  $repl->eval('my $app = $::app');

  # my $song = SDL::Mixer::Music::load_MUS('01-PC-Speaker-Sorrow.ogg');
  # SDL::Mixer::Music::play_music( $song, 0 );

  $game->run;
}

main();

