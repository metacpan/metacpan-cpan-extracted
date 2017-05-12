package Ogre::MaterialManager;

use strict;
use warnings;

use Ogre::ResourceManager;
our @ISA = qw(Ogre::ResourceManager);



1;

__END__
=head1 NAME

Ogre::MaterialManager

=head1 SYNOPSIS

  use Ogre;
  use Ogre::MaterialManager;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1MaterialManager.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::MaterialManager->getSingletonPtr()

I<Returns>

=over

=item MaterialManager *

=back

=head1 INSTANCE METHODS

=head2 $obj->load($String name, $String group, $bool isManual=false, $ManualResourceLoader *loader=0)

I<Parameter types>

=over

=item $String name : (no info available)

=item $String group : (no info available)

=item $bool isManual=false : (no info available)

=item $ManualResourceLoader *loader=0 : (no info available)

=back

I<Returns>

=over

=item Material *

=back

=head2 $obj->setDefaultTextureFiltering($fo)

I<Parameter types>

=over

=item $fo : int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setDefaultAnisotropy($maxAniso)

I<Parameter types>

=over

=item $maxAniso : unsigned int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDefaultAnisotropy()

I<Returns>

=over

=item unsigned int

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
