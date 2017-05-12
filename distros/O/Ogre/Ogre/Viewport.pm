package Ogre::Viewport;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::Viewport

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Viewport;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Viewport.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->update()

I<Returns>

=over

=item void

=back

=head2 $obj->getTarget()

I<Returns>

=over

=item RenderTarget *

=back

=head2 $obj->getCamera()

I<Returns>

=over

=item Camera *

=back

=head2 $obj->setCamera($cam)

I<Parameter types>

=over

=item $cam : Camera *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getZOrder()

I<Returns>

=over

=item int

=back

=head2 $obj->getLeft()

I<Returns>

=over

=item Real

=back

=head2 $obj->getTop()

I<Returns>

=over

=item Real

=back

=head2 $obj->getWidth()

I<Returns>

=over

=item Real

=back

=head2 $obj->getHeight()

I<Returns>

=over

=item Real

=back

=head2 $obj->getActualLeft()

I<Returns>

=over

=item int

=back

=head2 $obj->getActualTop()

I<Returns>

=over

=item int

=back

=head2 $obj->getActualWidth()

I<Returns>

=over

=item int

=back

=head2 $obj->getActualHeight()

I<Returns>

=over

=item int

=back

=head2 $obj->setDimensions($left, $top, $width, $height)

I<Parameter types>

=over

=item $left : Real

=item $top : Real

=item $width : Real

=item $height : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setBackgroundColour($colour)

I<Parameter types>

=over

=item $colour : ColourValue *colour

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setClearEveryFrame($clear, $buffers=FBT_COLOUR|FBT_DEPTH)

I<Parameter types>

=over

=item $clear : bool

=item $buffers=FBT_COLOUR|FBT_DEPTH : unsigned int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getClearEveryFrame()

I<Returns>

=over

=item bool

=back

=head2 $obj->getClearBuffers()

I<Returns>

=over

=item unsigned int

=back

=head2 $obj->setMaterialScheme($schemeName)

I<Parameter types>

=over

=item $schemeName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getMaterialScheme()

I<Returns>

=over

=item String

=back

=head2 $obj->getActualDimensions($OUTLIST int left, $OUTLIST int top, $OUTLIST int width, $OUTLIST int height)

I<Parameter types>

=over

=item $OUTLIST int left : (no info available)

=item $OUTLIST int top : (no info available)

=item $OUTLIST int width : (no info available)

=item $OUTLIST int height : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setOverlaysEnabled($enabled)

I<Parameter types>

=over

=item $enabled : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getOverlaysEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->setSkiesEnabled($enabled)

I<Parameter types>

=over

=item $enabled : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getSkiesEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->setShadowsEnabled($enabled)

I<Parameter types>

=over

=item $enabled : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getShadowsEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->setVisibilityMask($mask)

I<Parameter types>

=over

=item $mask : uint32

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getVisibilityMask()

I<Returns>

=over

=item uint32

=back

=head2 $obj->setRenderQueueInvocationSequenceName($sequenceName)

I<Parameter types>

=over

=item $sequenceName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderQueueInvocationSequenceName()

I<Returns>

=over

=item String

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
