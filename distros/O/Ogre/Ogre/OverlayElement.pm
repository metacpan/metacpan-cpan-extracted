package Ogre::OverlayElement;

use strict;
use warnings;

use Ogre::StringInterface;
our @ISA = qw(Ogre::StringInterface);  # Ogre::Renderable



1;

__END__
=head1 NAME

Ogre::OverlayElement

=head1 SYNOPSIS

  use Ogre;
  use Ogre::OverlayElement;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1OverlayElement.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->initialise()

I<Returns>

=over

=item void

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

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->isVisible()

I<Returns>

=over

=item bool

=back

=head2 $obj->isEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->setEnabled($b)

I<Parameter types>

=over

=item $b : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setDimensions($width, $height)

I<Parameter types>

=over

=item $width : Real

=item $height : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setPosition($left, $top)

I<Parameter types>

=over

=item $left : Real

=item $top : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setWidth($width)

I<Parameter types>

=over

=item $width : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setHeight($height)

I<Parameter types>

=over

=item $height : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setLeft($left)

I<Parameter types>

=over

=item $left : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setTop($top)

I<Parameter types>

=over

=item $top : Real

=back

I<Returns>

=over

=item void

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

=head2 $obj->getMaterialName()

I<Returns>

=over

=item String

=back

=head2 $obj->setMaterialName($matName)

I<Parameter types>

=over

=item $matName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getTypeName()

I<Returns>

=over

=item String

=back

=head2 $obj->getCaption()

I<Returns>

=over

=item String

=back

=head2 $obj->setCaption($text)

I<Parameter types>

=over

=item $text : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setColour($col)

I<Parameter types>

=over

=item $col : ColourValue *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->contains($x, $y)

I<Parameter types>

=over

=item $x : Real

=item $y : Real

=back

I<Returns>

=over

=item bool

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

=head2 $obj->isContainer()

I<Returns>

=over

=item bool

=back

=head2 $obj->isKeyEnabled()

I<Returns>

=over

=item bool

=back

=head2 $obj->isCloneable()

I<Returns>

=over

=item bool

=back

=head2 $obj->getParent()

I<Returns>

=over

=item OverlayContainer *

=back

=head2 $obj->getZOrder()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getSquaredViewDepth($cam)

I<Parameter types>

=over

=item $cam : Camera *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->copyFromTemplate($templateOverlay)

I<Parameter types>

=over

=item $templateOverlay : OverlayElement *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->clone($instanceName)

I<Parameter types>

=over

=item $instanceName : String

=back

I<Returns>

=over

=item OverlayElement *

=back

=head2 $obj->getSourceTemplate()

I<Returns>

=over

=item const OverlayElement *

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
