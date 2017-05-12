package Ogre::Matrix3;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::Matrix3

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Matrix3;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Matrix3.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Matrix3->new(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Matrix3 *

=back

=head2 Ogre::Matrix3->DESTROY()

This method is called automatically; don't call it yourself.

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
