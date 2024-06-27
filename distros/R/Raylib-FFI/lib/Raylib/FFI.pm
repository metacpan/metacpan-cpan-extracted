use 5.40.0;
use experimental 'try';

package Raylib::FFI;

our $VERSION = '0.01';

use FFI::CheckLib      qw( find_lib_or_die );
use FFI::Platypus 2.08 ();
use FFI::C::StructDef  ();
use builtin 'export_lexically';

my $ffi = FFI::Platypus->new(
    api => 2,
    lib => find_lib_or_die( lib => 'raylib', alien => 'Alien::raylib' ),
);

package Raylib::FFI::Vector2D {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        float => 'x',
        float => 'y',
    );
}
$ffi->type( 'record(Raylib::FFI::Vector2D)' => 'Vector2D' );

package Raylib::FFI::Vector3D {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        float => 'x',
        float => 'y',
        float => 'z',
    );
}
$ffi->type( 'record(Raylib::FFI::Vector3D)' => 'Vector3D' );

package Raylib::FFI::Vector4D {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        float => 'x',
        float => 'y',
        float => 'z',
        float => 'w',
    );
}
$ffi->type( 'record(Raylib::FFI::Vector4D)' => 'Vector4D' );
$ffi->type( 'record(Raylib::FFI::Vector4D)' => 'Qaternion' );

package Raylib::FFI::Matrix {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,

        # laid out in column order to mirror raylib
        qw(
          float m0  float m4  float m8   float m12
          float m1  float m5  float m9   float m13
          float m2  float m6  float m10  float m14
          float m3  float m7  float m11  float m15
        )
    );
}
$ffi->type( 'record(Raylib::FFI::Matrix)' => 'Matrix' );

package Raylib::FFI::Color {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        char => 'r',    # red
        char => 'g',    # green
        char => 'b',    # blue
        char => 'a',    # alpha
    );
}
$ffi->type( 'record(Raylib::FFI::Color)' => 'Color' );

package Raylib::FFI::Rectangle {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        float => 'x',
        float => 'y',
        float => 'width',
        float => 'height',
    );
};
$ffi->type( 'record(Raylib::FFI::Rectangle)' => 'Rectangle' );

package Raylib::FFI::Image {
    use FFI::Platypus::Record qw( record_layout_1 );
    $ffi->load_custom_type( '::PointerSizeBuffer' => 'buffer' );
    record_layout_1(
        $ffi,
        opaque => 'data',       # raw image data
        int    => 'width',
        int    => 'height',
        int    => 'mipmaps',    # number of mipmap levels, 1 by default
        int    => 'format',     # data format (PixelFormat type)
    );
}
$ffi->type( 'record(Raylib::FFI::Image)' => 'Image' );

package Raylib::FFI::Texture {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        uint => 'id',           # OpenGL texture id
        int  => 'width',
        int  => 'height',
        int  => 'mipmaps',      # number of mipmap levels, 1 by default
        int  => 'format',       # data format (PixelFormat type)
    );
}

$ffi->type( 'record(Raylib::FFI::Texture)' => 'Texture' );
$ffi->type( 'Texture'                      => 'Texture2D' );
$ffi->type( 'Texture'                      => 'TextureCubemap' );

package Raylib::FFI::RenderTexture {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        uint   => 'id',
        opaque => 'texture',    # cast to Texture
        opaque => 'depth',      # cast to Texture
    );
}
$ffi->type( 'record(Raylib::FFI::RenderTexture)' => 'RenderTexture' );
$ffi->type( 'RenderTexture'                      => 'RenderTexture2D' );

package Raylib::FFI::NPatchInfo {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'sourceRec',    # cast to Rectangle
        int    => 'left',
        int    => 'top',
        int    => 'right',
        int    => 'bottom',
        int    => 'layout'        # layout of the n-patch: 3x3, 1x3 or 3x1
    );
}
$ffi->type( 'record(Raylib::FFI::NPatchInfo)' => 'NPatchInfo' );

package Raylib::FFI::GlyphInfo {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        int    => 'value',
        int    => 'offsetX',
        int    => 'offsetY',
        int    => 'advanceX',
        opaque => 'image'       # cast to Image
    );
}
$ffi->type( 'record(Raylib::FFI::GlyphInfo)' => 'GlyphInfo' );

package Raylib::FFI::Font {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        uint   => 'baseSize',
        uint   => 'glyphCount',
        uint   => 'glyphPadding',
        opaque => 'texture',        # cast to Texture2D
        opaque => 'recs',           # array of rectangles
        opaque => 'glyphs',         # array of GlyphInfo
    );
}
$ffi->type( 'record(Raylib::FFI::Font)' => 'Font' );

package Raylib::FFI::Camera3D {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'position',       # Vector3
        opaque => 'target',         # Vector3
        opaque => 'up',             # Vector3
        float  => 'fovy',
        int    => 'projection',
    );
}

$ffi->type( 'record(Raylib::FFI::Camera3D)' => 'Camera3D' );
$ffi->type( 'Camera3D'                      => 'Camera' );

package Raylib::FFI::Camera2D {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'offset',    # Vector2
        opaque => 'target',    # Vector2
        float  => 'rotation',  # rotation in degrees
        float  => 'zoom',      # zoom level (scaling), should be 1.0f by default
    );
}
$ffi->type( 'record(Raylib::FFI::Camera2D)' => 'Camera2D' );

package Raylib::FFI::Mesh {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        uint => 'vertexCount',     # number of vertices stored in arrays
        uint => 'triangleCount',   # number of triangles stored (indexed or not)

        # vertex data
        opaque => 'vertices',      # array of Vector3
        opaque => 'texcoords',     # array of Vector2
        opaque => 'texcoords2',    # array of Vector2
        opaque => 'normals',       # array of Vector3
        opaque => 'tangents',      # array of Vector4
        opaque => 'colors',        # array of Color
        opaque => 'indices',       # array of uint16

        # animated vertex data
        opaque => 'animVertices',    # array of Vector3
        opaque => 'animNormals',     # array of Vector3
        opaque => 'boneIds',         # array of uint16
        opaque => 'boneWeights',     # array of Vector4

        # openGL ids
        uint     => 'vaoId',         # cast to rVAO
        'uint[]' => 'vboId',         # cast to rVBO
    );
}
$ffi->type( 'record(Raylib::FFI::Mesh)' => 'Mesh' );

package Raylib::FFI::Shader {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        uint    => 'id',
        'int[]' => 'locs',
    );
}
$ffi->type( 'record(Raylib::FFI::Shader)' => 'Shader' );

package Raylib::FFI::MaterialMap {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'texture',    # cast to Texture2D
        opaque => 'color',      # cast to Color
        float  => 'value',
    );
}
$ffi->type( 'record(Raylib::FFI::MaterialMap)' => 'MaterialMap' );

package Raylib::FFI::Material {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'shader',     # cast to Shader
        opaque => 'maps',       # array of MaterialMap
        float  => 'params',
    );
}
$ffi->type( 'record(Raylib::FFI::Material)' => 'Material' );

package Raylib::FFI::Transform {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'translation',    # cast to Vector3
        opaque => 'rotation',       # cast to Quaternion
        opaque => 'scale',          # cast to Vector3
    );
}
$ffi->type( 'record(Raylib::FFI::Transform)' => 'Transform' );

package Raylib::FFI::BoneInfo {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        string => 'name',
        int    => 'parent',
    );
}
$ffi->type( 'record(Raylib::FFI::BoneInfo)' => 'BoneInfo' );

package Raylib::FFI::Model {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'transform',       # cast to Matrix
        int    => 'meshCount',
        int    => 'materialCount',
        opaque => 'meshes',          # array of Mesh
        opaque => 'materials',       # array of Material
        int    => 'meshMaterial',
        int    => 'boneCount',
        opaque => 'bones',           # cast to BoneInfo
        opaque => 'bindPose',        # cast to Transform
    );
}
$ffi->type( 'record(Raylib::FFI::Model)' => 'Model' );

package Raylib::FFI::ModelAnimation {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        int    => 'boneCount',       # number of bones
        int    => 'frameCount',      # number of animation frames
        opaque => 'bones',           # cast to BoneInfo
        opaque => 'framePoses',      # poses array by frame
        string => 'name',
    );
}
$ffi->type( 'record(Raylib::FFI::ModelAnimation)' => 'ModelAnimation' );

package Raylib::FFI::Ray {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'position',        # cast to Vector3
        opaque => 'direction',       # cast to Vector3
    );
}
$ffi->type( 'record(Raylib::FFI::Ray)' => 'Ray' );

package Raylib::FFI::RayCollision {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        bool   => 'hit',         # did the ray hit something?
        float  => 'distance',    # distance to nearest hit
        opaque => 'point',       # cast to Vector3 - Point of the nearest hit
        opaque => 'normal',      # cast to Vector3 - Surface normal of the hit
    );
}
$ffi->type( 'record(Raylib::FFI::RayCollision)' => 'RayCollision' );

package Raylib::FFI::BoundingBox {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'min',         # cast to Vector3
        opaque => 'max',         # cast to Vector3
    );
}
$ffi->type( 'record(Raylib::FFI::BoundingBox)' => 'BoundingBox' );

package Raylib::FFI::Wave {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        uint   => 'frameCount',    # Number of frames (considering channels)
        uint   => 'sampleRate',    # Frequency (samples per second)
        uint   => 'sampleSize',    # 8, 16, 32 (24 not supported)
        uint   => 'channels',      # 1 = mono, 2 = stereo
        opaque => 'data',
    );
}
$ffi->type( 'record(Raylib::FFI::Wave)' => 'Wave' );

# NOTE: Actual structs are defined internally in raudio module
$ffi->type( 'opaque' => 'rAudioBuffer' );
$ffi->type( 'opaque' => 'rAudioProcessor' );

package Raylib::FFI::AudioStream {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'buffer',        # cast to rAudioBuffer
        opaque => 'processor',     # cast to rAudioProcessor
        uint   => 'sampleRate',    # Frequency (samples per second)
        uint   => 'sampleSize',    # 8, 16, 32 (24 not supported)
        uint   => 'channels',      # 1 = mono, 2 = stereo
    );
}
$ffi->type( 'record(Raylib::FFI::AudioStream)' => 'AudioStream' );

package Raylib::FFI::Sound {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'stream',      # cast to AudioStream
        uint   => 'frameCount',  # Total number of frames (considering channels)
    );
}
$ffi->type( 'record(Raylib::FFI::Sound)' => 'Sound' );

package Raylib::FFI::Music {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'stream',      # cast to AudioStream
        uint   => 'frameCount',  # Total number of frames (considering channels)
        bool   => 'looping',     # Music looping enable
        int    => 'ctxType',     # Audio context type
        opaque => 'ctxData',     # Audio context data, depends on type
    );
}
$ffi->type( 'record(Raylib::FFI::Music)' => 'Music' );

package Raylib::FFI::VrDeviceInfo {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        int   => 'hResolution',            # horizontal resolution in pixels
        int   => 'vResolution',            # vertical resolution in pixels
        float => 'hScreenSize',            # horizontal size in meters
        float => 'vScreenSize',            # vertical size in meters
        float => 'vScreenCenter',          # screen center in meters
        float => 'eyeToScreenDistance',    # in meters
        float => 'lensSeparationDistance', # in meters
        float => 'interpupillaryDistance', # distance between pupils in meters
        float => 'lensDistortionValues',   # lens distortion constant parameters
        float =>
          'chromaAbCorrection',    # chromatic aberration correction parameters
    );
}
$ffi->type( 'record(Raylib::FFI::VrDeviceInfo)' => 'VrDeviceInfo' );

package Raylib::FFI::VrStereoConfig {
    use FFI::Platypus::Record qw( record_layout_1 );
    record_layout_1(
        $ffi,
        opaque => 'projection',          # cast to Matrix
        opaque => 'viewOffset',          # cast to Vector3
        float  => 'leftLensCenter',
        float  => 'rightLensCenter',
        float  => 'leftScreenCenter',
        float  => 'rightScreenCenter',
        float  => 'scale',
        float  => 'scaleInverted',
    );
}
$ffi->type( 'record(Raylib::FFI::VrStereoConfig)' => 'VrStereoConfig' );

my %functions = (

    # Window-related functions
    InitWindow               => [ [qw(int int string)] => 'void' ],
    CloseWindow              => [ []                   => 'void' ],
    WindowShouldClose        => [ []                   => 'bool' ],
    IsWindowReady            => [ []                   => 'bool' ],
    IsWindowFullscreen       => [ []                   => 'bool' ],
    IsWindowHidden           => [ []                   => 'bool' ],
    IsWindowMinimized        => [ []                   => 'bool' ],
    IsWindowMaximized        => [ []                   => 'bool' ],
    IsWindowFocused          => [ []                   => 'bool' ],
    IsWindowResized          => [ []                   => 'bool' ],
    IsWindowHidden           => [ []                   => 'bool' ],
    IsWindowState            => [ ['int']              => 'bool' ],
    SetWindowState           => [ ['int']              => 'void' ],
    ClearWindowState         => [ ['int']              => 'void' ],
    ToggleFullscreen         => [ []                   => 'void' ],
    ToggleBorderlessWindowed => [ []                   => 'void' ],
    MaximizeWindow           => [ []                   => 'void' ],
    MinimizeWindow           => [ []                   => 'void' ],
    RestoreWindow            => [ []                   => 'void' ],
    SetWindowIcon            => [ ['Image']            => 'void' ],
    SetWindowIcons           => [ ['Image']            => 'void' ],
    SetWindowTitle           => [ ['string']           => 'void' ],
    SetWindowPosition        => [ [qw(int int)]        => 'void' ],
    SetWindowMonitor         => [ ['int']              => 'void' ],
    SetWindowMinSize         => [ [qw(int int)]        => 'void' ],
    SetWindowMaxSize         => [ [qw(int int)]        => 'void' ],
    SetWindowSize            => [ [qw(int int)]        => 'void' ],
    SetWindowOpacity         => [ ['float']            => 'void' ],
    SetWindowFocused         => [ ['int']              => 'void' ],
    GetScreenWidth           => [ []                   => 'int' ],
    GetScreenHeight          => [ []                   => 'int' ],
    GetRenderWidth           => [ []                   => 'int' ],
    GetRenderHeight          => [ []                   => 'int' ],
    GetMonitorCount          => [ []                   => 'int' ],
    GetCurrentMonitor        => [ []                   => 'int' ],
    GetMonitorPosition       => [ ['int']              => 'Vector2D' ],
    GetMonitorWidth          => [ ['int']              => 'int' ],
    GetMonitorHeight         => [ ['int']              => 'int' ],
    GetMonitorPhysicalWidth  => [ ['int']              => 'int' ],
    GetMonitorPhysicalHeight => [ ['int']              => 'int' ],
    GetMonitorRefreshRate    => [ ['int']              => 'int' ],
    GetWindowPosition        => [ []                   => 'Vector2D' ],
    GetWindowScaleDPI        => [ []                   => 'Vector2D' ],
    GetMonitorName           => [ ['int']              => 'string' ],
    SetClipboardText         => [ ['string']           => 'void' ],
    GetClipboardText         => [ []                   => 'string' ],
    EnableEventWaiting       => [ []                   => 'void' ],
    DisableEventWaiting      => [ []                   => 'void' ],

    # Cursor-related functions
    ShowCursor       => [ [] => 'void' ],
    HideCursor       => [ [] => 'void' ],
    IsCursorHidden   => [ [] => 'bool' ],
    EnableCursor     => [ [] => 'void' ],
    DisableCursor    => [ [] => 'void' ],
    IsCursorOnScreen => [ [] => 'bool' ],

    # Drawing-related functions
    ClearBackground => [ ['Color']    => 'void' ],
    BeginDrawing    => [ []           => 'void' ],
    EndDrawing      => [ []           => 'void' ],
    BeginMode2D     => [ ['Camera2D'] => 'void' ],
    EndMode2D       => [ []           => 'void' ],
    BeginMode3D     => [ ['Camera3D'] => 'void' ],
    EndMode3D       => [ []           => 'void' ],

    BeginTextureMode  => [ ['RenderTexture2D']   => 'void' ],
    EndTextureMode    => [ []                    => 'void' ],
    BeginShaderMode   => [ ['Shader']            => 'void' ],
    EndShaderMode     => [ []                    => 'void' ],
    BeginBlendMode    => [ ['int']               => 'void' ],
    EndBlendMode      => [ []                    => 'void' ],
    BeginScissorMode  => [ [qw(int int int int)] => 'void' ],
    EndScissorMode    => [ []                    => 'void' ],
    BeginVrStereoMode => [ ['VrStereoConfig']    => 'void' ],
    EndVrStereoMode   => [ []                    => 'void' ],

    # VR stereo config functions for VR simulator
    LoadVrStereoConfig   => [ ['VrStereoConfig'] => 'void' ],
    UnloadVrStereoConfig => [ ['VrStereoConfig'] => 'void' ],

    # Shader management functions
    LoadShader              => [ [ 'string', 'string' ] => 'Shader' ],
    LoadShaderFromMemory    => [ [ 'string', 'string' ] => 'Shader' ],
    IsShaderReady           => [ ['Shader']             => 'bool' ],
    GetShaderLocation       => [ [ 'Shader', 'string' ] => 'int' ],
    GetShaderLocationAttrib => [ [ 'Shader', 'string' ] => 'int' ],
    SetShaderValue        => [ [ 'Shader', 'int', 'opaque', 'int' ] => 'void' ],
    SetShaderValueV       => [ [ 'Shader', 'int', 'opaque', 'int' ] => 'void' ],
    SetShaderValueMatrix  => [ [ 'Shader', 'int', 'Matrix' ]        => 'void' ],
    SetShaderValueTexture => [ [ 'Shader', 'int', 'Texture2D' ]     => 'void' ],
    UnloadShader          => [ ['Shader']                           => 'void' ],

    # Screen-space-related functions
    GetMouseRay        => [ [ 'Vector2D', 'Camera3D' ]          => 'Ray' ],
    GetWorldToScreenEx => [ [ 'Vector3D', 'Camera3D', 'float' ] => 'Vector2D' ],
    GetScreenToWorld2D => [ [ 'Vector2D', 'Camera2D' ]          => 'Vector2D' ],
    GetCameraMatrix    => [ ['Camera3D']                        => 'Matrix' ],
    GetCameraMatrix2D  => [ ['Camera2D']                        => 'Matrix' ],

    # Timing related functions
    SetTargetFPS => [ ['int'] => 'void' ],
    GetFPS       => [ []      => 'int' ],
    GetFrameTime => [ []      => 'double' ],
    GetTime      => [ []      => 'double' ],

    # Custom frame control functions
    SwapScreenBuffer => [ []         => 'void' ],
    PollInputEvents  => [ []         => 'void' ],
    WaitTime         => [ ['double'] => 'void' ],

    # Misc. functions
    TakeScreenshot   => [ [qw(string)] => 'void' ],
    SetConfigFlags   => [ [qw(int)]    => 'void' ],
    OpenURL          => [ [qw(string)] => 'void' ],
    TraceLog         => [ ['int']      => 'void' ],
    SetTraceLogLevel => [ ['int']      => 'void' ],

    # Input-related functions: keyboard
    IsKeyPressed       => [ ['int'] => 'bool' ],
    IsKeyPressedRepeat => [ ['int'] => 'bool' ],
    IsKeyDown          => [ ['int'] => 'bool' ],
    IsKeyReleased      => [ ['int'] => 'bool' ],
    IsKeyUp            => [ ['int'] => 'bool' ],
    GetKeyPressed      => [ []      => 'int' ],
    GetCharPressed     => [ []      => 'int' ],
    SetExitKey         => [ ['int'] => 'void' ],

    # Input-related functions: gamepads
    IsGamepadAvailable      => [ ['int']          => 'bool' ],
    GetGamepadName          => [ ['int']          => 'string' ],
    IsGamepadButtonPressed  => [ [ 'int', 'int' ] => 'bool' ],
    IsGamepadButtonDown     => [ [ 'int', 'int' ] => 'bool' ],
    IsGamepadButtonReleased => [ [ 'int', 'int' ] => 'bool' ],
    IsGamepadButtonUp       => [ [ 'int', 'int' ] => 'bool' ],
    GetGamepadButtonPressed => [ []               => 'int' ],
    GetGamepadAxisCount     => [ ['int']          => 'int' ],
    GetGamepadAxisMovement  => [ [ 'int', 'int' ] => 'float' ],
    SetGamepadMappings      => [ ['string']       => 'void' ],

    # Input-related functions: mouse
    IsMouseButtonPressed  => [ ['int']           => 'bool' ],
    IsMouseButtonDown     => [ ['int']           => 'bool' ],
    IsMouseButtonReleased => [ ['int']           => 'bool' ],
    IsMouseButtonUp       => [ ['int']           => 'bool' ],
    GetMouseX             => [ []                => 'int' ],
    GetMouseY             => [ []                => 'int' ],
    GetMousePosition      => [ []                => 'Vector2D' ],
    GetMouseDelta         => [ []                => 'Vector2D' ],
    SetMousePosition      => [ [qw(int int)]     => 'void' ],
    SetMouseOffset        => [ [qw(int int)]     => 'void' ],
    SetMouseScale         => [ [qw(float float)] => 'void' ],
    GetMouseWheelMove     => [ []                => 'int' ],
    GetMouseWheelMoveV    => [ []                => 'Vector2D' ],
    SetMouseCursor        => [ [qw(int)]         => 'void' ],

    # Input-related functions: touch
    GetTouchX          => [ []      => 'int' ],
    GetTouchY          => [ []      => 'int' ],
    GetTouchPosition   => [ ['int'] => 'Vector2D' ],
    GetTouchPointId    => [ ['int'] => 'int' ],
    GetTouchPointCount => [ []      => 'int' ],

    # Gestures and Touch Handling Functions
    SetGesturesEnabled     => [ [qw(int)] => 'void' ],
    IsGestureDetected      => [ ['int']   => 'bool' ],
    GetGestureDetected     => [ []        => 'int' ],
    GetGestureHoldDuration => [ []        => 'float' ],
    GetGestureDragVector   => [ []        => 'Vector2D' ],
    GetGestureDragAngle    => [ []        => 'float' ],
    GetGesturePinchVector  => [ []        => 'Vector2D' ],
    GetGesturePinchAngle   => [ []        => 'float' ],

    # Camera System Functions
    UpdateCamera    => [ ['Camera*'] => 'void' ],
    UpdateCameraPro =>
      [ [ 'Camera*', 'Vector3D', 'Vector3D', 'float' ] => 'void' ],

    # Set texture and rectangle to be used on shapes drawing
    SetShapesTexture => [ [ 'Texture2D', 'Rectangle' ] => 'void' ],

    # Basic shapes drawing functions
    DrawPixel             => [ [qw(int int)]                       => 'void' ],
    DrawPixelV            => [ ['Vector2D']                        => 'void' ],
    DrawLine              => [ [qw(int int int int)]               => 'void' ],
    DrawLineV             => [ [ 'Vector2D', 'Vector2D' ]          => 'void' ],
    DrawLineEx            => [ [ 'Vector2D', 'Vector2D', 'float' ] => 'void' ],
    DrawLineStrip         => [ [ 'Vector2D*', 'int' ]              => 'void' ],
    DrawLineBezier        => [ [ 'Vector2D*', 'int' ]              => 'void' ],
    DrawCircle            => [ [qw(int int float)]                 => 'void' ],
    DrawCircleSector      => [ [qw(int int float float)]           => 'void' ],
    DrawCircleSectorLines => [ [qw(int int float float)]           => 'void' ],
    DrawCircleGradient    => [ [qw(int int float)]                 => 'void' ],
    DrawCircleV           => [ [ 'Vector2D', 'float' ]             => 'void' ],
    DrawCircleLines       => [ [qw(int int float)]                 => 'void' ],
    DrawCircleLinesV      => [ [ 'Vector2D', 'float' ]             => 'void' ],
    DrawEllipse           => [ [qw(int int float float)]           => 'void' ],
    DrawEllipseLines      => [ [qw(int int float float)]           => 'void' ],
    DrawRing              => [ [qw(int int float float float)]     => 'void' ],
    DrawRingLines         => [ [qw(int int float float float)]     => 'void' ],
    DrawRectangle         => [ [qw(int int int int)]               => 'void' ],
    DrawRectangleV        => [ [ 'Vector2D', 'Vector2D' ]          => 'void' ],
    DrawRectangleRec      => [ [ 'Rectangle', 'Color' ]            => 'void' ],
    DrawRectanglePro      =>
      [ [ 'Rectangle', 'Vector2D', 'float', 'Color' ] => 'void' ],
    DrawRectangleGradientV  => [ [qw(int int int int)]             => 'void' ],
    DrawRectangleGradientH  => [ [qw(int int int int)]             => 'void' ],
    DrawRectangleGradientEx => [ [ 'Rectangle', 'Color', 'Color' ] => 'void' ],
    DrawRectangleLines      => [ [qw(int int int int)]             => 'void' ],
    DrawRectangleLinesEx    => [ [ 'Rectangle', 'float' ]          => 'void' ],
    DrawRectangleRounded    => [ [ 'Rectangle', 'float', 'int' ]   => 'void' ],
    DrawRectangleRoundedLines => [ [ 'Rectangle', 'float', 'int' ] => 'void' ],

    DrawTriangle      => [ [ 'Vector2D', 'Vector2D', 'Vector2D' ]   => 'void' ],
    DrawTriangleLines => [ [ 'Vector2D', 'Vector2D', 'Vector2D' ]   => 'void' ],
    DrawTriangleFan   => [ [ 'Vector2D*', 'int' ]                   => 'void' ],
    DrawTriangleStrip => [ [ 'Vector2D*', 'int' ]                   => 'void' ],
    DrawPoly          => [ [ 'Vector2D*', 'int', 'float' ]          => 'void' ],
    DrawPolyLines     => [ [ 'Vector2D*', 'int', 'float' ]          => 'void' ],
    DrawPolyLinesEx   => [ [ 'Vector2D*', 'int', 'float', 'float' ] => 'void' ],

    # Splines Drawing Functions
    DrawSplineLinear            => [ [ 'Vector2D*', 'int' ]      => 'void' ],
    DrawSplineBasis             => [ [ 'Vector2D*', 'int' ]      => 'void' ],
    DrawSplineCatmullRom        => [ [ 'Vector2D*', 'int' ]      => 'void' ],
    DrawSplineBezierQuadratic   => [ [ 'Vector2D*', 'int' ]      => 'void' ],
    DrawSplineBezierCubic       => [ [ 'Vector2D*', 'int' ]      => 'void' ],
    DrawSplineSegmentLinear     => [ [ 'Vector2D',  'Vector2D' ] => 'void' ],
    DrawSplineSegmentBasis      => [ [ 'Vector2D',  'Vector2D' ] => 'void' ],
    DrawSplineSegmentCatmullRom => [ [ 'Vector2D',  'Vector2D' ] => 'void' ],
    DrawSplineSegmentBezierQuadratic =>
      [ [ 'Vector2D', 'Vector2D' ] => 'void' ],
    DrawSplineSegmentBezierCubic => [ [ 'Vector2D', 'Vector2D' ] => 'void' ],

    # pline segment point evaluation functions, for a given t [0.0f .. 1.0f]
    GetSplinePointLinear      => [ [ 'Vector2D', 'float' ] => 'Vector2D' ],
    GetSplinePointBasis       => [ [ 'Vector2D', 'float' ] => 'Vector2D' ],
    GetSplinePointCatmullRom  => [ [ 'Vector2D', 'float' ] => 'Vector2D' ],
    GetSplinePointBezierQuad  => [ [ 'Vector2D', 'float' ] => 'Vector2D' ],
    GetSplinePointBezierCubic => [ [ 'Vector2D', 'float' ] => 'Vector2D' ],

    # Basic shapes collision detection functions
    CheckCollisionRecs    => [ [ 'Rectangle', 'Rectangle' ] => 'bool' ],
    CheckCollisionCircles =>
      [ [ 'Vector2D', 'float', 'Vector2D', 'float' ] => 'bool' ],
    CheckCollisionCircleRec =>
      [ [ 'Vector2D', 'float', 'Rectangle' ] => 'bool' ],
    CheckCollisionPointRec    => [ [ 'Vector2D', 'Rectangle' ] => 'bool' ],
    CheckCollisionPointCircle =>
      [ [ 'Vector2D', 'Vector2D', 'float' ] => 'bool' ],
    CheckCollisionPointTriangle =>
      [ [ 'Vector2D', 'Vector2D', 'Vector2D', 'Vector2D' ] => 'bool' ],
    CheckCollisionPointPoly => [ [ 'Vector2D', 'int', 'Vector2D' ] => 'bool' ],
    CheckCollisionLines     =>
      [ [ 'Vector2D', 'Vector2D', 'Vector2D', 'Vector2D' ] => 'bool' ],
    CheckCollisionPointLine =>
      [ [ 'Vector2D', 'Vector2D', 'Vector2D', 'Vector2D' ] => 'bool' ],

    GetCollisionRec => [ [ 'Rectangle', 'Rectangle' ] => 'Rectangle' ],

    # Image loading functions
    LoadImage     => [ ['string']                         => 'Image' ],
    LoadImageRaw  => [ [ 'string', 'int', 'int', 'bool' ] => 'Image' ],
    LoadImageSvg  => [ ['string']                         => 'Image' ],
    LoadImageAnim => [ [ 'string', 'int' ]                => 'Image' ],

    LoadImageFromMemory  => [ [ 'string', 'string' ] => 'Image' ],
    LoadImageFromTexture => [ ['Texture2D']          => 'Image' ],
    LoadImageFromScreen  => [ []                     => 'Image' ],
    IsImageReady         => [ ['Image']              => 'bool' ],
    UnloadImage          => [ ['Image']              => 'void' ],
    ExportImage          => [ [ 'Image', 'string' ]  => 'void' ],

    # Image generation functions
    GenImageColor          => [ [ 'int', 'int', 'Color' ] => 'Image' ],
    GenImageGradientLinear => [ [ 'int', 'int', 'Color', 'Color' ] => 'Image' ],
    GenImageGradientRadial => [ [ 'int', 'int', 'Color', 'Color' ] => 'Image' ],
    GenImageGradientSquare => [ [ 'int', 'int', 'Color', 'Color' ] => 'Image' ],
    GenImageChecked        =>
      [ [ 'int', 'int', 'int', 'int', 'Color', 'Color' ] => 'Image' ],
    GenImageWhiteNoise  => [ [ 'int', 'int', 'float' ]        => 'Image' ],
    GenImagePerlinNoise => [ [ 'int', 'int', 'int', 'float' ] => 'Image' ],
    GenImageCellular    => [ [ 'int', 'int' ]                 => 'Image' ],
    GenImageText        => [ [ 'int', 'string' ]              => 'Image' ],

    # Image manipulation functions
    ImageCopy      => [ ['Image']                             => 'Image' ],
    ImageFromImage => [ [ 'Image', 'Rectangle', 'Rectangle' ] => 'Image' ],
    ImageText      => [ [ 'string', 'int' ]                   => 'Image' ],
    ImageTextEx    =>
      [ [ 'Image', 'string', 'float', 'float', 'Color' ] => 'Image' ],
    ImageFormat           => [ [ 'Image', 'int' ]            => 'void' ],
    ImageToPOT            => [ [ 'Image', 'Color' ]          => 'void' ],
    ImageCrop             => [ [ 'Image', 'Rectangle' ]      => 'void' ],
    ImageAlphaCrop        => [ [ 'Image', 'float' ]          => 'void' ],
    ImageAlphaClear       => [ [ 'Image', 'Color', 'float' ] => 'void' ],
    ImageAlphaMask        => [ [ 'Image', 'Image' ]          => 'void' ],
    ImageAlphaPremultiply => [ ['Image']                     => 'void' ],
    ImageBlurGaussian     => [ [ 'Image', 'float' ]          => 'void' ],

    ImageResize       => [ [ 'Image', 'int', 'int' ] => 'void' ],
    ImageResizeNN     => [ [ 'Image', 'int', 'int' ] => 'void' ],
    ImageResizeCanvas =>
      [ [ 'Image', 'int', 'int', 'int', 'int', 'Color' ] => 'void' ],
    ImageMipmaps         => [ ['Image']                     => 'void' ],
    ImageDither          => [ [ 'Image', 'int' ]            => 'void' ],
    ImageFlipVertical    => [ ['Image']                     => 'void' ],
    ImageFlipHorizontal  => [ ['Image']                     => 'void' ],
    ImageRotate          => [ [ 'Image', 'int' ]            => 'void' ],
    ImageRotateCW        => [ ['Image']                     => 'void' ],
    ImageRotateCCW       => [ ['Image']                     => 'void' ],
    ImageColorTint       => [ [ 'Image', 'Color' ]          => 'void' ],
    ImageColorInvert     => [ ['Image']                     => 'void' ],
    ImageColorGrayscale  => [ ['Image']                     => 'void' ],
    ImageColorContrast   => [ [ 'Image', 'float' ]          => 'void' ],
    ImageColorBrightness => [ [ 'Image', 'int' ]            => 'void' ],
    ImageColorReplace    => [ [ 'Image', 'Color', 'Color' ] => 'void' ],
    LoadImageColors      => [ ['Image']                     => 'Color*' ],
    LoadImagePalette     => [ [ 'Image', 'int' ]            => 'Color*' ],
    UnloadImageColors    => [ ['Color*']                    => 'void' ],
    UnloadImagePalette   => [ ['Color*']                    => 'void' ],
    GetImageAlphaBorder  => [ [ 'Image', 'Rectangle' ]      => 'Rectangle' ],
    GetImageColor        => [ [ 'Image', 'int', 'int' ]     => 'Color' ],

    # Image Drawing Functions (CPU)
    ImageClearBackground => [ [ 'Image', 'Color' ]               => 'void' ],
    ImageDrawPixel       => [ [ 'Image', 'int', 'int', 'Color' ] => 'void' ],
    ImageDrawPixelV      => [ [ 'Image', 'Vector2D', 'Color' ]   => 'void' ],
    ImageDrawLine        =>
      [ [ 'Image', 'int', 'int', 'int', 'int', 'Color' ] => 'void' ],
    ImageDrawLineV =>
      [ [ 'Image', 'Vector2D', 'Vector2D', 'Color' ] => 'void' ],
    ImageDrawCircle  => [ [ 'Image', 'int', 'int', 'int', 'Color' ] => 'void' ],
    ImageDrawCircleV => [ [ 'Image', 'Vector2D', 'int', 'Color' ] => 'void' ],
    ImageDrawCircleLines =>
      [ [ 'Image', 'int', 'int', 'int', 'Color' ] => 'void' ],
    ImageDrawRectangle =>
      [ [ 'Image', 'int', 'int', 'int', 'int', 'Color' ] => 'void' ],
    ImageDrawRectangleV =>
      [ [ 'Image', 'Vector2D', 'Vector2D', 'Color' ] => 'void' ],
    ImageDrawRectangleRec   => [ [ 'Image', 'Rectangle', 'Color' ] => 'void' ],
    ImageDrawRectangleLines =>
      [ [ 'Image', 'Rectangle', 'int', 'Color' ] => 'void' ],
    ImageDraw     => [ [ 'Image', 'Image', 'int', 'int', 'Color' ] => 'void' ],
    ImageDrawText =>
      [ [ 'Image', 'string', 'int', 'int', 'int', 'Color' ] => 'void' ],

    ImageDrawTextEx => [
        [ 'Image', 'Font', 'string', 'Vector2D', 'float', 'float', 'Color' ] =>
          'void'
    ],

    # Texture Loading Functions
    LoadTexture          => [ ['string']         => 'Texture' ],
    LoadTextureFromImage => [ ['Image']          => 'Texture2D' ],
    LoadTextureCubemap   => [ [ 'Image', 'int' ] => 'TextureCubemap' ],

    LoadRenderTexture => [ [ 'int', 'int' ] => 'RenderTexture2D' ],
    IsTextureReady    => [ ['Texture']      => 'bool' ],
    UnloadTexture     => [ ['Texture2D']    => 'void' ],

    IsRenderTextureReady => [ ['RenderTexture2D']                   => 'bool' ],
    UnloadRenderTexture  => [ ['RenderTexture2D']                   => 'void' ],
    UpdateTexture        => [ [ 'Texture2D', 'Image' ]              => 'void' ],
    UpdateTextureRec     => [ [ 'Texture2D', 'Rectangle', 'Image' ] => 'void' ],

    # Texture Configuration Functions
    GenTextureMipmaps => [ ['Texture2D'] => 'void' ],
    SetTextureFilter  => [ [ 'Texture2D', 'int' ] => 'void' ],
    SetTextureWrap    => [ [ 'Texture2D', 'int' ] => 'void' ],

    # texture drawing functions
    DrawTexture   => [ [ 'Texture2D', 'int', 'int', 'Color' ] => 'void' ],
    DrawTextureV  => [ [ 'Texture2D', 'Vector2D', 'Color' ] => 'void' ],
    DrawTextureEx =>
      [ [ 'Texture', 'Vector2D', 'float', 'float', 'Color' ] => 'void' ],
    DrawTextureRec =>
      [ [ 'Texture', 'Rectangle', 'Vector2D', 'Color' ] => 'void' ],
    DrawTexturePro =>
      [ [qw(Texture Rectangle Rectangle Vector2D float Color)] => 'void' ],
    DrawTextureNPatch => [
        [
            'Texture2D', 'NPatchInfo', 'Rectangle', 'Vector2D', 'float',
            'Color'
        ] => 'void'
    ],

    # Color/pixel related functions
    Fade                => [ [ 'Color', 'float' ]               => 'Color' ],
    ColorToInt          => [ ['Color']                          => 'int' ],
    ColorNormalize      => [ ['Color']                          => 'Color' ],
    ColorFromNormalized => [ ['Color']                          => 'Color' ],
    ColorToHSV          => [ ['Color']                          => 'Color' ],
    ColorFromHSV        => [ [ 'float', 'float', 'float' ]      => 'Color' ],
    ColorTint           => [ [ 'Color', 'Color' ]               => 'Color' ],
    ColorBrightness     => [ [ 'Color', 'float' ]               => 'Color' ],
    ColorContrast       => [ [ 'Color', 'float' ]               => 'Color' ],
    ColorAlpha          => [ [ 'Color', 'float' ]               => 'Color' ],
    ColorAlphaBlend     => [ [ 'Color', 'Color', 'Color' ]      => 'Color' ],
    GetColor            => [ ['int']                            => 'Color' ],
    GetPixelColor       => [ [ 'Image', 'int', 'int' ]          => 'Color' ],
    SetPixelColor       => [ [ 'Image', 'int', 'int', 'Color' ] => 'void' ],
    GetPixelDataSize    => [ [ 'int', 'int' ]                   => 'int' ],

    # Font Loading and Text Drawing Functions
    GetFontDefault     => [ []                                      => 'Font' ],
    LoadFont           => [ ['string']                              => 'Font' ],
    LoadFontEx         => [ [ 'string', 'int', 'string' ]           => 'Font' ],
    LoadFontFromImage  => [ [ 'Image', 'float' ]                    => 'Font' ],
    LoadFontFromMemory => [ [ 'string', 'string', 'int', 'string' ] => 'Font' ],
    IsFontReady        => [ ['Font']                                => 'bool' ],
    LoadFontData       =>
      [ [ 'Font', 'string', 'int', 'int', 'float' ] => 'GlyphInfo' ],
    GenImageFontAtlas =>
      [ [ 'GlyphInfo', 'Rectangle', 'int', 'int', 'int', 'int' ] => 'Image' ],
    UnloadFontData => [ ['GlyphInfo'] => 'void' ],
    UnloadFont     => [ ['Font']      => 'void' ],

    # text drawing functions
    DrawFPS    => [ [ 'int',    'int' ] => 'void' ],
    DrawText   => [ [ 'string', 'int', 'int', 'int', 'Color' ] => 'void' ],
    DrawTextEx =>
      [ [ 'Font', 'string', 'Vector2D', 'float', 'float', 'Color' ] => 'void' ],
    DrawTextPro =>
      [ [ 'Font', 'string', 'Vector2D', 'float', 'float', 'Color' ] => 'void' ],
    DrawTextCodepoint  => [ [ 'Font', 'int', 'int', 'Color' ] => 'void' ],
    DrawTextCodepoints =>
      [ [ 'Font', 'string', 'int', 'int', 'int', 'Color' ] => 'void' ],

    # Text font info functions
    SetTextLineSpacing => [ ['float']             => 'void' ],
    MeasureText        => [ [ 'string', 'float' ] => 'int' ],
    MeasureTextEx => [ [ 'Font', 'string', 'float', 'float' ] => 'Vector2D' ],
    GetGlyphIndex => [ [ 'Font', 'int' ]                      => 'int' ],
    GetGlyphInfo  => [ [ 'Font', 'int' ]                      => 'GlyphInfo' ],
    GetGlyphAtlasRec => [ ['GlyphInfo'] => 'Rectangle' ],

    # Text codepoints management functions (utf8 strings)
    LoadCodepoints       => [ ['string']                 => 'int' ],
    UnloadCodepoints     => [ ['int']                    => 'void' ],
    GetCodepointCount    => [ ['string']                 => 'int' ],
    GetCodepoint         => [ [ 'string', 'int' ]        => 'int' ],
    GetCodepointNext     => [ [ 'string', 'int' ]        => 'int' ],
    GetCodepointPrevious => [ [ 'string', 'int' ]        => 'int' ],
    CodepointToUTF8      => [ [ 'int', 'string', 'int' ] => 'int' ],

    # text strigns management functions (not utf8 strings)
    TextToInteger => [ ['string'] => 'int' ],

    # Basic geometric 3D shapes drawing functions
    DrawLine3D   => [ [ 'Vector3D', 'Vector3D', 'Color' ]          => 'void' ],
    DrawPoint3D  => [ [ 'Vector3D', 'Color' ]                      => 'void' ],
    DrawCircle3D => [ [ 'Vector3D', 'float', 'Vector3D', 'Color' ] => 'void' ],
    DrawTriangle3D =>
      [ [ 'Vector3D', 'Vector3D', 'Vector3D', 'Color' ] => 'void' ],
    DrawTriangleStrip3D => [ [ 'Vector3D*', 'int', 'Color' ] => 'void' ],
    DrawCube        => [ [qw(float float float float float float)] => 'void' ],
    DrawCubeV       => [ [ 'Vector3D', 'Vector3D' ]                => 'void' ],
    DrawCubeWires   => [ [qw(float float float float float float)] => 'void' ],
    DrawCubeWiresV  => [ [ 'Vector3D', 'Vector3D' ]                => 'void' ],
    DrawSphere      => [ [qw(float float)]                         => 'void' ],
    DrawSphereEx    => [ [qw(float float float float)]             => 'void' ],
    DrawSphereWires => [ [qw(float float float)]                   => 'void' ],
    DrawCylinder    => [ [qw(float float float float float float)] => 'void' ],
    DrawCylinderEx  => [ [qw(float float float float float float)] => 'void' ],
    DrawCylinderWires =>
      [ [qw(float float float float float float)] => 'void' ],
    DrawCapsule      => [ [qw(float float float float)] => 'void' ],
    DrawCapsuleWires => [ [qw(float float float float)] => 'void' ],
    DrawPlane        => [ [qw(float float float float)] => 'void' ],
    DrawRay          => [ ['Ray']                       => 'void' ],
    DrawGrid         => [ [qw(int int)]                 => 'void' ],

    # model management functions
    LoadModel           => [ ['string'] => 'Model' ],
    LoadModelFromMesh   => [ ['Mesh']   => 'Model' ],
    IsModelReady        => [ ['Model']  => 'bool' ],
    UnloadModel         => [ ['Model']  => 'void' ],
    GetModelBoundingBox => [ ['Model']  => 'BoundingBox' ],

    # model drawing functions
    DrawModel   => [ [ 'Model', 'Vector3D', 'float' ] => 'void' ],
    DrawModelEx =>
      [ [ 'Model', 'Vector3D', 'Vector3D', 'float', 'Color' ] => 'void' ],
    DrawModelWires   => [ [ 'Model', 'Vector3D', 'float' ] => 'void' ],
    DrawModelWiresEx =>
      [ [ 'Model', 'Vector3D', 'Vector3D', 'float', 'Color' ] => 'void' ],
    DrawBoundingBox => [ [ 'BoundingBox', 'Color' ] => 'void' ],
    DrawBillboard   =>
      [ [ 'Camera', 'Texture2D', 'Vector3D', 'float', 'Color' ] => 'void' ],
    DrawBillboardRec => [
        [ 'Camera', 'Texture2D', 'Rectangle', 'Vector3D', 'float', 'Color' ] =>
          'void'
    ],
    DrawBillboardPro => [
        [
            'Camera',   'Texture2D', 'Rectangle', 'Vector3D',
            'Vector2D', 'float',     'Color'
        ] => 'void'
    ],

    # mesh management functions
    UploadMesh         => [ [ 'Mesh', 'bool' ]   => 'void' ],
    UnloadMesh         => [ ['Mesh']             => 'void' ],
    DrawMesh           => [ ['Mesh']             => 'void' ],
    GetMeshBoundingBox => [ ['Mesh']             => 'BoundingBox' ],
    GenMeshTangents    => [ ['Mesh']             => 'void' ],
    ExportMesh         => [ [ 'Mesh', 'string' ] => 'bool' ],

    # Mesh generation functions
    GenMeshPoly       => [ [qw(int int)]               => 'Mesh' ],
    GenMeshPlane      => [ [qw(float float int int)]   => 'Mesh' ],
    GenMeshCube       => [ [qw(float float float)]     => 'Mesh' ],
    GenMeshSphere     => [ [qw(float int)]             => 'Mesh' ],
    GenMeshHemiSphere => [ [qw(float int)]             => 'Mesh' ],
    GenMeshCylinder   => [ [qw(float float int)]       => 'Mesh' ],
    GenMeshCone       => [ [qw(float float int)]       => 'Mesh' ],
    GenMeshTorus      => [ [qw(float float int int)]   => 'Mesh' ],
    GenMeshKnot       => [ [qw(float float int int)]   => 'Mesh' ],
    GenMeshHeightmap  => [ [qw(Texture2D BoundingBox)] => 'Mesh' ],
    GenMeshCubicmap   => [ [qw(Texture2D BoundingBox)] => 'Mesh' ],

    # Material loading/unloading
    LoadMaterials       => [ [ 'string', 'int' ]                => 'Material' ],
    LoadMaterialDefault => [ []                                 => 'Material' ],
    IsMaterialReady     => [ ['Material']                       => 'bool' ],
    UnloadMaterial      => [ ['Material']                       => 'void' ],
    SetMaterialTexture  => [ [ 'Material', 'int', 'Texture2D' ] => 'void' ],
    SetModelMeshMaterial => [ [ 'Model', 'int', 'Material' ] => 'void' ],

    # model animations loading/unloading
    LoadModelAnimations   => [ [ 'string', 'int' ] => 'ModelAnimation' ],
    UpdateModelAnimation  => [ [ 'Model', 'ModelAnimation', 'int' ] => 'void' ],
    UnloadModelAnimation  => [ ['ModelAnimation']                   => 'void' ],
    UnloadModelAnimations => [ [ 'ModelAnimation', 'int' ]          => 'void' ],
    IsModelAnimationValid => [ [ 'Model', 'ModelAnimation' ]        => 'bool' ],

    # collision detection functions
    CheckCollisionSpheres =>
      [ [ 'Vector3D', 'Vector3D', 'float', 'Vector3D', 'float' ] => 'bool' ],
    CheckCollisionBoxes     => [ [ 'BoundingBox', 'BoundingBox' ] => 'bool' ],
    CheckCollisionBoxSphere =>
      [ [ 'BoundingBox', 'Vector3D', 'float' ] => 'bool' ],
    GetRayCollisionSphere =>
      [ [ 'Ray', 'Vector3D', 'float' ] => 'RayCollision' ],
    GetRayCollisionBox      => [ [ 'Ray', 'BoundingBox' ] => 'RayCollision' ],
    GetRayCollisionMesh     => [ [ 'Ray', 'Mesh' ]        => 'RayCollision' ],
    GetRayCollisionTriangle =>
      [ [ 'Ray', 'Vector3D', 'Vector3D', 'Vector3D' ] => 'RayCollision' ],
    GetRayCollisionQuad => [
        [ 'Ray', 'Vector3D', 'Vector3D', 'Vector3D', 'Vector3D' ] =>
          'RayCollision'
    ],

    # audio device management
    InitAudioDevice    => [ []        => 'void' ],
    CloseAudioDevice   => [ []        => 'void' ],
    IsAudioDeviceReady => [ []        => 'bool' ],
    SetMasterVolume    => [ ['float'] => 'void' ],
    GetMasterVolume    => [ []        => 'float' ],

    # wave/sound loading/unloading
    LoadWave           => [ ['string']                 => 'Wave' ],
    LoadWaveFromMemory => [ [ 'string', 'int', 'int' ] => 'Wave' ],
    IsWaveReady        => [ ['Wave']                   => 'bool' ],

    LoadSound         => [ ['string']           => 'Sound' ],
    LoadSoundFromWave => [ ['Wave']             => 'Sound' ],
    LoadSoundAlias    => [ ['Sound']            => 'Sound' ],
    IsSoundReady      => [ ['Sound']            => 'bool' ],
    UpdateSound       => [ [ 'Sound', 'float' ] => 'void' ],
    UnloadWave        => [ ['Wave']             => 'void' ],
    UnloadSound       => [ ['Sound']            => 'void' ],
    ExportWave        => [ [ 'Wave', 'string' ] => 'bool' ],

    # wave/sound managemnt functions
    PlaySound         => [ ['Sound']                       => 'void' ],
    StopSound         => [ ['Sound']                       => 'void' ],
    PauseSound        => [ ['Sound']                       => 'void' ],
    ResumeSound       => [ ['Sound']                       => 'void' ],
    IsSoundPlaying    => [ ['Sound']                       => 'bool' ],
    SetSoundVolume    => [ [ 'Sound', 'float' ]            => 'void' ],
    SetSoundPitch     => [ [ 'Sound', 'float' ]            => 'void' ],
    SetSoundPan       => [ [ 'Sound', 'float' ]            => 'void' ],
    WaveCopy          => [ ['Wave']                        => 'Wave' ],
    WaveCrop          => [ [ 'Wave', 'float', 'float' ]    => 'void' ],
    WaveFormat        => [ [ 'Wave', 'int', 'int', 'int' ] => 'void' ],
    LoadWaveSamples   => [ ['Wave']                        => 'float*' ],
    UnloadWaveSamples => [ ['float*']                      => 'void' ],

    # Music management functions
    LoadMusicStream           => [ ['string']                 => 'Music' ],
    LoadMusicStreamFromMemory => [ [ 'string', 'int', 'int' ] => 'Music' ],
    IsMusicReady              => [ ['Music']                  => 'bool' ],
    UnloadMusicStream         => [ ['Music']                  => 'void' ],
    PlayMusicStream           => [ ['Music']                  => 'void' ],
    IsMusicStreamPlaying      => [ ['Music']                  => 'bool' ],
    UpdateMusicStream         => [ ['Music']                  => 'void' ],
    StopMusicStream           => [ ['Music']                  => 'void' ],
    PauseMusicStream          => [ ['Music']                  => 'void' ],
    ResumeMusicStream         => [ ['Music']                  => 'void' ],
    SeekMusicStream           => [ [ 'Music', 'float' ]       => 'void' ],
    SetMusicVolume            => [ [ 'Music', 'float' ]       => 'void' ],
    SetMusicPitch             => [ [ 'Music', 'float' ]       => 'void' ],
    SetMusicPan               => [ [ 'Music', 'float' ]       => 'void' ],
    GetMusicTimeLength        => [ ['Music']                  => 'float' ],
    GetMusicTimePlayed        => [ ['Music']                  => 'float' ],

    # AudioStream management functions
    LoadAudioStream        => [ [ 'int', 'int', 'int' ] => 'AudioStream' ],
    IsAudioStreamReady     => [ ['AudioStream']         => 'bool' ],
    UnloadAudioStream      => [ ['AudioStream']         => 'void' ],
    UpdateAudioStream      => [ [ 'AudioStream', 'float', 'float' ] => 'void' ],
    IsAudioStreamProcessed => [ ['AudioStream']                     => 'bool' ],
    PlayAudioStream        => [ ['AudioStream']                     => 'void' ],
    PauseAudioStream       => [ ['AudioStream']                     => 'void' ],
    ResumeAudioStream      => [ ['AudioStream']                     => 'void' ],
    IsAudioStreamPlaying   => [ ['AudioStream']                     => 'bool' ],
    StopAudioStream        => [ ['AudioStream']                     => 'void' ],
    SetAudioStreamVolume   => [ [ 'AudioStream', 'float' ]          => 'void' ],
    SetAudioStreamPitch    => [ [ 'AudioStream', 'float' ]          => 'void' ],
    SetAudioStreamPan      => [ [ 'AudioStream', 'float' ]          => 'void' ],
    SetAudioStreamBufferSizeDefault => [ ['int'] => 'void' ],
);

for my $func ( keys %functions ) {
    try {
        $ffi->attach( $func => $functions{$func}->@* );
    }
    catch ($e) {
        warn $e;
    }
}

# export all the functions lexically
sub import( $class, @list ) {
    @list = keys %functions unless @list;
    export_lexically map { $_ => __PACKAGE__->can($_) }
      grep { __PACKAGE__->can($_) } @list;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Raylib::FFI - Perl FFI bindings for raylib

=head1 SYNOPSIS

    use 5.38.2;
    use lib qw(lib);
    use Raylib::FFI; # defaults to exporting all the functions
    use constant Color => 'Raylib::FFI::Color';

    InitWindow( 800, 600, "Testing!" );
    SetTargetFPS(60);
    while ( !WindowShouldClose() ) {
        my $x = GetScreenWidth() / 2;
        my $y = GetScreenHeight() / 2;
        BeginDrawing();
        ClearBackground( Color->new( r => 0, g => 0, b => 0, a => 0 ) );
        DrawFPS( 0, 0 );
        DrawText( "Hello, world!",
            $x, $y, 20, Color->new( r => 255, g => 255, b => 255, a => 255 ) );
        EndDrawing();
    }
    CloseWindow();

=head1 DESCRIPTION

This module provides Perl bindings for the raylib library using FFI::Platyus.
This is functional but very low level. You probably want to use L<Raylib::App>
instead.

This module was based on the Raylib 5.0.0 API. See L<http://www.raylib.com>.

=head1 TYPES

=head2 Raylib::FFI::Vector2D

X and Y coordinates

=head2 Raylib::FFI::Vector3D

X, Y and Z coordinates

=head2 Raylib::FFI::Vector4D

X, Y, Z and W coordinates

=head2 Raylib::FFI::Matrix

Matrix, 4x4 components, column major, OpenGL style, right-handed

=head2 Raylib::FFI::Color

Color, 4 components, R8G8B8A8 (32bit)

=head2 Raylib::FFI::Rectangle

Rectangle, 4 components

=head2 Raylib::FFI::Image

Image, pixel data stored in CPU memory (RAM)

=head2 Raylib::FFI::Texture

Texture, tex data stored in GPU memory (VRAM)

=head2 Raylib::FFI::RenderTexture

RenderTexture, fbo for texture rendering

=head2 Raylib::FFI::NPatchInfo

NPatchInfo, n-patch layout info

=head2 Raylib::FFI::GlyphInfo

GlyphInfo, font characters glyphs info

=head2 Raylib::FFI::Font

Font, font texture and characters glyphs info

=head2 Raylib::FFI::Camera3D

Camera3D, defines a camera position/orientation in 3D space

=head2 Raylib::FFI::Camera2D

Camera2D, defines a camera position and rotation in 2D space

=head2 Raylib::FFI::Mesh

Mesh, vertext data and vao/vbo

=head2 Raylib::FFI::Shader

Shader

=head2 Raylib::FFI::MaterialMap

MaterialMap

=head2 Raylib::FFI::Material

Material, includes shader and maps

=head2 Raylib::FFI::Transform

Transform, vertex transformation data

=head2 Raylib::FFI::BoneInfo

Bone, skeletal animation bone

=head2 Raylib::FFI::Model

Model, meshes, materials and animation data

=head2 Raylib::FFI::ModelAnimation

ModelAnimation, animation data

=head2 Raylib::FFI::Ray

Ray, ray for raycasting

=head2 Raylib::FFI::RayCollision

RayCollision, ray hit information

=head2 Raylib::FFI::BoundingBox

Bounding Box

=head2 Raylib::FFI::Wave

Wave, audio wave data

=head2 Raylib::FFI::AudioStream

AudioStream, custom audio stream

=head2 Raylib::FFI::Sound

Sound

=head2 Raylib::FFI::Music

Music, audio stream, anything longer than ~10 seconds should be streamed

=head2 Raylib::FFI::VrDeviceInfo

VrDeviceInfo, Head-Mounted-Display device parameters

=head2 Raylib::FFI::VrStereoConfig

VrStereoConfig, VR stereo rendering configuration for simulator

=head1 FUNCTIONS

All functions are exported lexically by default. To export only specific
functions simply liste them in the use statement.

=head2 InitWindow( $width, $height, $title )

Initialize window and OpenGL context.

=head2 CloseWindow()

Close window and unload OpenGL context.

=head2 WindowShouldClose() : bool

Check if application should close (KEY_ESCAPE pressed or windows close icon clicked).

=head2 IsWindowReady() : bool

Check if window has been initialized successfully.

=head2 IsWindowFullscreen() : bool

Check if window is currently fullscreen.

=head2 IsWindowHidden() : bool

Check if window is currently hidden.

=head2 IsWindowMinimized() : bool

Check if window is currently minimized.

=head2 IsWindowMaximized() : bool

Check if window is currently maximized.

=head2 IsWindowFocused() : bool

Check if window is currently focused.

=head2 IsWindowResized() : bool

Check if window has been resized last frame.

=head2 IsWindowState( $flag ) : bool

Check if one specific window flag is enabled.

=head2 SetWindowState( $flags )

Set window configuration state using flags.

=head2 ClearWindowState( $flags )

Clear window configuration state flags.

=head2 ToggleFullscreen()

Toggle window state: fullscreen/windowed (only PLATFORM_DESKTOP).

=head2 ToggleBorderlessWindowed()

Toggle window state: borderless/fullscreen (only PLATFORM_DESKTOP).

=head2 MaximizeWindow()

Set window state: maximized, if resizable (only PLATFORM_DESKTOP).

=head2 MinimizeWindow()

Set window state: minimized, if resizable (only PLATFORM_DESKTOP).

=head2 RestoreWindow()

Restore window state: if resizable (only PLATFORM_DESKTOP).

=head2 SetWindowIcon( $image )

Set icon for window (single image, RBGA 32bit, only PLATFORM_DESKTOP).

=head2 SetWindowIcons( $images )

Set icons for window (multiple images, RGBA 32bit, only PLATFORM_DESKTOP).

=head2 SetWindowTitle( $title )

Set title for window (only PLATFORM_DESKTOP).

=head2 SetWindowPosition( $x, $y )

Set window position on screen (only PLATFORM_DESKTOP).

=head2 SetWindowMonitor( $monitor )

Set monitor for the current window.

=head2 SetWindowMinSize( $width, $height )

Set window minimum dimensions (for FLAG_WINDOW_RESIZABLE).

=head2 SetWindowMaxSize( $width, $height )

Set window maximum dimensions (for FLAG_WINDOW_RESIZABLE).

=head2 SetWindowSize( $width, $height )

Set window dimensions.

=head2 SetWindowOpacity( $opacity )

Set window opacity [0.0f..1.0f]

=head2 GetScreenWidth() : int

Get current screen width.

=head2 GetScreenHeight() : int

Get current screen height.

=head2 GetRenderWidth() : int

Get current render width (it considers HiDPI).

=head2 GetRenderHeight() : int

Get current render height (it considers HiDPI).

=head2 GetMonitorCount() : int

Get number of connected monitors.

=head2 GetCurrentMonitor() : int

Get current connected monitor.

=head2 GetMonitorPosition( $monitor ) : Raylib::FFI::Vector2D

Get specified monitor position in screen space.

=head2 GetMonitorWidth( $monitor ) : int

Get specified monitor width (current video mode used by monitor).

=head2 GetMonitorHeight( $monitor ) : int

Get specified monitor height (current video mode used by monitor).

=head2 GetMonitorPhysicalWidth( $monitor ) : int

Get specified monitor physical width in millimetres.

=head2 GetMonitorPhysicalHeight( $monitor ) : int

Get specified monitor physical height in millimetres.

=head2 GetMonitorRefreshRate( $monitor ) : int

Get specified monitor refresh rate.

=head2 GetWindowPosition() : Raylib::FFI::Vector2D

Get window position XY on monitor.

=head2 GetWindowScaleDPI() : Raylib::FFI::Vector2D

Get window scale factor on HiDPI monitors.

=head2 GetMonitorName( $monitor ) : string

Get the human-readable, UTF-8 encoded name of the monitor.

=head2 SetClipboardText( $text )

Set clipboard text content.

=head2 GetClipboardText() : string

Get clipboard text content.

=head2 EnableEventWaiting()

Enable waiting for events on EndDrawing, automatic event polling.

=head2 DisableEventWaiting()

Disable waiting for events on EndDrawing, manual event polling.

=head2 ShowCursor()

Show cursor.

=head2 HideCursor()

Hide cursor.

=head2 IsCursorHidden() : bool

Check if cursor is not visible.

=head2 EnableCursor()

Enable cursor (unlock cursor).

=head2 DisableCursor()

Disable cursor (lock cursor).

=head2 IsCursorOnScreen() : bool

Check if cursor is on the screen.

=head2 ClearBackground( $color )

Set background color (framebuffer clear color).

=head2 BeginDrawing()

Setup canvas (framebuffer) to start drawing

=head2 EndDrawing()

End canvas drawing and swap buffers (double buffering).

=head2 BeginMode2D( $camera )

Begin 2D mode with custom camera (2D).

=head2 EndMode2D()

Ends 2D mode with custom camera.

=head2 BeginMode3D( $camera )

Begin 3D mode with custom camera (3D).

=head2 EndMode3D()

Ends 3D mode and returns to default 2D orthographic mode.

=head2 BeginTextureMode( $renderTexture )

Begin drawing to render texture.

=head2 EndTextureMode()

Ends drawing to render texture.

=head2 BeginShaderMode( $shader )

Begin custom shader drawing.

=head2 EndShaderMode()

End custom shader drawing (use default shader).

=head2 BeginBlendMode( $mode )

Begin blending mode (alpha, additive, multiplied, subtract, custom)

=head2 EndBlendMode()

End blending mode (reset to default: alpha blending)

=head2 BeginScissorMode( $x, $y, $width, $height )

Begin scissor mode (define screen area for following drawing operations)

=head2 EndScissorMode()

End scissor mode.

=head2 BeginVrStereoMode( $config )

Begin stereo rendering (requires VR simulator)

=head2 EndVrStereoMode()

End stereo rendering.

=head2 LoadVrStereoConfig( $config )

Load VR stereo config for VR simulator.

=head2 UnloadVrStereoConfig( $config )

Unload VR stereo config for VR simulator.

=head2 LoadShader( $vsFileName, $fsFileName ) : Raylib::FFI::Shader

Load shader from files and bind default locations.

=head2 LoadShaderFromMemory( $vsCode, $fsCode ) : Raylib::FFI::Shader

Load shader from code strings and bind default locations.

=head2 IsShaderReady( $shader ) : bool

Check if a shader is ready.

=head2 GetShaderLocation( $shader, $uniformName ) : int

Get shader uniform location.

=head2 GetShaderLocationAttrib( $shader, $attribName ) : int

Get shader attribute location.

=head2 SetShaderValue( $shader, $locIndex, $value, $uniformType )

Set shader uniform value

=head2 SetShaderValueV( $shader, $locIndex, $value, $uniformType )

Set shader uniform value vector

=head2 SetShaderValueMatrix( $shader, $locIndex, $matrix )

Set shader uniform value matrix (matrix 4x4)

=head2 SetShaderValueTexture( $shader, $locIndex, $texture )

Set shader uniform value for texture (sampler2d)

=head2 UnloadShader( $shader )

Unload shader from GPU memory (VRAM).

=head2 GetMouseRay( $position, $camera ) : Raylib::FFI::Ray # DEPRECATED

Get a ray trace from screen space (i.e. mouse position)

=head2 GetWorldToScreenEx( $position, $camera, $width, $height ) : Raylib::FFI::Vector2D

Get size position for a 3d world space position

=head2 GetWorldToScreen2D( $position, $camera) : Raylib::FFI::Vector2D

Get the screen space position for a 2d camera world space position

=head2 GetScreenToWorld2D( $position, $camera) : Raylib::FFI::Vector2D;

Get the world space position for a 2d camera screen space position

=head2 GetCameraMatrix( $camera ) : Raylib::FFI::Matrix;

Get camera transform matrix (view matrix)

=head2 GetCameraMatrix2D( $camera ) : Raylib::FFI::Matrix;

Get camera 2d transform matrix

=head2 SetTargetFPS( $fps )

Set target FPS (maximum)

=head2 GetFrameTime() : float

Get time in seconds for last frame drawn (delta time)

=head2 GetTime() : double

Get elapsed time in seconds since InitWindow()

=head2 GetFPS() : int

Get current FPS

=head2 SwapScreenBuffer()

NOTE: This function is intended for advanced users that want full control over
the frame processing.  default EndDrawing() does this job: draws everything +
SwapScreenBuffer() + manage frame timing + PollInputEvents(). To avoid that
behaviour and control frame processes manually, enable in config.h:
SUPPORT_CUSTOM_FRAME_CONTROL

Swap backbuffer with frontbuffer (screen drawing)

=head2 PollInputEvents()

NOTE: This function is intended for advanced users that want full control over
the frame processing.  default EndDrawing() does this job: draws everything +
SwapScreenBuffer() + manage frame timing + PollInputEvents(). To avoid that
behaviour and control frame processes manually, enable in config.h:
SUPPORT_CUSTOM_FRAME_CONTROL

Register all input events

=head2 WaitTime( $seconds )

NOTE: This function is intended for advanced users that want full control over
the frame processing.  default EndDrawing() does this job: draws everything +
SwapScreenBuffer() + manage frame timing + PollInputEvents(). To avoid that
behaviour and control frame processes manually, enable in config.h:
SUPPORT_CUSTOM_FRAME_CONTROL

Wait for some time (halt program execution)

=head2 TakeScreenshot( $fileName )

Takes a screenshot of current screen (filename extension defines format)

=head2 SetConfigFlags( $flags )

Setup init configuration flags (view FLAGS)

=head2 OpenURL( $url )

Open URL with default system browser (if available)

=head2 TraceLog( $logLevel, $text )

Show trace log messages (LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR...)

=head2 SetTraceLogLevel( $logLevel )

Set the current threshold (minimum) log level

=head2 IsKeyPressed( $key ) : bool

Check if a key has been pressed once

=head2 IsKeyPressedRepeat( $key ) : bool

Check if a key has been pressed again (Only PLATFORM_DESKTOP)

=head2 IsKeyDown( $key ) : bool

Check if a key is being pressed

=head2 IsKeyReleased( $key ) : bool

Check if a key has been released once

=head2 IsKeyUp( $key ) : bool

Check if a key is NOT being pressed

=head2 GetKeyPressed() : int

Get latest key pressed. Returns 0 if no key was pressed during the last frame

=head2 GetCharPressed() : int

Get char pressed (unicode), call it multiple times for chars queued, returns 0 when the queue is empty

=head2 SetExitKey( $key )

Set a custom key to exit program (default is ESC)

=head2 IsGamepadAvailable( $gamepad ) : bool

Check if a gamepad is available

=head2 GetGamepadName( $gamepad ) : string

Get gamepad internal name id

=head2 IsGamepadButtonPressed( $gamepad, $button ) : bool

Check if a gamepad button has been pressed once

=head2 IsGamepadButtonDown( $gamepad, $button ) : bool

Check if a gamepad button is being pressed

=head2 IsGamepadButtonReleased( $gamepad, $button ) : bool

Check if a gamepad button has been released once

=head2 IsGamepadButtonUp( $gamepad, $button ) : bool

Check if a gamepad button is NOT being pressed

=head2 GetGamepadButtonPressed() : int

Get the last gamepad button pressed

=head2 GetGamepadAxisCount( $gamepad ) : int

Get gamepad axis count for a gamepad

=head2 GetGamepadAxisMovement( $gamepad, $axis ) : float

Get axis movement value for a gamepad axis

=head2 SetGamepadMappings( $mappings )

Set internal gamepad mappings

=head2 IsMouseButtonPressed( $button ) : bool

Check if a mouse button has been pressed once

=head2 IsMouseButtonDown( $button ) : bool

Check if a mouse button is being pressed

=head2 IsMouseButtonReleased( $button ) : bool

Check if a mouse button has been released once

=head2 IsMouseButtonUp( $button ) : bool

Check if a mouse button is NOT being pressed

=head2 GetMouseX() : int

Get mouse position X

=head2 GetMouseY() : int

Get mouse position Y

=head2 GetMousePosition() : Raylib::FFI::Vector2D

Get mouse position XY

=head2 GetMouseDelta() : Raylib::FFI::Vector2D

Get mouse delta between frames

=head2 SetMousePosition( $x, $y )

Set mouse position XY

=head2 SetMouseOffset( $offsetX, $offsetY )

Set mouse offset

=head2 SetMouseScale( $scaleX, $scaleY )

Set mouse scaling

=head2 GetMouseWheelMove() : int

Get mouse wheel movement for X or Y, whichever is larger

=head2 GetMouseWheelMoveV() : Raylib::FFI::Vector2D

Get mouse wheel movement for both X and Y

=head2 SetMouseCursor( $cursor )

Set mouse cursor

=head2 GetTouchX() : int

Get touch position X for touch point 0 (relative to screen size).

=head2 GetTouchY() : int

Get touch position Y for touch point 0 (relative to screen size).

=head2 GetTouchPosition( $index ) : Raylib::FFI::Vector2D

Get touch position XY for a touch point index (relative to screen size).

=head2 GetTouchPointId( $index ) : int

Get touch point identifier for given index.

=head2 GetTouchPointCount() : int

Get number of touch points

=head2 SetGesturesEnabled( $flags )

Enable a set of gestures using flags

=head2 IsGestureDetected( $gesture ) : bool

Check if a gesture have been detected

=head2 GetGestureDetected() : int

Get latest detected gesture

=head2 GetGestureHoldDuration() : float

Get gesture hold time in milliseconds

=head2 GetGestureDragVector() : Raylib::FFI::Vector2D

Get gesture drag vector

=head2 GetGestureDragAngle() : float

Get gesture drag angle

=head2 GetGesturePinchVector() : Raylib::FFI::Vector2D

Get gesture pinch delta

=head2 GetGesturePinchAngle() : float

Get gesture pinch angle

=head2 UpdateCamera( $camera )

Update camera position for selected mode

=head2 UpdateCameraPro( $camera, $dest, $rotation, $zoom )

Uppdate camera movement/rotation

=head2 SetShapesTexture( $texture, $rec )

Set texture and rectangle to be used on shapes drawing

=head2 GetShapesTextureRec() : Raylib::FF::Rectangle

Get texture rectangle to be used on shapes drawing

=head2 DrawPixel( $posX, $posY, $color )

Draw a pixel

=head2 DrawPixelV( $position, $color )

Draw a pixel (Vector version)

=head2 DrawLine( $startPosX, $startPosY, $endPosX, $endPosY, $color )

Draw a line

=head2 DrawLineV( $startPos, $endPos, $color )

Draw a line (using gl lines)

=head2 DrawLineEx( $startPos, $endPos, $thick, $color )

Draw a line (using triangles/quads)

=head2 DrawLineStrip( $points, $pointCount, $color )

Draw lines sequence (using gl lines)

=head2 DrawLineBezier( $startPos, $endPos, $thick, $color )

Draw line segment cubic-bezier in-out interpolation

=head2 DrawCircle( $centerX, $centerY, $radius, $color )

Draw a color-filled circle

=head2 DrawCircleSector( $center, $radius, $startAngle, $endAngle, $segments, $color )

Draw a piece of a circle

=head2 DrawCircleSectorLines( $center, $radius, $startAngle, $endAngle, $segments, $color )

Draw circle sector outline

=head2 DrawCircleGradient( $centerX, $centerY, $radius, $color1, $color2 )

Draw a gradient-filled circle

=head2 DrawCircleV( $center, $radius, $color )

Draw a color-filled circle (Vector version)

=head2 DrawCircleLines( $centerX, $centerY, $radius, $color )

Draw circle outline

=head2 DrawCircleLinesV( $center, $radius, $color )

Draw circle outline (Vector version)

=head2 DrawEllipse( $centerX, $centerY, $radiusH, $radiusV, $color )

Draw ellipse

=head2 DrawEllipseLines( $centerX, $centerY, $radiusH, $radiusV, $color )

Draw ellipse outline

=head2 DrawRing( $center, $innerRadius, $outerRadius, $startAngle, $endAngle, $segments, $color )

Draw ring

=head2 DrawRingLines( $center, $innerRadius, $outerRadius, $startAngle, $endAngle, $segments, $color )

Draw ring outline

=head2 DrawRectangle( $posX, $posY, $width, $height, $color )

Draw a color-filled rectangle

=head2 DrawRectangleV( $position, $size, $color )

Draw a color-filled rectangle (Vector version)

=head2 DrawRectangleRec( $rec, $color )

Draw a color-filled rectangle

=head2 DrawRectanglePro( $rec, $origin, $rotation, $color )

Draw a color-filled rectangle with pro parameters

=head2 DrawRectangleGradientV( $posX, $posY, $width, $height, $color1, $color2 )

Draw a vertical-gradient-filled rectangle

=head2 DrawRectangleGradientH( $posX, $posY, $width, $height, $color1, $color2 )

Draw a horizontal-gradient-filled rectangle

=head2 DrawRectangleGradientEx( $rec, $col1, $col2, $col3, $col4 )

Draw a gradient-filled rectangle with custom vertex colors

=head2 DrawRectangleLines( $posX, $posY, $width, $height, $color )

Draw rectangle outline

=head2 DrawRectangleLinesEx( $rec, $lineThick, $color )

Draw rectangle outline with extended parameters

=head2 DrawRectangleRounded( $rec, $roundness, $segments, $color )

Draw rectangle with rounded edges

=head2 DrawRectangleRoundedLines( $rec, $roundness, $segments, $lineThick, $color )

Draw rectangle lines with rounded edges

=head2 DrawTriangle( $v1, $v2, $v3 )

Draw a color-filled triangle (vertex in counter-clockwise order!)

=head2 DrawTriangleLines( $v1, $v2, $v3 )

Draw triangle outline (vertex in counter-clockwise order!)

=head2 DrawTriangleFan( $points, $pointCount )

Draw a triangle fan defined by points (first vertex is the center)

=head2 DrawTriangleStrip( $points, $pointCount )

Draw a triangle strip defined by points

=head2 DrawPoly( $center, $sides, $radius, $rotation, $color )

Draw a regular polygon (Vector version)

=head2 DrawPolyLines( $center, $sides, $radius, $rotation, $color )

Draw a polygon outline of n sides

=head2 DrawPolyLinesEx( $center, $sides, $radius, $rotation, $lineThick, $color )

Draw a polygon outline of n sides with extended parameters

=head2 DrawSplineLinear( $points, $pointCount, $color )

Draw spline: Linear, minimum 2 points

=head2 DrawSplineBasis( $points, $pointCount, $color )

Draw spline: B-Spline, minimum 4 points

=head2 DrawSplineCatmullRom( $points, $pointCount, $color )

Draw spline: Catmull-Rom, minimum 4 points

=head2 DrawSplineBezierQuadratic( $points, $pointCount, $color )

Draw spline: Quadratic Bezier, minimum 3 points (1 control point): [p1, c2, p3, c4...]

=head2 DrawSplineBezierCubic( $points, $pointCount, $color )

Draw spline: Cubic Bezier, minimum 4 points (2 control points): [p1, c2, c3, p4, c5, c6...]

=head2 DrawSplineSegmentLinear( $p1, $p2, $color )

Draw spline segment: Linear, 2 points

=head2 DrawSplineSegmentBasis( $p1, $p2, $color )

Draw spline segment: B-Spline, 4 points

=head2 DrawSplineSegmentCatmullRom( $p1, $p2, $color )

Draw spline segment: Catmull-Rom, 4 points

=head2 DrawSplineSegmentBezierQuadratic( $p1, $p2, $p3, $color )

Draw spline segment: Quadratic Bezier, 2 points, 1 control point

=head2 DrawSplineSegmentBezierCubic( $p1, $p2, $p3, $p4, $color )

Draw spline segment: Cubic Bezier, 2 points, 2 control points

=head2 GetSplinePointLinear( $points, $pointCount, $t ) : Raylib::FFI::Vector2D

Get (evaluate) spline point: Linear
Spline segment point evaluation functions, for a given t [0.0f .. 1.0f]

=head2 GetSplinePointBasis( $points, $pointCount, $t ) : Raylib::FFI::Vector2D

Get (evaluate) spline point: B-Spline
Spline segment point evaluation functions, for a given t [0.0f .. 1.0f]

=head2 GetSplinePointCatmullRom( $points, $pointCount, $t ) : Raylib::FFI::Vector2D

Get (evaluate) spline point: Catmull-Rom
Spline segment point evaluation functions, for a given t [0.0f .. 1.0f]

=head2 GetSplinePointBezierQuad( $points, $pointCount, $t ) : Raylib::FFI::Vector2D

Get (evaluate) spline point: Quadratic Bezier
Spline segment point evaluation functions, for a given t [0.0f .. 1.0f]

=head2 GetSplinePointBezierCubic( $points, $pointCount, $t ) : Raylib::FFI::Vector2D

Get (evaluate) spline point: Cubic Bezier
Spline segment point evaluation functions, for a given t [0.0f .. 1.0f]

=head2 CheckCollisionRecs( $rec1, $rec2 ) : bool

Check collision between two rectangles

=head2 CheckCollisionCircles( $center1, $radius1, $center2, $radius2 ) : bool

Check collision between two circles

=head2 CheckCollisionCircleRec( $center, $radius, $rec ) : bool

Check collision between circle and rectangle

=head2 CheckCollisionPointRec( $point, $rec ) : bool

Check if point is inside rectangle

=head2 CheckCollisionPointCircle( $point, $center, $radius ) : bool

Check if point is inside circle

=head2 CheckCollisionPointTriangle( $point, $p1, $p2, $p3 ) : bool

Check if point is inside a triangle

=head2 CheckCollisionPointPoly( $point, $poly, $polyCount ) : bool

Check if point is within a polygon described by array of vertices

=head2 CheckCollisionLines( $startPos1, $endPos1, $startPos2, $endPos2, $collisionPoint ) : bool

Check the collision between two lines defined by two points each, returns collision point by reference

=head2 CheckCollisionPointLine( $point, $p1, $p2, $threshold ) : bool

Check if point belongs to line created between two points [p1] and [p2] with defined margin in pixels [threshold]


=head2 GetCollisionRec( $rec1, $rec2 ) : Raylib::FFI::Rectangle

Get collision rectangle for two rectangles collision

=head2 LoadImage( $fileName ) : Raylib::FFI::Image

Load image from file into CPU memory (RAM)
NOTE: This function does not require GPU access

=head2 LoadImageRaw( $fileName, $width, $height, $format, $headerSize ) : Raylib::FFI::Image

Load image from RAW file data
NOTE: This function does not require GPU access

=head2 LoadImageSvg( $string, $width, $height ) : Raylib::FFI::Image

Load image from SVG file data or string with specified size
NOTE: This function does not require GPU access

=head2 LoadImageAnim( $fileName, $frames ) : Raylib::FFI::Image

Load image sequence from file (frames appended to image.data)
NOTE: This function does not require GPU access

=head2 LoadImageFromMemory( $fileType, $fileData, $dataSize ) : Raylib::FFI::Image

Load image from memory buffer, fileType refers to extension: i.e. '.png'
NOTE: This function does not require GPU access

=head2 LoadImageFromTexture( $texture ) : Raylib::FFI::Image

Load image from GPU texture data
NOTE: This function requires GPU access

=head2 LoadImageFromScreen() : Raylib::FFI::Image

Load image from screen buffer and (screenshot)
NOTE: This function requires GPU access

=head2 IsImageReady( $image ) : bool

Check if an image is ready

=head2 UnloadImage( $image )

Unload image from CPU memory (RAM)

=head2 ExportImage( $image, $fileName ) : bool

Export image data to file, returns true on success

=head2 GenImageColor( $width, $height, $color ) : Raylib::FFI::Image

Generate image: plain color

=head2 GenImageGradientLinear( $width, $height, $top, $bottom ) : Raylib::FFI::Image

Generate image: linear gradient, direction in degrees [0..360], 0=Vertical gradient

=head2 GenImageGradientRadial( $width, $height, $density, $inner, $outer ) : Raylib::FFI::Image

Generate image: radial gradient

=head2 GenImageGradientSquare( $width, $height, $left, $right, $top, $bottom ) : Raylib::FFI::Image

Generate image: square gradient

=head2 GenImageChecked( $width, $height, $checksX, $checksY, $col1, $col2 ) : Raylib::FFI::Image

Generate image: checked

=head2 GenImageWhiteNoise( $width, $height, $factor ) : Raylib::FFI::Image

Generate image: white noise

=head2 GenImagePerlinNoise( $width, $height, $offsetX, $offsetY, $scale ) : Raylib::FFI::Image

Generate image: perlin noise

=head2 GenImageCellular( $width, $height, $tileSize ) : Raylib::FFI::Image

Generate image: cellular algorithm, bigger tileSize means bigger cells

=head2 GenImageText( $width, $height, $text ) : Raylib::FFI::Image

Generate image: grayscale image from text

=head2 ImageCopy( $image ) : Raylib::FFI::Image

Create an image duplicate (useful for transformations)

=head2 ImageFromImage( $image, $rec, $rec2 ) : Raylib::FFI::Image

Create an image from another image region

=head2 ImageText( $text, $fontSize, $color ) : Raylib::FFI::Image

Create an image from text (default font)

=head2 ImageTextEx($font, $text, $fontSize, $spacing, $tint) : Raylib::FFI::Image

Create an image from text (custom sprite font)

=head2 ImageFormat( $image, $format )

Convert image data to desired format

=head2 ImageToPOT( $image )

Convert image to POT (power-of-two)

=head2 ImageCrop( $image, $crop )

Crop an image to a defined rectangle

=head2 ImageAlphaCrop( $image, $threshold )

Crop image depending on alpha value

=head2 ImageAlphaClear( $image, $color, $threshold )

Clear alpha channel to desired color

=head2 ImageAlphaMask( $image, $mask )

Apply alpha mask to image

=head2 ImageAlphaPremultiply( $image )

Premultiply alpha channel

=head2 ImageBlurGaussian( $image, $blurSize, $threshold )

Apply Gaussian blur using a box blur approximation

=head2 ImageResize( $image, $newWidth, $newHeight )

Resize image (Bicubic scaling algorithm)

=head2 ImageResizeNN( $image, $newWidth, $newHeight )

Resize image (Nearest-Neighbor scaling algorithm)

=head2 ImageResizeCanvas( $image, $newWidth, $newHeight, $offsetX, $offsetY, $fill )

Resize canvas and fill with color

=head2 ImageMipmaps( $image )

Compute all mipmap levels for a provided image

=head2 ImageDither( $image, $rBpp, $gBpp, $bBpp, $aBpp )

Dither image data to 16bpp or lower (Floyd-Steinberg dithering)

=head2 ImageFlipVertical( $image )

Flip image vertically

=head2 ImageFlipHorizontal( $image )

Flip image horizontally

=head2 ImageRotate( $image, $rotation )

Rotate image

=head2 ImageRotateCW( $image )

Rotate image clockwise 90deg

=head2 ImageRotateCCW( $image )

Rotate image counter-clockwise 90deg

=head2 ImageColorTint( $image, $color )

Modify image color: tint

=head2 ImageColorInvert( $image )

Modify image color: invert

=head2 ImageColorGrayscale( $image )

Modify image color: grayscale

=head2 ImageColorContrast( $image, $contrast )

Modify image color: contrast (-100 to 100)

=head2 ImageColorBrightness( $image, $brightness )

Modify image color: brightness (-255 to 255)

=head2 ImageColorReplace( $image, $color, $replace )

Modify image color: replace color

=head2 LoadImageColors( $image ) : Raylib::FFI::Color*

Load color data from image as a Color array (RGBA - 32bit)

=head2 LoadImagePalette( $image, $maxPaletteSize ) : Raylib::FFI::Color*

Load colors palette from image as a Color array (RGBA - 32bit)

=head2 UnloadImageColors( $colors )

Unload color data loaded with LoadImageColors()

=head2 UnloadImagePalette( $colors )

Unload colors palette loaded with LoadImagePalette()

=head2 GetImageAlphaBorder( $image, $threshold ) : Raylib::FFI::Rectangle

Get image alpha border rectangle

=head2 GetImageColor( $image, $x, $y ) : Raylib::FFI::Color

Get image pixel color at (x, y) position

=head2 ImageClearBackground( $image, $color )

Clear image background with given color

=head2 ImageDrawPixel( $image, $posX, $posY, $color )

Draw pixel within an image

=head2 ImageDrawPixelV( $image, $position, $color )

Draw pixel within an image (Vector version)

=head2 ImageDrawLine( $image, $startX, $startY, $endX, $endY, $color )

Draw line within an image

=head2 ImageDrawLineV( $image, $start, $end, $color )

aw line within an image (Vector version)

=head2 ImageDrawCircle( $image, $centerX, $centerY, $radius, $color )

Draw a filled circle within an image

=head2 ImageDrawCircleV( $image, $center, $radius, $color )

Draw a filled circle within an image (Vector version)

=head2 ImageDrawCircleLines( $image, $centerX, $centerY, $radius, $color )

Draw circle outline within an image

=head2 ImageDrawRectangle( $image, $posX, $posY, $width, $height, $color )

Draw circle outline within an image (Vector version)

=head2 ImageDrawRectangleV( $image, $position, $size, $color )

Draw rectangle within an image

=head2 ImageDrawRectangleV($image, $position, $size, $color)

Draw rectangle within an image (Vector version)

=head2 ImageDrawRectangleRec( $image, $rec, $color )

Draw rectangle within an image

=head2 ImageDrawRectangleLines( $image, $rec, $thick, $color )

Draw rectangle lines within an image

=head2 ImageDraw( $dst, $src, $srcRec, $dstRec, $tint )

Draw a source image within a destination image (tint applied to source)

=head2 ImageDrawText( $dst, $text, $posX, $posY, $fontSize, $color )

Draw text (using default font) within an image (destination)

=head2 ImageDrawTextEx( $dst, $text, $position, $fontSize, $spacing, $tint )

Draw text (custom sprite font) within an image (destination)

=head2 LoadTexture( $fileName ) : Raylib::FFI::Texture2D

Load texture from file into GPU memory (VRAM)
NOTE: This function requires GPU access

=head2 LoadTextureFromImage( $image ) : Raylib::FFI::Texture2D

Load texture from image data
NOTE: This function requires GPU access

=head2 LoadTextureCubemap( $image, $layout ) : Raylib::FFI::TextureCubemap

Load cubemap from image, multiple image cubemap layouts supported
NOTE: This function requires GPU access

=head2 LoadRenderTexture( $width, $height ) : Raylib::FFI::RenderTexture2D

Load texture for rendering (framebuffer)
NOTE: This function requires GPU access

=head2 IsTextureReady( $texture ) : bool

Check if a texture is ready

=head2 UnloadTexture( $texture )

Unload texture from GPU memory (VRAM)

=head2 IsRenderTextureReady( $renderTexture ) : bool

Check if a render texture is ready

=head2 UnloadRenderTexture( $renderTexture )

Unload render texture from GPU memory (VRAM)

=head2 UpdateTexture( $texture, $pixels )

Update GPU texture with new data

=head2 UpdateTextureRec( $texture, $rec, $pixels )

Update GPU texture rectangle with new data

=head2 GenTextureMipmaps( $texture )

Generate GPU mipmaps for a texture

=head2 SetTextureFilter( $texture, $filter )

Set texture scaling filter mode

=head2 SetTextureWrap( $texture, $wrap )

Set texture wrapping mode

=head2 DrawTexture( $texture, $posX, $posY, $tint )

Draw a Texture2D

=head2 DrawTextureV( $texture, $position, $tint )

Draw a Texture2D with position defined as Vector2

=head2 DrawTextureEx( $texture, $position, $rotation, $tint )

Draw a Texture2D with extended parameters

=head2 DrawTextureRec( $texture, $source, $position, $tint )

Draw a part of a texture defined by a rectangle

=head2 DrawTexturePro( $texture, $source, $dest, $origin, $rotation, $tint )

Draw a part of a texture defined by a rectangle with 'pro' parameters

=head2 DrawTextureNPatch( $texture, $nPatchInfo, $dest, $origin, $rotation, $tint )

Draws a texture (or part of it) that stretches or shrinks nicely


=head2 Fade( $color, $alpha ) : Raylib::FFI::Color

Get color with alpha applied

=head2 ColorToInt( $color ) : int

Get hexadecimal value for a Color

=head2 ColorNormalize( $color ) : Raylib::FFI::Vector4

Get Color normalized as float [0..1]

=head2 ColorToHSV( $color ) : Raylib::FFI::Vector3

Get HSV values for a Color

=head2 ColorFromHSV( $hsv ) : Raylib::FFI::Color

Get Color from HSV values. Hue [0..360], Saturation [0..1], Value [0..1]

=head2 ColorTint( $color ) : int

Get Color multiplied with another color

=head2 ColorBrightness( $color, $factor ) : Raylib::FFI::Color

Get Color with brightness correction, brightness factor [0..1]

=head2 ColorContrast( $color, $contrast ) : Raylib::FFI::Color

Get Color with contrast correction, contrast factor [0..1]

=head2 ColorAlpha( $color, $alpha ) : Raylib::FFI::Color

Get src alpha-blended into dst color with tint

=head2 ColorAlphaBlend( $dst, $src, $tint ) : Raylib::FFI::Color

Get Color structure from hexadecimal value

=head2 GetColor( $hexValue ) : Raylib::FFI::Color

Get Color structure from hexadecimal value

=head2 GetPixelColor( $srcPtr, $format ) : Raylib::FFI::Color

Get Color from a source pixel pointer of certain format

=head2 SetPixelColor( $dstPtr, $color, $format )

Set color formatted into destination pixel pointer

=head2 GetPixelDataSize( $width, $height, $format ) : int

Get pixel data size in bytes for certain format

=head2 GetFontDefault() : Raylib::FFI::Font

Get the default Font

=head2 LoadFont( $fileName ) : Raylib::FFI::Font

Load font from file into GPU memory (VRAM)

=head2 LoadFontEx( $fileName, $fontSize, $fontChars, $glyphCount ) : Raylib::FFI::Font

Load font from file with extended parameters, use undef for codepoints and 0 for
codepointCount to load the default character set

=head2 LoadFontFromImage( $image, $fontSize, $fontChars, $glyphCount ) : Raylib::FFI::Font

Load font from Image (XNA style)

=head2 LoadFontFromMemory( $fileType, $fileData, $dataSize, $fontSize, $fontChars, $glyphCount ) : Raylib::FFI::Font

Load font from memory buffer, fileType refers to extension: i.e. '.ttf'

=head2 IsFontReady( $font ) : bool

Check if a font is ready

=head2 LoadFontData( $fileData, $dataSize, $fontSize, $fontChars, $glyphCount, $type ) : Raylib::FFI::GlyphInfo

Load font data for further use

=head2 GenImageFontAtlas( $glyphs, $glyphCount, $fontSize, $padding, $packMethod ) : Raylib::FFI::Image

Generate image font atlas using chars info

=head2 UnloadFontData( $glyphs, $glyphCount )

Unload font chars info data (RAM)

=head2 UnloadFont( $font )

Unload font from GPU memory (VRAM)

=head2 DrawFPS( $posX, $posY )

Draw current FPS

=head2 DrawText( $text, $posX, $posY, $fontSize, $color )

Draw text (using default font)

=head2 DrawTextEx( $font, $text, $position, $fontSize, $spacing, $tint )

Draw text using font and additional parameters

=head2 DrawTextPro( $font, $text, $position, $origin, $rotation, $fontSize, $spacing, $tint )

Draw text using Font and pro parameters (rotation)

=head2 DrawTextCodepoint( $font, $codepoint, $position, $fontSize, $tint )

Draw one character (codepoint)

=head2 DrawTextCodepoints( $font, $codepoints, $count, $position, $fontSize, $spacing, $tint )

Draw multiple character (codepoint)

=head2 SetTextLineSpacing( $spacing )

Set vertical line spacing when drawing with line-breaks

=head2 MeasureText( $text, $fontSize ) : int

Measure string width for default font

=head2 MeasureTextEx( $font, $text, $fontSize, $spacing ) : Raylib::FFI::Vector2D

Measure string size for Font

=head2 GetGlyphIndex( $font, $codepoint ) : int

Get glyph index position in font for a codepoint (unicode character), fallback
to '?' if not found

=head2 GetGlyphInfo( $font, $codepoint ) : Raylib::FFI::GlyphInfo

Get glyph font info data for a codepoint (unicode character), fallback to '?'
if not found

=head2 GetGlyphAtlasRec( $font, $codepoint ) : Raylib::FFI::Rectangle

Get glyph rectangle in font atlas for a codepoint (unicode character), fallback
to '?' if not found

=head2 LoadCodepoints( $text, $count ) : int

Load all codepoints from a UTF-8 text string, codepoints count returned by parameter

=head2 UnloadCodepoints( $codepoints, $count )

Unload codepoints data from memory

=head2 GetCodepointCount( $text ) : int

Get total number of codepoints in a UTF-8 encoded string

=head2 GetCodepoint( $text, $index ) : int

Get next codepoint in a UTF-8 encoded string, 0x3f('?') is returned on failure

=head2 GetCodepointNext( $text, $index ) : int

Get next codepoint in a UTF-8 encoded string, 0x3f('?') is returned on failure

=head2 GetCodepointPrevious( $text, $index ) : int

Get previous codepoint in a UTF-8 encoded string, 0x3f('?') is returned on failure

=head2 CodepointToUtf8( $codepoint, $byteSize ) : string

Encode one codepoint into UTF-8 byte array (array length returned as parameter)

=head2 TextToInteger( $text ) : int

Get integer value from text (negative values not supported)

=head2 DrawLine3D( $startPos, $endPos, $color )

Draw a line in 3D world space

=head2 DrawPoint3D( $position, $color )

Draw a point in 3D space, actually a small line

=head2 DrawCircle3D( $center, $radius, $rotationAxis, $rotationAngle, $color )

Draw a circle in 3D world space

=head2 DrawTriangle3D( $v1, $v2, $v3, $color )

Draw a triangle in 3D space

=head2 DrawTriangleStrip3D( $points, $pointCount, $color )

Draw a triangle strip defined by points

=head2 DrawCube( $position, $width, $height, $length, $color )

Draw cube

=head2 DrawCubeV( $position, $size, $color )

Draw cube (Vector version)

=head2 DrawCubeWires( $position, $width, $height, $length, $color )

Draw cube wires

=head DrawSphere( $centerPos, $radius, $color )

Draw sphere

=head DrawSphereEx( $centerPos, $radius, $rings, $segments, $color )

Draw sphere with extended parameters

=head DrawSphereWires( $centerPos, $radius, $rings, $segments, $color )

Draw sphere wires

=head2 DrawCylinder( $position, $radiusTop, $radiusBottom, $height, $slices, $color )

Draw a cylinder/cone

=head2 DrawCylinderEx( $position, $radiusTop, $radiusBottom, $height, $slices, $color )

Draw cylinder with base at startPos and top at endPos

=head2 DrawCylinderWires( $position, $radiusTop, $radiusBottom, $height, $slices, $color )

Draw cylinder/cone wires

=head2 DrawCylinderWiresEx($startPos, $endPos, $startRadius, $endRadius, $sides, $color)

Draw a cylinder with base at startPos and top at endPos

=head2 DrawCapsule( $startPos, $endPos, $radius, $slices, $segments, $color )

Draw a capsule with the center of its sphere caps at startPos and endPos

=head2 DrawCapsuleWires($startPos, $endPos, $radius, $slices, $rings, $color)

Draw capsule wireframe with the center of its sphere caps at startPos and endPos

=head2 DrawPlane($centerPos, $size, $color)

Draw a plane XZ

=head2 DrawRay( $ray, $color )

Draw a ray line

=head2 DrawGrid( $slices, $color )

Draw a grid (centered at (0, 0, 0))

=head2 LoadModel( $fileName ) : Raylib::FFI::Model

Load model from files (meshes and materials)

=head2 LoadModelFromMesh( $mesh ) : Raylib::FFI::Model

Load model from generated mesh (default material)

=head2 IsModelReady( $model ) : bool

Check if an model is ready

=head2 UnloadModel( $model )

Unload model (including meshes) from memory (RAM and/or VRAM)

=head2 GetModelBoundingBox( $model ) : Raylib::FFI::BoundingBox

Compute model bounding box limits (considering all meshes)

=head2 DrawModel( $model, $position, $scale, $tint )

Draw a model (with texture if set)

=head2 DrawModelEx( $model, $position, $rotationAxis, $rotationAngle, $scale, $tint )

Draw a model with extended parameters

=head2 DrawModelWires( $model, $position, $scale, $tint )

Draw model wires (with texture if set)

=head2 DrawModelWiresEx( $model, $position, $rotationAxis, $rotationAngle, $scale, $tint )

Draw model wires (with texture if set) with extended parameters

=head2 DrawBoundingBox( $box, $color )

Draw bounding box (wires)

=head2 DrawBillboard( $camera, $texture, $position, $size, $tint )

Draw a billboard texture

=head2 DrawBillboardRec( $camera, $texture, $source, $position, $size, $tint )

Draw a billboard texture defined by source

=head2 DrawBillboardPro( $camera, $texture, $source, $position, $up, $size, $origin, $rotation, $tint )

Draw a billboard texture defined by source and rotation

=head2 UploadMesh( $mesh, $dynamic )

Upload mesh vertex data in GPU and provide VAO/VBO ids

=head2 UnloadMesh( $mesh )

Unload mesh from CPU and GPU

=head2 DrawMesh( $mesh, $material, $transform )

Draw a 3d mesh with material and transform

=head2 GetMeshBoundingBox( $mesh ) : Raylib::FFI::BoundingBox

Compute mesh bounding box limits

=head2 GenMeshTangents( $mesh )

Compute mesh tangents

=head2 ExportMesh( $mesh, $fileName ) : bool

Export mesh data to file, returns true on success

=head2 GenMeshPoly( $sides, $radius ) : Raylib::FFI::Mesh

Generate polygonal mesh

=head2 GenMeshPlane( $width, $length, $resX, $resZ ) : Raylib::FFI::Mesh

Generate plane mesh (with subdivisions)

=head2 GenMeshCube( $width, $height, $length ) : Raylib::FFI::Mesh

Generate cuboid mesh

=head2 GenMeshSphere( $radius, $rings, $slices ) : Raylib::FFI::Mesh

Generate sphere mesh

=head2 GenMeshHemiSphere( $radius, $rings, $segments ) : Raylib::FFI::Mesh

Generate half-sphere mesh (no bottom cap)

=head2 GenMeshCylinder( $radius, $height, $slices ) : Raylib::FFI::Mesh

Generate cylinder mesh

=head2 GenMeshCone( $radius, $height, $slices ) : Raylib::FFI::Mesh

Generate cone/pyramid mesh

=head2 GenMeshTorus( $radius, $size, $radSeg, $sides ) : Raylib::FFI::Mesh

Generate torus mesh

=head2 GenMeshKnot( $radius, $size, $radSeg, $sides ) : Raylib::FFI::Mesh

Generate trefoil knot mesh

=head2 GenMeshHeightmap( $heightmap, $size ) : Raylib::FFI::Mesh

Generate heightmap mesh from image data ($heightmap)

=head2 GenMeshCubicmap( $cubicmap, $cubeSize ) : Raylib::FFI::Mesh

Generate cubes-based map mesh from image data

=head2 LoadMaterials( $fileName, $materialCount ) : Raylib::FFI::Material

Load materials from model file

=head2 LoadMaterialDefault() : Raylib::FFI::Material

Load default material (Supports: Diffuse Maps, Specular Maps, Normal Maps)

=head2 IsMaterialReady( $material ) : bool

Check if a material is ready

=head2 UnloadMaterial( $material )

Unload material from GPU memory (VRAM)

=head2 SetMaterialTexture( $material, $mapType, $texture )

Set texture for a material map type (MAT_MAP_DIFFUSE, MAT_MAP_SPECULAR...)

=head2 SetModelMeshMaterial( $model, $meshId, $materialId )

Set material for a mesh

=head2 LoadModelAnimations( $fileName, $animCount ) : Raylib::FFI::ModelAnimation

Load model animations from file

=head2 UpdateModelAnimation( $model, $anim, $frame )

Update model animation pose

=head2 UnloadModelAnimation( $anim )

Unload animation data

=head2 UnloadModelAnimations( $model, $animCount )

Unload animation array data

=head2 IsModelAnimationValid( $model, $anim ) : bool

Check model animation skeleton match

=head2 CheckCollisionSpheres( $centerA, $radiusA, $centerB, $radiusB ) : bool

Check collision between two spheres

=head2 CheckCollisionBoxes( $box1, $box2 ) : bool

Check collision between two bounding boxes

=head2 CheckCollisionBoxSphere( $box, $center, $radius ) : bool

Check collision between box and sphere

=head2 GetRayCollisionSphere( $ray, $center, $radius ) : Raylib::FFI::RayCollision

Get collision info between ray and sphere

=head2 GetRayCollisionBox( $ray, $box ) : Raylib::FFI::RayCollision

Get collision info between ray and box

=head2 GetRayCollisionMesh( $ray, $mesh, $transform ) : Raylib::FFI::RayCollision

Get collision info between ray and mesh

=head2 GetRayCollisionTriangle( $ray, $p1, $p2, $p3 ) : Raylib::FFI::RayCollision

Get collision info between ray and triangle

=head2 GetRayCollisionQuad( $ray, $p1, $p2, $p3, $p4 ) : Raylib::FFI::RayCollision

Get collision info between ray and quad

=head2 InitAudioDevice()

Initialize audio device and context

=head2 CloseAudioDevice()

Close the audio device and context

=head2 IsAudioDeviceReady() : bool

Check if audio device has been initialized successfully

=head2 SetMasterVolume( $volume )

Set master volume (listener)

=head2 GetMasterVolume() : float

Get master volume (listener)

=head2 LoadWave( $fileName ) : Raylib::FFI::Wave

Load wave data from file

=head2 LoadWaveFromMemory( $fileType, $fileData, $dataSize ) : Raylib::FFI::Wave

Load wave from memory buffer, fileType refers to extension: i.e. ".wav"

=head2 LoadSound( $fileName ) : Raylib::FFI::Sound

Load sound from file

=head2 LoadSoundFromWave( $wave ) : Raylib::FFI::Sound

Load sound from wave data

=head2 LoadSoundAlias( $sound, $fileName ) : Raylib::FFI::Sound

Create a new sound that shares the same sound data as another existing sound

=head2 IsSoundReady( $sound ) : bool

Check if a sound is ready

=head2 UpdateSound( $sound, $data )

Update sound buffer with new data

=head2 UnloadWave( $wave )

Unload wave data

=head2 UnloadSound( $sound )

Unload sound

=head2 ExportWave( $wave, $fileName ) : bool

Export wave data to file, return true on success

=head2 PlaySound( $sound )

Play a sound

=head2 StopSound( $sound )

Stop playing a sound

=head2 PauseSound( $sound )

Pause a sound

=head2 ResumeSound( $sound )

Resume a paused sound

=head2 IsSoundPlaying( $sound ) : bool

Check if a sound is currently playing

=head2 SetSoundVolume( $sound, $volume )

Set volume for a sound (1.0 is max level)

=head2 SetSoundPitch( $sound, $pitch )

Set pitch for a sound (1.0 is base level)

=head2 SetSoundPan( $sound, $pan )

Set pan for a sound (0.5 is center)

=head2 WaveCopy( $wave ) : Raylib::FFI::Wave

Copy a wave to a new wave

=head2 WaveCrop( $wave, $initFrame, $finalFrame )

Crop a wave to defined samples range

=head2 WaveFormat( $wave, $sampleRate, $sampleSize, $channels )

Convert wave data to desired format

=head2 LoadWaveSamples( $wave ) : float*

Load samples data from wave as a 32bit float array

=head2 UnloadWaveSamples( $samples )

Unload samples data loaded with LoadWaveSamples()

=head2 LoadMusicStream( $fileName ) : Raylib::FFI::Music

Load music stream from file

=head2 LoadMusicStreamFromMemory( $fileType, $data, $dataSize ) : Raylib::FFI::Music

Load music stream from data

=head2 IsMusicReady( $music ) : bool

Check if music stream is ready

=head2 UnloadMusicStream( $music )

Unload music stream

=head2 PlayMusicStream( $music )

Start music playing

=head2 IsMusicStreamPlaying( $music ) : bool

Check if music is playing

=head2 UpdateMusicStream( $music )

Update buffers for music streaming

=head2 StopMusicStream( $music )

Stop music playing

=head2 PauseMusicStream( $music )

Pause music playing

=head2 ResumeMusicStream( $music )

Resume music playing

=head2 SeekMusicStream( $music, $position )

Seek music to a position (in seconds)

=head2 SetMusicVolume( $music, $volume )

Set volume for music (1.0 is max level)

=head2 SetMusicPitch( $music, $pitch )

Set pitch for a music (1.0 is base level)

=head2 SetMusicPan( $music, $pan )

Set pan for a music (0.5 is center)

=head2 GetMusicTimeLength( $music ) : float

Get music time length (in seconds)

=head2 GetMusicTimePlayed( $music ) : float

Get current music time played (in seconds)

=head2 LoadAudioStream( $sampleRate, $sampleSize, $channels ) : Raylib::FFI::AudioStream

Load audio stream (to stream raw audio pcm data)

=head2 IsAudioStreamReady( $audioStream ) : bool

Check if an audio stream is ready

=head2 UnloadAudioStream( $audioStream )

Unload audio stream

=head2 UpdateAudioStream( $audioStream, $data, $frameCount )

Update audio stream buffers with data

=head2 IsAudioStreamProcessed( $audioStream ) : bool

Check if any audio stream buffers requires refill

=head2 PlayAudioStream( $audioStream )

Play audio stream

=head2 PauseAudioStream( $audioStream )

Pause audio stream

=head2 ResumeAudioStream( $audioStream )

Resume audio stream

=head2 IsAudioStreamPlaying( $audioStream ) : bool

Check if audio stream is playing

=head2 StopAudioStream( $audioStream )

Stop audio stream

=head2 SetAudioStreamVolume( $audioStream, $volume )

Set volume for audio stream (1.0 is max level)

=head2 SetAudioStreamPitch( $audioStream, $pitch )

Set pitch for audio stream (1.0 is base level)

=head2 SetAudioStreamPan( $audioStream, $pan )

Set pan for audio stream (0.5 is center)

=head2 SetAudioStreamBufferSizeDefault( $size )

Default size for new audio streams

=head1 KNOWN ISSUES

Also, this module was put together very quickly, and it's not very well tested.
There may be differences between the documentation and the underlying library.
The library is correct, please let me know if you find any issues.

=head1 SEE ALSO

L<http://www.raylib.com>

L<Graphics::Raylib>

L<Alien::raylib>

=head1 AUTHOR

Chris Prather <chris@prather.org>

Based on the work of:

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 RAYLIB LICENSE

This is an unofficial wrapper of L<http://www.raylib.com>.

raylib is Copyright (c) 2013-2016 Ramon Santamaria and available under the
terms of the zlib/libpng license. Refer to
L<LICENSE|https://github.com/raysan5/raylib/blob/5.0/LICENSE> for full terms.

=cut
