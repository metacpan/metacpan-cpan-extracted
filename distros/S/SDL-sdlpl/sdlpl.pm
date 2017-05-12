package SDL::sdlpl;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
use AutoLoader 'AUTOLOAD';

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.08';

bootstrap SDL::sdlpl $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SDL::sdlpl - Perl bindings for the SDL

=head1 SYNOPSIS

  use SDL::sdlpl;

=head1 DESCRIPTION

	sdlpl is a collection of bindings for functions in the
Simple DirectMedia Layer, and an assortment of related utilities.
The module sdlpl is not indended for direct use, but rather serves
as the backbone of a collection of Object-Oriented modules which
provide access to the SDL library.

	The associated modules are App.pm, Surface.pm, Event.pm, Rect.pm,
Palette.pm, Mixer.pm, Cdrom.pm and OpenGL.pm.

=head1 AUTHOR

David J. Goehrig
Wayne Keenan      

=head1 SEE ALSO

perl(1) App(3) Surface(3) Event(3) Rect(3) Palette(3) Mixer(3) Cdrom(3)
OpenGL(3) OpenGL::App(3)

=cut
