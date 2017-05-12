package Ogre::OverlayManager;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::OverlayManager

=head1 SYNOPSIS

  use Ogre;
  use Ogre::OverlayManager;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1OverlayManager.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::OverlayManager->getSingletonPtr()

I<Returns>

=over

=item OverlayManager *

=back

=head1 INSTANCE METHODS

=head2 $obj->create($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Overlay *

=back

=head2 $obj->getByName($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item Overlay *

=back

=head2 $obj->destroy($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAll()

I<Returns>

=over

=item void

=back

=head2 $obj->hasViewportChanged()

I<Returns>

=over

=item bool

=back

=head2 $obj->getViewportHeight()

I<Returns>

=over

=item int

=back

=head2 $obj->getViewportWidth()

I<Returns>

=over

=item int

=back

=head2 $obj->getViewportAspectRatio()

I<Returns>

=over

=item Real

=back

=head2 $obj->createOverlayElement($typeName, $instanceName, $isTemplate=false)

I<Parameter types>

=over

=item $typeName : String

=item $instanceName : String

=item $isTemplate=false : bool

=back

I<Returns>

=over

=item OverlayElement *

=back

=head2 $obj->getOverlayElement($name, $isTemplate=false)

I<Parameter types>

=over

=item $name : String

=item $isTemplate=false : bool

=back

I<Returns>

=over

=item OverlayElement *

=back

=head2 $obj->destroyOverlayElement($instanceName, $isTemplate=false)

I<Parameter types>

=over

=item $instanceName : String

=item $isTemplate=false : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllOverlayElements($isTemplate=false)

I<Parameter types>

=over

=item $isTemplate=false : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->isTemplate($strName)

I<Parameter types>

=over

=item $strName : String

=back

I<Returns>

=over

=item bool

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
