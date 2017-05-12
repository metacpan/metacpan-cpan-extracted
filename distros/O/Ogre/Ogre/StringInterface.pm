package Ogre::StringInterface;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::StringInterface

=head1 SYNOPSIS

  use Ogre;
  use Ogre::StringInterface;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1StringInterface.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::StringInterface->cleanupDictionary()

I<Returns>

=over

=item void

=back

=head1 INSTANCE METHODS

=head2 $obj->setParameter($name, $value)

I<Parameter types>

=over

=item $name : String

=item $value : String

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->getParameter($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item String

=back

=head2 $obj->copyParametersTo($dest)

I<Parameter types>

=over

=item $dest : StringInterface *

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
