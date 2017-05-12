package Ogre::Frustum;

use strict;
use warnings;

use Ogre::MovableObject;
use Ogre::Renderable;
our @ISA = qw(Ogre::MovableObject Ogre::Renderable);



1;

__END__
=head1 NAME

Ogre::Frustum

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Frustum;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Frustum.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->setNearClipDistance($Real nearDist)

I<Parameter types>

=over

=item $Real nearDist : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setFarClipDistance($Real farDist)

I<Parameter types>

=over

=item $Real farDist : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setAspectRatio($Real ratio)

I<Parameter types>

=over

=item $Real ratio : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getAspectRatio()

I<Returns>

=over

=item Real

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
