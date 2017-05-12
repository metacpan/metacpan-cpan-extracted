package Ogre::Renderable;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::Renderable

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Renderable;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Renderable.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->getSquaredViewDepth($cam)

I<Parameter types>

=over

=item $cam : Camera *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->getNumWorldTransforms()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getCastsShadows()

I<Returns>

=over

=item bool

=back

=head2 $obj->getPolygonModeOverrideable()

I<Returns>

=over

=item bool

=back

=head2 $obj->setPolygonModeOverrideable($override)

I<Parameter types>

=over

=item $override : bool

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
