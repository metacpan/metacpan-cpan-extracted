package OpenGL::XScreenSaver;

use strict;
use warnings;

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('OpenGL::XScreenSaver', $VERSION);

my $window_id = 0;

# for tests
sub _window_id { return $window_id; }
sub _reset_wid { $window_id = 0; }

sub init {
	# parse and remove XScreenSaver specific arguments.
	# stop at the first unknown argument (XScreenSaver will pass its own always
	# first)
	while (@ARGV) {
		if ($ARGV[0] eq "-window-id") {
			$window_id = $ARGV[1];
			$window_id = oct($window_id) if ($window_id =~ /^0/);
			splice(@ARGV, 0, 2);
		} elsif ($ARGV[0] eq "-root") {
			$window_id = "ROOT";
			shift(@ARGV);
		} elsif ($ARGV[0] eq "-mono" or $ARGV[0] eq "-install") {
			shift(@ARGV);
		} elsif ($ARGV[0] eq "-visual") {
			splice(@ARGV, 0, 2);
		} else {
			last;
		}
	}

	# if no window ID has been found yet, check out the environment.
	# XScreenSaver sometimes dumps the window ID there
	if (!$window_id and $ENV{XSCREENSAVER_WINDOW}) {
		$window_id = $ENV{XSCREENSAVER_WINDOW};
		$window_id = oct($window_id) if ($window_id =~ /^0/);
	}

	# if still no window then it seems we have to create one ourselves.
	# leave the window ID set to 0, start() will detect this and create its
	# own window.
	# return the information to the caller because the user might decide she
	# wants it to work in XScreenSaver only, not standalone.
	return ! ! $window_id;
}

sub start {
	xss_connect();
	if ($window_id eq "ROOT") {
		$window_id = xss_root_window();
	}
	xss_init_gl($window_id);
}

sub update {
	xss_update_frame();
	xss_update_viewport();
}

sub dimensions {
	xss_viewport_dimensions();
}

1;

__END__

=head1 NAME

OpenGL::XScreenSaver - prepare environment for writing OpenGL-based XScreenSaver hacks

=head1 SYNOPSIS

 use OpenGL qw(:all);
 use OpenGL::XScreenSaver;

 OpenGL::XScreenSaver::init();
 # GetOptions(...); # parse your own options, if any

 OpenGL::XScreenSaver::start();

 while (1) {
     glClear(...);
     # draw your scene here
     OpenGL::XScreenSaver::update();
 }

=head1 DESCRIPTION

This module allows you to write OpenGL XScreenSaver hacks in Perl. It prepares
the GL to be used with XScreenSaver.

Read the synopsis for how your program might look.

=head2 Description of functions

The B<init()> function will return a true value if a window to draw on has been
found, and a false value if a window will have to be created. This value can
be ignored unless you want to make sure that your screenhack cannot be
executed outside XScreenSaver (e.g. if your standalone version comes as an
extra binary with keyboard control, which would be useless in a screensaver).

The B<start()> function will open the connection to the X server and bind to
the window ID or create a new window to draw on (depends on if it was called
standalone or from XScreenSaver).

The B<update()> function should be called when you finished rendering the
frame. It will flush output and swap the buffers. In the future it might also
handle a minimal set of X events when run in standalone mode (like window
deletion requests by the window manager).

The B<dimensions()> function returns a list with the width and the height of
the currently used window.

=head2 About screenhacks

What follows is a short description of how it works and what XScreenSaver
expects a screenhack to do.

XScreenSaver tells the hack on startup what window ID the hack shall draw to.
This is either a small window mapping to the screen in the preview dialog, or
a fullscreen window. The window ID is passed either via the B<-window-id>
option or via the B<XSCREENSAVER_WINDOW> environment variable. B<init()> of
this module checks both of these.

XScreenSaver handles all user input including exiting and pausing the
screensaver. The process is sent a SIGSTOP when the unlock screen is displayed,
obviously a SIGCONT when it is dismissed, and when the pointing device is
moved or the screen gets unlocked XScreenSaver sends a SIGTERM. This means
that no event handling is required by your screenhack whatsoever. This again
keeps the design of a screenhack dead simple.

=head1 SEE ALSO

L<OpenGL>

=head1 AUTHORS & COPYRIGHTS

Made 2010 by Lars Stoltenow.
OpenGL::XScreenSaver is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

