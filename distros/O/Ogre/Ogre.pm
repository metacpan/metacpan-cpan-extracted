package Ogre;

use 5.006;
use strict;
use warnings;

require DynaLoader;
our @ISA = qw(DynaLoader);

our $VERSION = '0.60';

# use all files under Ogre/ - probably not a good idea
## BEGIN USES
use Ogre::AnimableObject;
use Ogre::AnimableValue;
use Ogre::Animation;
use Ogre::AnimationControllerFunction;
use Ogre::AnimationState;
use Ogre::AnimationStateSet;
use Ogre::AnimationTrack;
use Ogre::AxisAlignedBox;
use Ogre::AxisAlignedBoxSceneQuery;
use Ogre::Billboard;
use Ogre::BillboardChain;
use Ogre::BillboardSet;
use Ogre::Bone;
use Ogre::BorderPanelOverlayElement;
use Ogre::Camera;
use Ogre::ColourValue;
use Ogre::CompositionPass;
use Ogre::CompositionTargetPass;
use Ogre::ConfigFile;
use Ogre::ControllerManager;
use Ogre::ControllerReal;
use Ogre::DataStream;
use Ogre::Degree;
use Ogre::EdgeData;
use Ogre::Entity;
use Ogre::Exception;
use Ogre::Frustum;
use Ogre::GpuProgram;
use Ogre::GpuProgramParameters;
use Ogre::HardwareBuffer;
use Ogre::HardwareBufferManager;
use Ogre::HardwareIndexBuffer;
use Ogre::HardwarePixelBuffer;
use Ogre::HardwareVertexBuffer;
use Ogre::Image;
use Ogre::IndexData;
use Ogre::InstancedGeometry::InstancedObject;
use Ogre::InstancedGeometry;
use Ogre::IntersectionSceneQuery;
use Ogre::KeyFrame;
use Ogre::Light;
use Ogre::Log;
use Ogre::LogManager;
use Ogre::ManualObject::ManualObjectSection;
use Ogre::ManualObject;
use Ogre::ManualResourceLoader;
use Ogre::Material;
use Ogre::MaterialManager;
use Ogre::Math;
use Ogre::Matrix3;
use Ogre::Matrix4;
use Ogre::Mesh;
use Ogre::MeshManager;
use Ogre::MeshPtr;
use Ogre::MovableObject;
use Ogre::MultiRenderTarget;
use Ogre::Node;
use Ogre::NodeAnimationTrack;
use Ogre::NumericAnimationTrack;
use Ogre::Overlay;
use Ogre::OverlayContainer;
use Ogre::OverlayElement;
use Ogre::OverlayManager;
use Ogre::PanelOverlayElement;
use Ogre::Particle;
use Ogre::ParticleAffector;
use Ogre::ParticleEmitter;
use Ogre::ParticleSystem;
use Ogre::ParticleSystemRenderer;
use Ogre::Pass;
use Ogre::PassthroughControllerFunction;
use Ogre::PatchMesh;
use Ogre::PatchSurface;
use Ogre::Plane;
use Ogre::PlaneBoundedVolume;
use Ogre::PlaneBoundedVolumeListSceneQuery;
use Ogre::Pose;
use Ogre::Quaternion;
use Ogre::QueuedRenderableCollection;
use Ogre::Radian;
use Ogre::Ray;
use Ogre::RaySceneQuery;
use Ogre::RegionSceneQuery;
use Ogre::RenderOperation;
use Ogre::RenderSystem;
use Ogre::RenderSystemCapabilities;
use Ogre::RenderTarget;
use Ogre::RenderTexture;
use Ogre::RenderWindow;
use Ogre::Renderable;
use Ogre::Resource;
use Ogre::ResourceGroupManager;
use Ogre::ResourceManager;
use Ogre::RibbonTrail;
use Ogre::Root;
use Ogre::ScaleControllerFunction;
use Ogre::SceneManager;
use Ogre::SceneNode;
use Ogre::SceneQuery::WorldFragment;
use Ogre::SceneQuery;
use Ogre::ScriptLoader;
use Ogre::Serializer;
use Ogre::ShadowCaster;
use Ogre::Skeleton;
use Ogre::SkeletonInstance;
use Ogre::SkeletonManager;
use Ogre::Sphere;
use Ogre::SphereSceneQuery;
use Ogre::StaticGeometry;
use Ogre::StringInterface;
use Ogre::SubEntity;
use Ogre::SubMesh;
use Ogre::TagPoint;
use Ogre::Technique;
use Ogre::TextAreaOverlayElement;
use Ogre::Texture;
use Ogre::TextureManager;
use Ogre::TextureUnitState;
use Ogre::TimeIndex;
use Ogre::Timer;
use Ogre::TransformKeyFrame;
use Ogre::Vector2;
use Ogre::Vector3;
use Ogre::Vector4;
use Ogre::VertexAnimationTrack;
use Ogre::VertexBufferBinding;
use Ogre::VertexCacheProfiler;
use Ogre::VertexData;
use Ogre::VertexDeclaration;
use Ogre::VertexElement;
use Ogre::Viewport;
use Ogre::WaveformControllerFunction;
use Ogre::WindowEventUtilities;
## END USES

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

__PACKAGE__->bootstrap($VERSION);


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'SceneType' => [qw(
		ST_GENERIC
		ST_EXTERIOR_CLOSE
		ST_EXTERIOR_FAR
		ST_EXTERIOR_REAL_FAR
		ST_INTERIOR
	)],
	'StencilOperation' => [qw(
		SOP_KEEP
		SOP_ZERO
		SOP_REPLACE
		SOP_INCREMENT
		SOP_DECREMENT
		SOP_INCREMENT_WRAP
		SOP_DECREMENT_WRAP
		SOP_INVERT
	)],
	'TexCoordCalcMethod' => [qw(
		TEXCALC_NONE
		TEXCALC_ENVIRONMENT_MAP
		TEXCALC_ENVIRONMENT_MAP_PLANAR
		TEXCALC_ENVIRONMENT_MAP_REFLECTION
		TEXCALC_ENVIRONMENT_MAP_NORMAL
		TEXCALC_PROJECTIVE_TEXTURE
	)],
	'Capabilities' => [qw(
		RSC_AUTOMIPMAP
		RSC_BLENDING
		RSC_ANISOTROPY
		RSC_DOT3
		RSC_CUBEMAPPING
		RSC_HWSTENCIL
		RSC_VBO
		RSC_VERTEX_PROGRAM
		RSC_FRAGMENT_PROGRAM
		RSC_TEXTURE_COMPRESSION
		RSC_TEXTURE_COMPRESSION_DXT
		RSC_TEXTURE_COMPRESSION_VTC
		RSC_SCISSOR_TEST
		RSC_TWO_SIDED_STENCIL
		RSC_STENCIL_WRAP
		RSC_HWOCCLUSION
		RSC_USER_CLIP_PLANES
		RSC_VERTEX_FORMAT_UBYTE4
		RSC_INFINITE_FAR_PLANE
		RSC_HWRENDER_TO_TEXTURE
		RSC_TEXTURE_FLOAT
		RSC_NON_POWER_OF_2_TEXTURES
		RSC_TEXTURE_3D
		RSC_POINT_SPRITES
		RSC_POINT_EXTENDED_PARAMETERS
		RSC_VERTEX_TEXTURE_FETCH
		RSC_MIPMAP_LOD_BIAS
	)],
	'IlluminationStage' => [qw(
		IS_AMBIENT
		IS_PER_LIGHT
		IS_DECAL
	)],
	'GuiVerticalAlignment' => [qw(
		GVA_TOP
		GVA_CENTER
		GVA_BOTTOM
	)],
	'GuiHorizontalAlignment' => [qw(
		GHA_LEFT
		GHA_CENTER
		GHA_RIGHT
	)],
	'GuiMetricsMode' => [qw(
		GMM_RELATIVE
		GMM_PIXELS
		GMM_RELATIVE_ASPECT_ADJUSTED
	)],
	'MaterialScriptSection' => [qw(
		MSS_NONE
		MSS_MATERIAL
		MSS_TECHNIQUE
		MSS_PASS
		MSS_TEXTUREUNIT
		MSS_PROGRAM_REF
		MSS_PROGRAM
		MSS_DEFAULT_PARAMETERS
		MSS_TEXTURESOURCE
	)],
	'LogMessageLevel' => [qw(
		LML_TRIVIAL
		LML_NORMAL
		LML_CRITICAL
	)],
	'LoggingLevel' => [qw(
		LL_LOW
		LL_NORMAL
		LL_BOREME
	)],
	'SkeletonAnimationBlendMode' => [qw(
		ANIMBLEND_AVERAGE
		ANIMBLEND_CUMULATIVE
	)],
	'TextureMipmap' => [qw(
		MIP_UNLIMITED
		MIP_DEFAULT
	)],
	'TextureType' => [qw(
		TEX_TYPE_1D
		TEX_TYPE_2D
		TEX_TYPE_3D
		TEX_TYPE_CUBE_MAP
	)],
	'TextureUsage' => [qw(
		TU_STATIC
		TU_DYNAMIC
		TU_WRITE_ONLY
		TU_STATIC_WRITE_ONLY
		TU_DYNAMIC_WRITE_ONLY
		TU_DYNAMIC_WRITE_ONLY_DISCARDABLE
		TU_AUTOMIPMAP
		TU_RENDERTARGET
		TU_DEFAULT
	)],
	'ImageFlags' => [qw(
		IF_COMPRESSED
		IF_CUBEMAP
		IF_3D_TEXTURE
	)],
	'PixelComponentType' => [qw(
		PCT_BYTE
		PCT_SHORT
		PCT_FLOAT16
		PCT_FLOAT32
		PCT_COUNT
	)],
	'PixelFormatFlags' => [qw(
		PFF_HASALPHA
		PFF_COMPRESSED
		PFF_FLOAT
		PFF_DEPTH
		PFF_NATIVEENDIAN
		PFF_LUMINANCE
	)],
	'PixelFormat' => [qw(
		PF_UNKNOWN
		PF_L8
		PF_BYTE_L
		PF_L16
		PF_SHORT_L
		PF_A8
		PF_BYTE_A
		PF_A4L4
		PF_BYTE_LA
		PF_R5G6B5
		PF_B5G6R5
		PF_R3G3B2
		PF_A4R4G4B4
		PF_A1R5G5B5
		PF_R8G8B8
		PF_B8G8R8
		PF_A8R8G8B8
		PF_A8B8G8R8
		PF_B8G8R8A8
		PF_R8G8B8A8
		PF_X8R8G8B8
		PF_X8B8G8R8
		PF_BYTE_RGB
		PF_BYTE_BGR
		PF_BYTE_BGRA
		PF_BYTE_RGBA
		PF_A2R10G10B10
		PF_A2B10G10R10
		PF_DXT1
		PF_DXT2
		PF_DXT3
		PF_DXT4
		PF_DXT5
		PF_FLOAT16_R
		PF_FLOAT16_RGB
		PF_FLOAT16_RGBA
		PF_FLOAT32_R
		PF_FLOAT32_RGB
		PF_FLOAT32_RGBA
		PF_FLOAT16_GR
		PF_FLOAT32_GR
		PF_DEPTH
		PF_SHORT_RGBA
		PF_SHORT_GR
		PF_SHORT_RGB
		PF_COUNT
	)],
	'FrustumPlane' => [qw(
		FRUSTUM_PLANE_NEAR
		FRUSTUM_PLANE_FAR
		FRUSTUM_PLANE_LEFT
		FRUSTUM_PLANE_RIGHT
		FRUSTUM_PLANE_TOP
		FRUSTUM_PLANE_BOTTOM
	)],
	'ProjectionType' => [qw(
		PT_ORTHOGRAPHIC
		PT_PERSPECTIVE
	)],
	'BillboardType' => [qw(
		BBT_POINT
		BBT_ORIENTED_COMMON
		BBT_ORIENTED_SELF
		BBT_PERPENDICULAR_COMMON
		BBT_PERPENDICULAR_SELF
	)],
	'BillboardRotationType' => [qw(
		BBR_VERTEX
		BBR_TEXCOORD
	)],
	'BillboardOrigin' => [qw(
		BBO_TOP_LEFT
		BBO_TOP_CENTER
		BBO_TOP_RIGHT
		BBO_CENTER_LEFT
		BBO_CENTER
		BBO_CENTER_RIGHT
		BBO_BOTTOM_LEFT
		BBO_BOTTOM_CENTER
		BBO_BOTTOM_RIGHT
	)],
	'ShadowRenderableFlags' => [qw(
		SRF_INCLUDE_LIGHT_CAP
		SRF_INCLUDE_DARK_CAP
		SRF_EXTRUDE_TO_INFINITY
	)],
	'GpuConstantType' => [qw(
		GCT_FLOAT1
		GCT_FLOAT2
		GCT_FLOAT3
		GCT_FLOAT4
		GCT_SAMPLER1D
		GCT_SAMPLER2D
		GCT_SAMPLER3D
		GCT_SAMPLERCUBE
		GCT_SAMPLER1DSHADOW
		GCT_SAMPLER2DSHADOW
		GCT_MATRIX_2X2
		GCT_MATRIX_2X3
		GCT_MATRIX_2X4
		GCT_MATRIX_3X2
		GCT_MATRIX_3X3
		GCT_MATRIX_3X4
		GCT_MATRIX_4X2
		GCT_MATRIX_4X3
		GCT_MATRIX_4X4
		GCT_INT1
		GCT_INT2
		GCT_INT3
		GCT_INT4
		GCT_UNKNOWN
	)],
	'GpuProgramType' => [qw(
		GPT_VERTEX_PROGRAM
		GPT_FRAGMENT_PROGRAM
	)],
	'SceneBlendFactor' => [qw(
		SBF_ONE
		SBF_ZERO
		SBF_DEST_COLOUR
		SBF_SOURCE_COLOUR
		SBF_ONE_MINUS_DEST_COLOUR
		SBF_ONE_MINUS_SOURCE_COLOUR
		SBF_DEST_ALPHA
		SBF_SOURCE_ALPHA
		SBF_ONE_MINUS_DEST_ALPHA
		SBF_ONE_MINUS_SOURCE_ALPHA
	)],
	'SceneBlendType' => [qw(
		SBT_TRANSPARENT_ALPHA
		SBT_TRANSPARENT_COLOUR
		SBT_ADD
		SBT_MODULATE
		SBT_REPLACE
	)],
	'LayerBlendSource' => [qw(
		LBS_CURRENT
		LBS_TEXTURE
		LBS_DIFFUSE
		LBS_SPECULAR
		LBS_MANUAL
	)],
	'LayerBlendOperationEx' => [qw(
		LBX_SOURCE1
		LBX_SOURCE2
		LBX_MODULATE
		LBX_MODULATE_X2
		LBX_MODULATE_X4
		LBX_ADD
		LBX_ADD_SIGNED
		LBX_ADD_SMOOTH
		LBX_SUBTRACT
		LBX_BLEND_DIFFUSE_ALPHA
		LBX_BLEND_TEXTURE_ALPHA
		LBX_BLEND_CURRENT_ALPHA
		LBX_BLEND_MANUAL
		LBX_DOTPRODUCT
		LBX_BLEND_DIFFUSE_COLOUR
	)],
	'LayerBlendOperation' => [qw(
		LBO_REPLACE
		LBO_ADD
		LBO_MODULATE
		LBO_ALPHA_BLEND
	)],
	'LayerBlendType' => [qw(
		LBT_COLOUR
		LBT_ALPHA
	)],
	'RenderQueueGroupID' => [qw(
		RENDER_QUEUE_BACKGROUND
		RENDER_QUEUE_SKIES_EARLY
		RENDER_QUEUE_1
		RENDER_QUEUE_2
		RENDER_QUEUE_WORLD_GEOMETRY_1
		RENDER_QUEUE_3
		RENDER_QUEUE_4
		RENDER_QUEUE_MAIN
		RENDER_QUEUE_6
		RENDER_QUEUE_7
		RENDER_QUEUE_WORLD_GEOMETRY_2
		RENDER_QUEUE_8
		RENDER_QUEUE_9
		RENDER_QUEUE_SKIES_LATE
		RENDER_QUEUE_OVERLAY
		RENDER_QUEUE_MAX
	)],
	'ParameterType' => [qw(
		PT_BOOL
		PT_REAL
		PT_INT
		PT_UNSIGNED_INT
		PT_SHORT
		PT_UNSIGNED_SHORT
		PT_LONG
		PT_UNSIGNED_LONG
		PT_STRING
		PT_VECTOR3
		PT_MATRIX3
		PT_MATRIX4
		PT_QUATERNION
		PT_COLOURVALUE
	)],
	'FrameBufferType' => [qw(
		FBT_COLOUR
		FBT_DEPTH
		FBT_STENCIL
	)],
	'SortMode' => [qw(
		SM_DIRECTION
		SM_DISTANCE
	)],
	'TrackVertexColourEnum' => [qw(
		TVC_NONE
		TVC_AMBIENT
		TVC_DIFFUSE
		TVC_SPECULAR
		TVC_EMISSIVE
	)],
	'ShadowTechnique' => [qw(
		SHADOWTYPE_NONE
		SHADOWDETAILTYPE_ADDITIVE
		SHADOWDETAILTYPE_MODULATIVE
		SHADOWDETAILTYPE_INTEGRATED
		SHADOWDETAILTYPE_STENCIL
		SHADOWDETAILTYPE_TEXTURE
		SHADOWTYPE_STENCIL_MODULATIVE
		SHADOWTYPE_STENCIL_ADDITIVE
		SHADOWTYPE_TEXTURE_MODULATIVE
		SHADOWTYPE_TEXTURE_ADDITIVE
		SHADOWTYPE_TEXTURE_ADDITIVE_INTEGRATED
		SHADOWTYPE_TEXTURE_MODULATIVE_INTEGRATED
	)],
	'PolygonMode' => [qw(
		PM_POINTS
		PM_WIREFRAME
		PM_SOLID
	)],
	'WaveformType' => [qw(
		WFT_SINE
		WFT_TRIANGLE
		WFT_SQUARE
		WFT_SAWTOOTH
		WFT_INVERSE_SAWTOOTH
		WFT_PWM
	)],
	'ManualCullingMode' => [qw(
		MANUAL_CULL_NONE
		MANUAL_CULL_BACK
		MANUAL_CULL_FRONT
	)],
	'CullingMode' => [qw(
		CULL_NONE
		CULL_CLOCKWISE
		CULL_ANTICLOCKWISE
	)],
	'FogMode' => [qw(
		FOG_NONE
		FOG_EXP
		FOG_EXP2
		FOG_LINEAR
	)],
	'ShadeOptions' => [qw(
		SO_FLAT
		SO_GOURAUD
		SO_PHONG
	)],
	'FilterOptions' => [qw(
		FO_NONE
		FO_POINT
		FO_LINEAR
		FO_ANISOTROPIC
	)],
	'FilterType' => [qw(
		FT_MIN
		FT_MAG
		FT_MIP
	)],
	'TextureFilterOptions' => [qw(
		TFO_NONE
		TFO_BILINEAR
		TFO_TRILINEAR
		TFO_ANISOTROPIC
	)],
	'CompareFunction' => [qw(
		CMPF_ALWAYS_FAIL
		CMPF_ALWAYS_PASS
		CMPF_LESS
		CMPF_LESS_EQUAL
		CMPF_EQUAL
		CMPF_NOT_EQUAL
		CMPF_GREATER_EQUAL
		CMPF_GREATER
	)],
	'VertexAnimationType' => [qw(
		VAT_NONE
		VAT_MORPH
		VAT_POSE
	)],
	'VertexElementType' => [qw(
		VET_FLOAT1
		VET_FLOAT2
		VET_FLOAT3
		VET_FLOAT4
		VET_COLOUR
		VET_SHORT1
		VET_SHORT2
		VET_SHORT3
		VET_SHORT4
		VET_UBYTE4
		VET_COLOUR_ARGB
		VET_COLOUR_ABGR
	)],
	'VertexElementSemantic' => [qw(
		VES_POSITION
		VES_BLEND_WEIGHTS
		VES_BLEND_INDICES
		VES_NORMAL
		VES_DIFFUSE
		VES_SPECULAR
		VES_TEXTURE_COORDINATES
		VES_BINORMAL
		VES_TANGENT
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END


1;

__END__


=head1 NAME

Ogre - Perl binding for the OGRE C++ graphics library

=head1 SYNOPSIS

  use Ogre;
  # see examples/README.txt

=head1 DESCRIPTION

For more details, see F<README.txt>.

For documentation on specific classes, see the perldoc for the class.
There is a L<list below|/"CLASSES"> of classes currently wrapped.
The documentation for each class is somewhat minimal. In the DESCRIPTION
section there will be a link to the corresponding C++ API documentation
on the OGRE website. The documentation of methods uses C++ types to describe
its parameters and return values, so some translation to Perl is generally
required.

Not all methods are currently wrapped, although there are enough to run
the examples, which isn't bad. But expect to find that your favorite method
isn't wrapped yet. I'm working on completely wrapping the methods, but it's
still not there. One particular "category" of methods not yet wrapped is those
that return a C++ reference, rather than a pointer (one exception is Node::getPosition).
Methods that return fundamental types, like bool or int, are usually wrapped,
provided their arguments aren't too weird. There are also some overloaded
C++ methods (i.e. different argument parameter types but the same method name)
that have only one version of that method implemented; I have to work on
how to handle that.

See F<TODO.txt> for more things that aren't done yet.

=head1 CLASSES

This is the list of classes that are at least partially wrapped.

=for comment CLASS LIST BEGIN

=over

=item L<Ogre::AnimableObject>

=item L<Ogre::AnimableValue>

=item L<Ogre::Animation>

=item L<Ogre::AnimationControllerFunction>

=item L<Ogre::AnimableObject>

=item L<Ogre::AnimationState>

=item L<Ogre::AnimationStateSet>

=item L<Ogre::AnimationTrack>

=item L<Ogre::AxisAlignedBox>

=item L<Ogre::AxisAlignedBoxSceneQuery>

=item L<Ogre::Billboard>

=item L<Ogre::BillboardChain>

=item L<Ogre::BillboardSet>

=item L<Ogre::Bone>

=item L<Ogre::BorderPanelOverlayElement>

=item L<Ogre::Camera>

=item L<Ogre::ColourValue>

=item L<Ogre::CompositionPass>

=item L<Ogre::CompositionTargetPass>

=item L<Ogre::ConfigFile>

=item L<Ogre::ControllerManager>

=item L<Ogre::ControllerReal>

=item L<Ogre::DataStream>

=item L<Ogre::Degree>

=item L<Ogre::EdgeData>

=item L<Ogre::Entity>

=item L<Ogre::ExampleApplication>

=item L<Ogre::ExampleFrameListener>

=item L<Ogre::Exception>

=item L<Ogre::FrameEvent>

=item L<Ogre::FrameStats>

=item L<Ogre::Frustum>

=item L<Ogre::GpuProgram>

=item L<Ogre::GpuProgramParameters>

=item L<Ogre::HardwareBuffer>

=item L<Ogre::HardwareBufferManager>

=item L<Ogre::HardwareIndexBuffer>

=item L<Ogre::HardwarePixelBuffer>

=item L<Ogre::HardwareVertexBuffer>

=item L<Ogre::Image>

=item L<Ogre::IndexData>

=item L<Ogre::InstancedGeometry>

=item L<Ogre::IntersectionSceneQuery>

=item L<Ogre::KeyFrame>

=item L<Ogre::Light>

=item L<Ogre::Log>

=item L<Ogre::LogManager>

=item L<Ogre::ManualObject>

=item L<Ogre::ManualObjectSection>

=item L<Ogre::ManualResourceLoader>

=item L<Ogre::Material>

=item L<Ogre::MaterialManager>

=item L<Ogre::Math>

=item L<Ogre::Matrix3>

=item L<Ogre::Matrix4>

=item L<Ogre::Mesh>

=item L<Ogre::MeshManager>

=item L<Ogre::MeshPtr>

=item L<Ogre::MovableObject>

=item L<Ogre::MovablePlane>

=item L<Ogre::MultiRenderTarget>

=item L<Ogre::Node>

=item L<Ogre::NodeAnimationTrack>

=item L<Ogre::NumericAnimationTrack>

=item L<Ogre::Overlay>

=item L<Ogre::OverlayContainer>

=item L<Ogre::OverlayElement>

=item L<Ogre::OverlayManager>

=item L<Ogre::PanelOverlayElement>

=item L<Ogre::Particle>

=item L<Ogre::ParticleAffector>

=item L<Ogre::ParticleEmitter>

=item L<Ogre::ParticleSystem>

=item L<Ogre::ParticleSystemRenderer>

=item L<Ogre::Pass>

=item L<Ogre::PassthroughControllerFunction>

=item L<Ogre::PatchMesh>

=item L<Ogre::PatchSurface>

=item L<Ogre::Plane>

=item L<Ogre::PlaneBoundedVolume>

=item L<Ogre::PlaneBoundedVolumeListSceneQuery>

=item L<Ogre::Pose>

=item L<Ogre::Quaternion>

=item L<Ogre::QueuedRenderableCollection>

=item L<Ogre::Radian>

=item L<Ogre::Ray>

=item L<Ogre::RaySceneQuery>

=item L<Ogre::RegionSceneQuery>

=item L<Ogre::Renderable>

=item L<Ogre::RenderOperation>

=item L<Ogre::RenderQueue>

=item L<Ogre::RenderSystem>

=item L<Ogre::RenderSystemCapabilities>

=item L<Ogre::RenderTarget>

=item L<Ogre::RenderTexture>

=item L<Ogre::RenderWindow>

=item L<Ogre::Resource>

=item L<Ogre::ResourceGroupManager>

=item L<Ogre::ResourceManager>

=item L<Ogre::RibbonTrail>

=item L<Ogre::Root>

=item L<Ogre::ScaleControllerFunction>

=item L<Ogre::SceneManager>

=item L<Ogre::SceneNode>

=item L<Ogre::SceneQuery>

=item L<Ogre::ScriptLoader>

=item L<Ogre::Serializer>

=item L<Ogre::ShadowCaster>

=item L<Ogre::SimpleRenderable>

=item L<Ogre::Skeleton>

=item L<Ogre::SkeletonInstance>

=item L<Ogre::SkeletonManager>

=item L<Ogre::Sphere>

=item L<Ogre::SphereSceneQuery>

=item L<Ogre::StaticGeometry>

=item L<Ogre::StringInterface>

=item L<Ogre::SubEntity>

=item L<Ogre::SubMesh>

=item L<Ogre::TagPoint>

=item L<Ogre::Technique>

=item L<Ogre::TextAreaOverlayElement>

=item L<Ogre::Texture>

=item L<Ogre::TextureManager>

=item L<Ogre::TextureUnitState>

=item L<Ogre::TimeIndex>

=item L<Ogre::Timer>

=item L<Ogre::TransformKeyFrame>

=item L<Ogre::Vector2>

=item L<Ogre::Vector3>

=item L<Ogre::Vector4>

=item L<Ogre::VertexAnimationTrack>

=item L<Ogre::VertexBufferBinding>

=item L<Ogre::VertexCacheProfiler>

=item L<Ogre::VertexData>

=item L<Ogre::VertexDeclaration>

=item L<Ogre::VertexElement>

=item L<Ogre::Viewport>

=item L<Ogre::WaveformControllerFunction>

=item L<Ogre::WindowEventUtilities>

=item L<Ogre::WorldFragment>

=back

=for comment CLASS LIST END

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing info, see F<README.txt>.

=cut
