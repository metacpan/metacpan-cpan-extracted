package Ogre::OverlayContainer;

use strict;
use warnings;

use Ogre::OverlayElement;
our @ISA = qw(Ogre::OverlayElement);


1;

__END__
=head1 NAME

Ogre::OverlayContainer

=head1 SYNOPSIS

  use Ogre;
  use Ogre::OverlayContainer;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1OverlayContainer.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->isContainer()

I<Returns>

=over

=item bool

=back

=head2 $obj->addChild($elem)

I<Parameter types>

=over

=item $elem : OverlayElement *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->addChildImpl($cont)

I<Parameter types>

=over

=item $cont : OverlayContainer *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeChild($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getChild($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item OverlayElement *

=back

=head2 $obj->isChildrenProcessEvents()

I<Returns>

=over

=item bool

=back

=head2 $obj->setChildrenProcessEvents($val)

I<Parameter types>

=over

=item $val : bool

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
