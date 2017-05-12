package Ogre::TextureManager;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::TextureManager

=head1 SYNOPSIS

  use Ogre;
  use Ogre::TextureManager;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1TextureManager.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::TextureManager->getSingletonPtr()

I<Returns>

=over

=item TextureManager *

=back

=head1 INSTANCE METHODS

=head2 $obj->load($String name, $String group, $int texType=TEX_TYPE_2D, $int numMipmaps=MIP_DEFAULT, $Real gamma=1.0f, $bool isAlpha=false, $int desiredFormat=PF_UNKNOWN)

I<Parameter types>

=over

=item $String name : (no info available)

=item $String group : (no info available)

=item $int texType=TEX_TYPE_2D : (no info available)

=item $int numMipmaps=MIP_DEFAULT : (no info available)

=item $Real gamma=1.0f : (no info available)

=item $bool isAlpha=false : (no info available)

=item $int desiredFormat=PF_UNKNOWN : (no info available)

=back

I<Returns>

=over

=item Texture *

=back

=head2 $obj->setDefaultNumMipmaps($size_t num)

I<Parameter types>

=over

=item $size_t num : (no info available)

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
