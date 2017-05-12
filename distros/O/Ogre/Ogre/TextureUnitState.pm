package Ogre::TextureUnitState;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::TextureUnitState::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'TextureEffectType' => [qw(
		ET_ENVIRONMENT_MAP
		ET_PROJECTIVE_TEXTURE
		ET_UVSCROLL
		ET_USCROLL
		ET_VSCROLL
		ET_ROTATE
		ET_TRANSFORM
	)],
	'EnvMapType' => [qw(
		ENV_PLANAR
		ENV_CURVED
		ENV_REFLECTION
		ENV_NORMAL
	)],
	'TextureTransformType' => [qw(
		TT_TRANSLATE_U
		TT_TRANSLATE_V
		TT_SCALE_U
		TT_SCALE_V
		TT_ROTATE
	)],
	'TextureAddressingMode' => [qw(
		TAM_WRAP
		TAM_MIRROR
		TAM_CLAMP
		TAM_BORDER
	)],
	'TextureCubeFace' => [qw(
		CUBE_FRONT
		CUBE_BACK
		CUBE_LEFT
		CUBE_RIGHT
		CUBE_UP
		CUBE_DOWN
	)],
	'BindingType' => [qw(
		BT_FRAGMENT
		BT_VERTEX
	)],
	'ContentType' => [qw(
		CONTENT_NAMED
		CONTENT_SHADOW
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
