package Ogre::Overlay;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::Overlay

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Overlay;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Overlay.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getChild($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item OverlayContainer *

=back

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->setZOrder($zorder)

I<Parameter types>

=over

=item $zorder : unsigned short

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getZOrder()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->isVisible()

I<Returns>

=over

=item bool

=back

=head2 $obj->isInitialised()

I<Returns>

=over

=item bool

=back

=head2 $obj->show()

I<Returns>

=over

=item void

=back

=head2 $obj->hide()

I<Returns>

=over

=item void

=back

=head2 $obj->add2D($cont)

I<Parameter types>

=over

=item $cont : OverlayContainer *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->remove2D($cont)

I<Parameter types>

=over

=item $cont : OverlayContainer *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->add3D($node)

I<Parameter types>

=over

=item $node : SceneNode *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->remove3D($node)

I<Parameter types>

=over

=item $node : SceneNode *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->clear()

I<Returns>

=over

=item void

=back

=head2 $obj->setScroll($x, $y)

I<Parameter types>

=over

=item $x : Real

=item $y : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getScrollX()

I<Returns>

=over

=item Real

=back

=head2 $obj->getScrollY()

I<Returns>

=over

=item Real

=back

=head2 $obj->scroll($xoff, $yoff)

I<Parameter types>

=over

=item $xoff : Real

=item $yoff : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setRotate($angle)

I<Parameter types>

=over

=item $angle : Degree (or Radian) *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->rotate($angle)

I<Parameter types>

=over

=item $angle : Degree (or Radian) *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setScale($x, $y)

I<Parameter types>

=over

=item $x : Real

=item $y : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getScaleX()

I<Returns>

=over

=item Real

=back

=head2 $obj->getScaleY()

I<Returns>

=over

=item Real

=back

=head2 $obj->findElementAt($x, $y)

I<Parameter types>

=over

=item $x : Real

=item $y : Real

=back

I<Returns>

=over

=item OverlayElement *

=back

=head2 $obj->getOrigin()

I<Returns>

=over

=item String

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
