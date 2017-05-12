package Ogre::ManualObject;

use strict;
use warnings;

use Ogre::RenderTarget;
our @ISA = qw(Ogre::MovableObject);


1;

__END__
=head1 NAME

Ogre::ManualObject

=head1 SYNOPSIS

  use Ogre;
  use Ogre::ManualObject;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1ManualObject.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->clear()

I<Returns>

=over

=item void

=back

=head2 $obj->setDynamic($dyn)

I<Parameter types>

=over

=item $dyn : bool

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDynamic()

I<Returns>

=over

=item bool

=back

=head2 $obj->beginUpdate($sectionIndex)

I<Parameter types>

=over

=item $sectionIndex : size_t

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
