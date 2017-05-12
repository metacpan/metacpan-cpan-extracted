package Ogre::WindowEventUtilities;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::WindowEventUtilities

=head1 SYNOPSIS

  use Ogre;
  use Ogre::WindowEventUtilities;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1WindowEventUtilities.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::WindowEventUtilities->messagePump()

I<Returns>

=over

=item void

=back

=head2 Ogre::WindowEventUtilities->addWindowEventListener($win, $perlListener)

I<Parameter types>

=over

=item $win : RenderWindow *

=item $perlListener : SV *

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::WindowEventUtilities->removeWindowEventListener($win, $perlListener)

I<Parameter types>

=over

=item $win : RenderWindow *

=item $perlListener : SV *

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
