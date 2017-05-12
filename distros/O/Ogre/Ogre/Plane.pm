package Ogre::Plane;

use strict;
use warnings;



########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Plane::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'Side' => [qw(
		NO_SIDE
		POSITIVE_SIDE
		NEGATIVE_SIDE
		BOTH_SIDE
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::Plane

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Plane;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Plane.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Plane->new(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Plane *

=back

=head2 Ogre::Plane->DESTROY()

This method is called automatically; don't call it yourself.

=head1 INSTANCE METHODS

=head2 $obj->getDistance($rkPoint)

I<Parameter types>

=over

=item $rkPoint : Vector3 *

=back

I<Returns>

=over

=item Real

=back

=head2 $obj->normalise()

I<Returns>

=over

=item Real

=back

=head2 $obj->d()

I<Returns>

=over

=item Real

=back

=head2 $obj->setD($d)

I<Parameter types>

=over

=item $d : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->normal()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->setNormal($normal)

I<Parameter types>

=over

=item $normal : Vector3 *

=back

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
