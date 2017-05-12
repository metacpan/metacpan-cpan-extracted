package Ogre::Node;

use strict;
use warnings;

########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Node::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'TransformSpace' => [qw(
		TS_LOCAL
		TS_PARENT
		TS_WORLD
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::Node

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Node;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Node.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Node->queueNeedUpdate($Node *n)

I<Parameter types>

=over

=item $Node *n : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::Node->processQueuedUpdates()

I<Returns>

=over

=item void

=back

=head1 INSTANCE METHODS

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->getParent()

I<Returns>

=over

=item Node *

=back

=head2 $obj->getOrientation()

I<Returns>

=over

=item Quaternion *

=back

=head2 $obj->setOrientation(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->resetOrientation()

I<Returns>

=over

=item void

=back

=head2 $obj->setPosition(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getPosition()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->setScale(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getScale()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->setInheritOrientation($bool inherit)

I<Parameter types>

=over

=item $bool inherit : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getInheritOrientation()

I<Returns>

=over

=item bool

=back

=head2 $obj->setInheritScale($bool inherit)

I<Parameter types>

=over

=item $bool inherit : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getInheritScale()

I<Returns>

=over

=item bool

=back

=head2 $obj->scale(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->translate(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->roll($DegRad *angle, $int relativeTo=Node::TS_LOCAL)

I<Parameter types>

=over

=item $DegRad *angle : (no info available)

=item $int relativeTo=Node::TS_LOCAL : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->pitch($DegRad *angle, $int relativeTo=Node::TS_LOCAL)

I<Parameter types>

=over

=item $DegRad *angle : (no info available)

=item $int relativeTo=Node::TS_LOCAL : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->yaw($DegRad *angle, $int relativeTo=Node::TS_LOCAL)

I<Parameter types>

=over

=item $DegRad *angle : (no info available)

=item $int relativeTo=Node::TS_LOCAL : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->rotate(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getLocalAxes()

I<Returns>

=over

=item Matrix3 *

=back

=head2 $obj->createChild(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Node *

=back

=head2 $obj->addChild($child)

I<Parameter types>

=over

=item $child : Node *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->numChildren()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getChild(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Node *

=back

=head2 $obj->removeChild(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Node *

=back

=head2 $obj->removeAllChildren()

I<Returns>

=over

=item void

=back

=head2 $obj->getMaterial()

I<Returns>

=over

=item Material *

=back

=head2 $obj->getRenderOperation($OUTLIST RenderOperation *op)

I<Parameter types>

=over

=item $OUTLIST RenderOperation *op : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getWorldOrientation()

I<Returns>

=over

=item Quaternion *

=back

=head2 $obj->getWorldPosition()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->setInitialState()

I<Returns>

=over

=item void

=back

=head2 $obj->resetToInitialState()

I<Returns>

=over

=item void

=back

=head2 $obj->getInitialPosition()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->getInitialOrientation()

I<Returns>

=over

=item Quaternion *

=back

=head2 $obj->getInitialScale()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->getSquaredViewDepth($const Camera *cam)

I<Parameter types>

=over

=item $const Camera *cam : (no info available)

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->needUpdate($bool forceParentUpdate=false)

I<Parameter types>

=over

=item $bool forceParentUpdate=false : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->requestUpdate($Node *child, $bool forceParentUpdate=false)

I<Parameter types>

=over

=item $Node *child : (no info available)

=item $bool forceParentUpdate=false : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->cancelUpdate($Node *child)

I<Parameter types>

=over

=item $Node *child : (no info available)

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
