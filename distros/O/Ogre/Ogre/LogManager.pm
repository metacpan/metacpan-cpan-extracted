package Ogre::LogManager;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::LogManager

=head1 SYNOPSIS

  use Ogre;
  use Ogre::LogManager;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1LogManager.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::LogManager->getSingletonPtr()

I<Returns>

=over

=item LogManager *

=back

=head1 INSTANCE METHODS

=head2 $obj->logMessage($message)

I<Parameter types>

=over

=item $message : String

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
