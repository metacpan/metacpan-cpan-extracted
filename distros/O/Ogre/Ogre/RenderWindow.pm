package Ogre::RenderWindow;

use strict;
use warnings;

use Ogre::RenderTarget;
our @ISA = qw(Ogre::RenderTarget);


1;

__END__
=head1 NAME

Ogre::RenderWindow

=head1 SYNOPSIS

  use Ogre;
  use Ogre::RenderWindow;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1RenderWindow.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->setFullscreen($fullScreen, $width, $height)

I<Parameter types>

=over

=item $fullScreen : bool

=item $width : unsigned int

=item $height : unsigned int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroy()

I<Returns>

=over

=item void

=back

=head2 $obj->resize($width, $height)

I<Parameter types>

=over

=item $width : unsigned int

=item $height : unsigned int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->windowMovedOrResized()

I<Returns>

=over

=item void

=back

=head2 $obj->reposition($left, $top)

I<Parameter types>

=over

=item $left : int

=item $top : int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isVisible()

I<Returns>

=over

=item bool

=back

=head2 $obj->setVisible($visible)

I<Parameter types>

=over

=item $visible : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isClosed()

I<Returns>

=over

=item bool

=back

=head2 $obj->swapBuffers($waitForVSync=true)

I<Parameter types>

=over

=item $waitForVSync=true : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isFullScreen()

I<Returns>

=over

=item bool

=back

=head2 $obj->getMetrics($OUTLIST unsigned int width, $OUTLIST unsigned int height, $OUTLIST unsigned int colourDepth, $OUTLIST int left, $OUTLIST int top)

I<Parameter types>

=over

=item $OUTLIST unsigned int width : (no info available)

=item $OUTLIST unsigned int height : (no info available)

=item $OUTLIST unsigned int colourDepth : (no info available)

=item $OUTLIST int left : (no info available)

=item $OUTLIST int top : (no info available)

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
