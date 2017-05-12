package Ogre::MeshManager;

use strict;
use warnings;

use Ogre::ResourceManager;
use Ogre::ManualResourceLoader;
our @ISA = qw(Ogre::ResourceManager Ogre::ManualResourceLoader);


1;

__END__
=head1 NAME

Ogre::MeshManager

=head1 SYNOPSIS

  use Ogre;
  use Ogre::MeshManager;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1MeshManager.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::MeshManager->getSingletonPtr()

I<Returns>

=over

=item MeshManager *

=back

=head1 INSTANCE METHODS

=head2 $obj->()

I<Returns>

=over

=item Mesh *

=back

=head2 $obj->createManual($name, $groupName, $loader=0)

I<Parameter types>

=over

=item $name : String

=item $groupName : String

=item $loader=0 : ManualResourceLoader *

=back

I<Returns>

=over

=item Mesh *

=back

=head2 $obj->()

I<Returns>

=over

=item Mesh *

=back

=head2 $obj->()

I<Returns>

=over

=item Mesh *

=back

=head2 $obj->()

I<Returns>

=over

=item Mesh *

=back

=head2 $obj->setPrepareAllMeshesForShadowVolumes($bool enable)

I<Parameter types>

=over

=item $bool enable : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getPrepareAllMeshesForShadowVolumes()

I<Returns>

=over

=item bool

=back

=head2 $obj->getBoundsPaddingFactor()

I<Returns>

=over

=item Real

=back

=head2 $obj->setBoundsPaddingFactor($Real paddingFactor)

I<Parameter types>

=over

=item $Real paddingFactor : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->loadResource($res)

I<Parameter types>

=over

=item $res : Resource *

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
