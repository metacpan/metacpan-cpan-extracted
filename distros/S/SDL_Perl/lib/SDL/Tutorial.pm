package SDL::Tutorial;

use Pod::ToDemo <<'END_HERE';
use SDL::App;

# change these values as necessary
my  $title                   = 'My SDL App';
my ($width, $height, $depth) = ( 640, 480, 16 );

my $app = SDL::App->new(
	-width  => $width,
	-height => $height,
	-depth  => $depth,
	-title  => $title,
);

# your code here; remove the next line
sleep 2;
END_HERE

1;

__END__

=head1 NAME

SDL::Tutorial - introduction to Perl SDL

=head1 SYNOPSIS

	# to read this tutorial
	$ perldoc SDL::Tutorial

	# to create a bare-bones SDL app based on this tutorial
	$ perl -MSDL::Tutorial=basic_app.pl -e 1

=head1 SDL BASICS

SDL, the Simple DirectMedia Layer, is a cross-platform multimedia library.
These are the Perl 5 bindings.  You can find out more about SDL at
L<http://www.libsdl.org/>.

Creating an SDL application with Perl is easy.  You have to know a few basics,
though.  Here's how to get up and running as quickly as possible.

=head2 Surfaces

All graphics in SDL live on a surface.  You'll need at least one.  That's what
L<SDL::App> provides.

Of course, before you can get a surface, you need to initialize your video
mode.  SDL gives you several options, including whether to run in a window or
take over the full screen, the size of the window, the bit depth of your
colors, and whether to use hardware acceleration.  For now, we'll build
something really simple.

=head2 Initialization

SDL::App makes it easy to initialize video and create a surface.  Here's how to
ask for a windowed surface with 640x480x16 resolution:

	use SDL::App;

	my $app = SDL::App->new(
		-width  => 640,
		-height => 480,
		-depth  => 16,
	);

You can get more creative, especially if you use the C<-title> and C<-icon>
attributes in a windowed application.  Here's how to set the window title of
the application to C<My SDL Program>:

	use SDL::App;

	my $app = SDL::App->new(
		-height => 640,
		-width  => 480,
		-depth  => 16,
		-title  => 'My SDL Program',
	);

Setting an icon is a little more involved -- you have to load an image onto a
surface.  That's a bit more complicated, but see the C<-name> parameter to
C<SDL::Surface->new()> if you want to skip ahead.

=head2 Working With The App

Since C<$app> from the code above is just an SDL surface with some extra sugar,
it behaves much like L<SDL::Surface>.  In particular, the all-important C<blit>
and C<update> methods work.  You'll need to create L<SDL::Rect> objects
representing sources of graphics to draw onto the C<$app>'s surface, C<blit>
them there, then C<update> the C<$app>.

B<Note:>  "blitting" is copying a chunk of memory from one place to another.

That, however, is another tutorial.

=head1 SEE ALSO

=over 4

=item L<SDL::Tutorial::Drawing>

basic drawing with rectangles

=item L<SDL::Tutorial::Animation>

basic rectangle animation

=item L<SDL::Tutorial::Images>

image loading and animation

=back

=head1 AUTHOR

chromatic, E<lt>chromatic@wgz.orgE<gt>.  

Written for and maintained by the Perl SDL project, L<http://sdl.perl.org/>.

=head1 COPYRIGHT

Copyright (c) 2003 - 2004, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself, in the hope that it is useful
but certainly under no guarantee.
