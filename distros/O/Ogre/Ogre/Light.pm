package Ogre::Light;

use strict;
use warnings;

use Ogre::MovableObject;
our @ISA = qw(Ogre::MovableObject);


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Light::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'LightTypes' => [qw(
		LT_POINT
		LT_DIRECTIONAL
		LT_SPOTLIGHT
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END

1;

__END__
=head1 NAME

Ogre::Light

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Light;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Light.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 INSTANCE METHODS

=head2 $obj->setType($type)

I<Parameter types>

=over

=item $type : int

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getType()

I<Returns>

=over

=item int

=back

=head2 $obj->setDiffuseColour(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDiffuseColour()

I<Returns>

=over

=item ColourValue *

=back

=head2 $obj->setSpecularColour(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getSpecularColour()

I<Returns>

=over

=item ColourValue *

=back

=head2 $obj->setAttenuation($Real range, $Real constant, $Real linear, $Real quadratic)

I<Parameter types>

=over

=item $Real range : (no info available)

=item $Real constant : (no info available)

=item $Real linear : (no info available)

=item $Real quadratic : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getAttenuationRange()

I<Returns>

=over

=item Real

=back

=head2 $obj->getAttenuationConstant()

I<Returns>

=over

=item Real

=back

=head2 $obj->getAttenuationLinear()

I<Returns>

=over

=item Real

=back

=head2 $obj->getAttenuationQuadric()

I<Returns>

=over

=item Real

=back

=head2 $obj->setPosition(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getPosition()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->setDirection(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getDirection()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->setSpotlightRange($innerAngle, $outerAngle, $falloff=1.0)

I<Parameter types>

=over

=item $innerAngle : Degree (or Radian) *

=item $outerAngle : Degree (or Radian) *

=item $falloff=1.0 : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getSpotlightInnerAngle()

I<Returns>

=over

=item Radian *

=back

=head2 $obj->getSpotlightOuterAngle()

I<Returns>

=over

=item Radian *

=back

=head2 $obj->getSpotlightFalloff()

I<Returns>

=over

=item Real

=back

=head2 $obj->setSpotlightInnerAngle($val)

I<Parameter types>

=over

=item $val : Degree (or Radian) *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setSpotlightOuterAngle($val)

I<Parameter types>

=over

=item $val : Degree (or Radian) *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setSpotlightFalloff($Real val)

I<Parameter types>

=over

=item $Real val : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->setPowerScale($Real power)

I<Parameter types>

=over

=item $Real power : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getPowerScale()

I<Returns>

=over

=item Real

=back

=head2 $obj->getBoundingBox()

I<Returns>

=over

=item AxisAlignedBox *

=back

=head2 $obj->getMovableType()

I<Returns>

=over

=item String

=back

=head2 $obj->getDerivedPosition()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->getDerivedDirection()

I<Returns>

=over

=item Vector3 *

=back

=head2 $obj->setVisible($bool visible)

I<Parameter types>

=over

=item $bool visible : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getBoundingRadius()

I<Returns>

=over

=item Real

=back

=head2 $obj->getTypeFlags()

I<Returns>

=over

=item uint32

=back

=head2 $obj->createAnimableValue($valueName)

I<Parameter types>

=over

=item $valueName : String

=back

I<Returns>

=over

=item AnimableValue *

=back

=head2 $obj->resetCustomShadowCameraSetup()

I<Returns>

=over

=item void

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
