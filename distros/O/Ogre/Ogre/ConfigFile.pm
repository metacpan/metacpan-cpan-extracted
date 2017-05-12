package Ogre::ConfigFile;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::ConfigFile

=head1 SYNOPSIS

  use Ogre;
  use Ogre::ConfigFile;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1ConfigFile.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::ConfigFile->new()

I<Returns>

=over

=item ConfigFile *

=back

=head2 Ogre::ConfigFile->DESTROY()

This method is called automatically; don't call it yourself.

=head1 INSTANCE METHODS

=head2 $obj->load($filename)

I<Parameter types>

=over

=item $filename : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->clear()

I<Returns>

=over

=item void

=back

=head2 $obj->getSections()

I<Returns>

=over

=item SV *

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
