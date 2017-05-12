package Ogre::Animation;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Animation::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'InterpolationMode' => [qw(
		IM_LINEAR
		IM_SPLINE
	)],
	'RotationInterpolationMode' => [qw(
		RIM_LINEAR
		RIM_SPHERICAL
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::Animation

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Animation;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Animation.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Animation->setDefaultInterpolationMode($int im)

I<Parameter types>

=over

=item $int im : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::Animation->getDefaultInterpolationMode()

I<Returns>

=over

=item int

=back

=head2 Ogre::Animation->setDefaultRotationInterpolationMode($int im)

I<Parameter types>

=over

=item $int im : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 Ogre::Animation->getDefaultRotationInterpolationMode()

I<Returns>

=over

=item int

=back

=head1 INSTANCE METHODS

=head2 $obj->getName()

I<Returns>

=over

=item String

=back

=head2 $obj->getLength()

I<Returns>

=over

=item Real

=back

=head2 $obj->createNodeTrack($handle, ...)

I<Parameter types>

=over

=item $handle : unsigned short

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item NodeAnimationTrack *

=back

=head2 $obj->createNumericTrack($handle, ...)

I<Parameter types>

=over

=item $handle : unsigned short

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item NumericAnimationTrack *

=back

=head2 $obj->createVertexTrack($handle, ...)

I<Parameter types>

=over

=item $handle : unsigned short

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item VertexAnimationTrack *

=back

=head2 $obj->getNumNodeTracks()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getNodeTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item NodeAnimationTrack *

=back

=head2 $obj->hasNodeTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->getNumNumericTracks()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getNumericTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item NumericAnimationTrack *

=back

=head2 $obj->hasNumericTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->getNumVertexTracks()

I<Returns>

=over

=item unsigned short

=back

=head2 $obj->getVertexTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item VertexAnimationTrack *

=back

=head2 $obj->hasVertexTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item bool

=back

=head2 $obj->destroyNodeTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyNumericTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyVertexTrack($unsigned short handle)

I<Parameter types>

=over

=item $unsigned short handle : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllTracks()

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllNodeTracks()

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllNumericTracks()

I<Returns>

=over

=item void

=back

=head2 $obj->destroyAllVertexTracks()

I<Returns>

=over

=item void

=back

=head2 $obj->apply(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setInterpolationMode($int im)

I<Parameter types>

=over

=item $int im : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getInterpolationMode()

I<Returns>

=over

=item int

=back

=head2 $obj->setRotationInterpolationMode($int im)

I<Parameter types>

=over

=item $int im : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRotationInterpolationMode()

I<Returns>

=over

=item int

=back

=head2 $obj->getNodeTrackAref()

I<Returns>

=over

=item AV *

=back

=head2 $obj->getNumericTrackAref()

I<Returns>

=over

=item AV *

=back

=head2 $obj->getVertexTrackAref()

I<Returns>

=over

=item AV *

=back

=head2 $obj->optimise($bool discardIdentityNodeTracks=true)

I<Parameter types>

=over

=item $bool discardIdentityNodeTracks=true : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->clone($newName)

I<Parameter types>

=over

=item $newName : String

=back

I<Returns>

=over

=item Animation *

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
