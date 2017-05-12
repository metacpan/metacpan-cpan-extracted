package Ogre::SceneQuery::WorldFragment;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::SceneQuery::WorldFragment

=head1 SYNOPSIS

  use Ogre;
  use Ogre::SceneQuery::WorldFragment;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1SceneQuery_1_1WorldFragment.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->fragmentType($THIS)

I<Parameter types>

=over

=item $THIS : WorldFragment *

=back

I<Returns>

=over

=item int

=back

=head2 $obj->singleIntersection($THIS)

I<Parameter types>

=over

=item $THIS : WorldFragment *

=back

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->planes($THIS)

I<Parameter types>

=over

=item $THIS : WorldFragment *THIS

=back

I<Returns>

=over

=item SV *

=back

=head2 $obj->renderOp($THIS)

I<Parameter types>

=over

=item $THIS : WorldFragment *

=back

I<Returns>

=over

=item RenderOperation *

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
