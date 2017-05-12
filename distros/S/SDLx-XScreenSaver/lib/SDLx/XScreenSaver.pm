package SDLx::XScreenSaver;

use strict;
use warnings;
use SDLx::App   ();
use SDL::Event  ();
use SDL::Events ();
use SDL::Mouse  ();

our $VERSION = '0.02';

require XSLoader;
XSLoader::load( 'SDLx::XScreenSaver', $VERSION );

my $app;
my $window_id = 0;
my $event;

# Used in tests
sub _window_id { return $window_id; }
sub _reset_wid { $window_id = 0; }

sub init {

    # This is pretty much identical to the logic in OpenGL::XScreenSaver

    # parse and remove XScreenSaver specific arguments.
    while (@ARGV) {
        if ( $ARGV[0] eq "-window-id" ) {
            $window_id = $ARGV[1];
            $window_id = oct($window_id) if ( $window_id =~ /^0/ );
            splice( @ARGV, 0, 2 );
        }
        elsif ( $ARGV[0] eq "-root" ) {
            $window_id = "ROOT";
            shift(@ARGV);
        }
        elsif ( $ARGV[0] eq "-mono" || $ARGV[0] eq "-install" ) {
            shift(@ARGV);
        }
        elsif ( $ARGV[0] eq "-visual" ) {
            splice( @ARGV, 0, 2 );
        }
        else {
            last;
        }
    }

    # if no window ID has been found yet, check out the environment.
    if ( !$window_id and $ENV{XSCREENSAVER_WINDOW} ) {
        $window_id = $ENV{XSCREENSAVER_WINDOW};
        $window_id = oct($window_id) if ( $window_id =~ /^0/ );
    }

    return $window_id ? 1 : 0;
}

sub start {

    # Create and return the SDLx::App object
    my %app_params = @_;
    if ( $window_id eq "ROOT" ) {
        $window_id = xss_root_window();
    }
    if ($window_id) {
        my ( $width, $height ) = xss_viewport_dimensions($window_id);
        if ( $width && $height ) {
            @app_params{ '-width', '-height' } = ( $width, $height );
        }
        $ENV{'SDL_WINDOWID'} = $window_id;
    }
    $app   = SDLx::App->new(%app_params);
    $event = SDL::Event->new();
    SDL::Mouse::show_cursor(0);
    return $app;
}

sub update {

    # flip SDLx::App and poll for exit events
    unless ( defined $app ) {
        die "update() called before start()";
    }
    $app->sync();
    SDL::Events::pump_events();
    while ( SDL::Events::poll_event($event) ) {
        if ( $event->type() == SDL::Event::SDL_QUIT ) {
            exit;
        }
    }
}

sub dimensions {
    if ( defined $app ) {
        return ( $app->w(), $app->h() );
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SDLx::XScreenSaver - prepare environment for writing SDL based XScreenSaver hacks

=head1 SYNOPSIS

  use SDLx::XScreenSaver;

  SDLx::XScreenSaver::init();
  # GetOptions(...); # parse your own options, if any

  my $app = SDLx::XScreenSaver::start();

  while (1) {
     # draw your scene here
     SDLx::XScreenSaver::update();
  }


=head1 DESCRIPTION

This module provides a framework to write SDL XScreenSaver hacks in Perl.
It provides the same basic interface as OpenGL::XScreenSaver.

=head2 Description of functions

The B<init()> function will return a true value if a window to draw on has been
found, and a false value if a window will have to be created. This value can
be ignored unless you want special behavior when the screenhack is
executed outside of XScreenSaver.

The B<start()> function will create a SDLx::App object bound to the window ID
provided by XScreenSaver with the correct width and height.  Any parameters
supplied to start() will be passed through the SDLx::App->new().  The return
value is the SDLx::App object.

The B<update()> function should be called when you finish drawing a frame.
It will sync the SDLx::App object and poll for exit events.

The B<dimensions()> function returns a list with the width and the height of
the currently used window.

=head1 SEE ALSO

L<SDL>
L<SDLx::App>
L<OpenGL::XScreenSaver>

=head1 AUTHOR

John Lightsey, E<lt>john@nixnuts.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by John Lightsey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
