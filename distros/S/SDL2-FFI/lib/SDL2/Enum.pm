package SDL2::Enum {
    use lib '../../lib';
    use strictures 2;
    use experimental 'signatures';
    use SDL2::Utils;

    # https://github.com/libsdl-org/SDL/blob/main/include/SDL.h
    define init => [
        [ SDL_INIT_TIMER          => 0x00000001 ],
        [ SDL_INIT_AUDIO          => 0x00000010 ],
        [ SDL_INIT_VIDEO          => 0x00000020 ],
        [ SDL_INIT_JOYSTICK       => 0x00000200 ],
        [ SDL_INIT_HAPTIC         => 0x00001000 ],
        [ SDL_INIT_GAMECONTROLLER => 0x00002000 ],
        [ SDL_INIT_EVENTS         => 0x00004000 ],
        [ SDL_INIT_SENSOR         => 0x00008000 ],
        [ SDL_INIT_NOPARACHUTE    => 0x00100000 ],
        [   SDL_INIT_EVERYTHING => sub {
                SDL2::FFI::SDL_INIT_TIMER() | SDL2::FFI::SDL_INIT_AUDIO()
                    | SDL2::FFI::SDL_INIT_VIDEO() | SDL2::FFI::SDL_INIT_EVENTS()
                    | SDL2::FFI::SDL_INIT_JOYSTICK() | SDL2::FFI::SDL_INIT_HAPTIC()
                    | SDL2::FFI::SDL_INIT_GAMECONTROLLER() | SDL2::FFI::SDL_INIT_SENSOR();
            }
        ]
    ];

    # https://github.com/libsdl-org/SDL/blob/main/include/SDL_audio.h
    define audioformat => [
        [ SDL_AUDIO_MASK_BITSIZE   => 0xFF ],
        [ SDL_AUDIO_MASK_DATATYPE  => ( 1 << 8 ) ],
        [ SDL_AUDIO_MASK_ENDIAN    => ( 1 << 12 ) ],
        [ SDL_AUDIO_MASK_SIGNED    => ( 1 << 15 ) ],
        [ SDL_AUDIO_BITSIZE        => sub ($x) { $x & SDL_AUDIO_MASK_BITSIZE() } ],
        [ SDL_AUDIO_ISFLOAT        => sub ($x) { $x & SDL_AUDIO_MASK_DATATYPE() } ],
        [ SDL_AUDIO_ISBIGENDIAN    => sub ($x) { $x & SDL_AUDIO_MASK_ENDIAN() } ],
        [ SDL_AUDIO_ISSIGNED       => sub ($x) { $x & SDL_AUDIO_MASK_SIGNED() } ],
        [ SDL_AUDIO_ISINT          => sub ($x) { !SDL_AUDIO_ISFLOAT($x) } ],
        [ SDL_AUDIO_ISLITTLEENDIAN => sub ($x) { !SDL_AUDIO_ISBIGENDIAN($x) } ],
        [ SDL_AUDIO_ISUNSIGNED     => sub ($x) { !SDL_AUDIO_ISSIGNED($x) } ],
        [ AUDIO_U8                 => 0x0008 ],
        [ AUDIO_S8                 => 0x8008 ],
        [ AUDIO_U16LSB             => 0x0010 ],
        [ AUDIO_S16LSB             => 0x8010 ],
        [ AUDIO_U16MSB             => 0x1010 ],
        [ AUDIO_S16MSB             => 0x9010 ],
        [ AUDIO_U16                => sub () { AUDIO_U16LSB() } ],
        [ AUDIO_S16                => sub () { AUDIO_S16LSB() } ],
        [ AUDIO_S32LSB             => 0x8020 ],
        [ AUDIO_S32MSB             => 0x9020 ],
        [ AUDIO_S32                => sub () { AUDIO_S32LSB() } ],
        [ AUDIO_F32LSB             => 0x8120 ],
        [ AUDIO_F32MSB             => 0x9120 ],
        [ AUDIO_F32                => sub () { AUDIO_F32LSB() } ], (
            SDL2::FFI::bigendian() ? (
                [ AUDIO_U16SYS => sub () { AUDIO_U16MSB() } ],
                [ AUDIO_S16SYS => sub () { AUDIO_S16MSB() } ],
                [ AUDIO_S32SYS => sub () { AUDIO_S32MSB() } ],
                [ AUDIO_F32SYS => sub () { AUDIO_F32MSB() } ]
                ) : (
                [ AUDIO_U16SYS => sub () { AUDIO_U16LSB() } ],
                [ AUDIO_S16SYS => sub () { AUDIO_S16LSB() } ],
                [ AUDIO_S32SYS => sub () { AUDIO_S32LSB() } ],
                [ AUDIO_F32SYS => sub () { AUDIO_F32LSB() } ],
                )
        ),
        [ SDL_AUDIO_ALLOW_FREQUENCY_CHANGE => sub () {0x00000001} ],
        [ SDL_AUDIO_ALLOW_FORMAT_CHANGE    => sub () {0x00000002} ],
        [ SDL_AUDIO_ALLOW_CHANNELS_CHANGE  => sub () {0x00000004} ],
        [ SDL_AUDIO_ALLOW_SAMPLES_CHANGE   => sub () {0x00000008} ],
        [   SDL_AUDIO_ALLOW_ANY_CHANGE => sub () {
                ( SDL_AUDIO_ALLOW_FREQUENCY_CHANGE() | SDL_AUDIO_ALLOW_FORMAT_CHANGE()
                        | SDL_AUDIO_ALLOW_CHANNELS_CHANGE() | SDL_AUDIO_ALLOW_SAMPLES_CHANGE() )
            }
        ],
        [ SDL_AUDIOCVT_MAX_FILTERS => 9 ]
    ];
    enum
        SDL_AudioStatus => [ [ SDL_AUDIO_STOPPED => 0 ], qw[SDL_AUDIO_PLAYING SDL_AUDIO_PAUSED] ],
        SDL_BlendMode   => [
        [ SDL_BLENDMODE_NONE    => 0x00000000 ],
        [ SDL_BLENDMODE_BLEND   => 0x00000001 ],
        [ SDL_BLENDMODE_ADD     => 0x00000002, ],
        [ SDL_BLENDMODE_MOD     => 0x00000004, ],
        [ SDL_BLENDMODE_MUL     => 0x00000008, ],
        [ SDL_BLENDMODE_INVALID => 0x7FFFFFFF ]
        ],
        SDL_BlendOperation => [
        [ SDL_BLENDOPERATION_ADD          => 0x1 ],
        [ SDL_BLENDOPERATION_SUBTRACT     => 0x2 ],
        [ SDL_BLENDOPERATION_REV_SUBTRACT => 0x3 ],
        [ SDL_BLENDOPERATION_MINIMUM      => 0x4 ],
        [ SDL_BLENDOPERATION_MAXIMUM      => 0x5 ]
        ],
        SDL_BlendFactor => [
        [ SDL_BLENDFACTOR_ZERO                => 0x1 ],
        [ SDL_BLENDFACTOR_ONE                 => 0x2 ],
        [ SDL_BLENDFACTOR_SRC_COLOR           => 0x3 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR => 0x4 ],
        [ SDL_BLENDFACTOR_SRC_ALPHA           => 0x5 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA => 0x6 ],
        [ SDL_BLENDFACTOR_DST_COLOR           => 0x7 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR => 0x8 ],
        [ SDL_BLENDFACTOR_DST_ALPHA           => 0x9 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA => 0xA ]
        ],
        SDL_errorcode => [
        qw[
            SDL_ENOMEM
            SDL_EFREAD
            SDL_EFWRITE
            SDL_EFSEEK
            SDL_UNSUPPORTED
            SDL_LASTERROR
        ]
        ];
    define eventstate  => [ [ SDL_RELEASED => 0 ], [ SDL_PRESSED => 1 ] ];
    enum SDL_EventType => [
        [ SDL_FIRSTEVENT => 0 ], [ SDL_QUIT => 0x100 ],

        # These application events have special meaning on iOS, see README-ios.md for details
        qw[SDL_APP_TERMINATING
            SDL_APP_LOWMEMORY
            SDL_APP_WILLENTERBACKGROUND
            SDL_APP_DIDENTERBACKGROUND
            SDL_APP_WILLENTERFOREGROUND
            SDL_APP_DIDENTERFOREGROUND],
        #
        'SDL_LOCALECHANGED',

        #Display events
        [ SDL_DISPLAYEVENT => 0x150 ],

        # Window events
        [ SDL_WINDOWEVENT => 0x200 ], 'SDL_SYSWMEVENT',

        # Keyboard events
        [ SDL_KEYDOWN => 0x300 ], qw[SDL_KEYUP
            SDL_TEXTEDITING
            SDL_TEXTINPUT
            SDL_KEYMAPCHANGED],

        # Mouse events
        [ SDL_MOUSEMOTION => 0x400 ], qw[SDL_MOUSEBUTTONDOWN
            SDL_MOUSEBUTTONUP
            SDL_MOUSEWHEEL],

        # Joystick events
        [ SDL_JOYAXISMOTION => 0x600 ], qw[SDL_JOYBALLMOTION
            SDL_JOYHATMOTION
            SDL_JOYBUTTONDOWN
            SDL_JOYBUTTONUP
            SDL_JOYDEVICEADDED
            SDL_JOYDEVICEREMOVED],

        # Game controller events
        [ SDL_CONTROLLERAXISMOTION => 0x650 ], qw[SDL_CONTROLLERBUTTONDOWN
            SDL_CONTROLLERBUTTONUP
            SDL_CONTROLLERDEVICEADDED
            SDL_CONTROLLERDEVICEREMOVED
            SDL_CONTROLLERDEVICEREMAPPED
            SDL_CONTROLLERTOUCHPADDOWN
            SDL_CONTROLLERTOUCHPADMOTION
            SDL_CONTROLLERTOUCHPADUP
            SDL_CONTROLLERSENSORUPDATE],

        # Touch events
        [ SDL_FINGERDOWN => 0x700 ], qw[SDL_FINGERUP
            SDL_FINGERMOTION],

        # Gesture events
        [ SDL_DOLLARGESTURE => 0x800 ], qw[SDL_DOLLARRECORD
            SDL_MULTIGESTURE],

        # Clipboard events
        [ SDL_CLIPBOARDUPDATE => 0x900 ],

        # Drag and drop events
        [ SDL_DROPFILE => 0x1000 ], qw[SDL_DROPTEXT
            SDL_DROPBEGIN
            SDL_DROPCOMPLETE],

        # Audio hotplug events
        [ SDL_AUDIODEVICEADDED => 0x1100 ], 'SDL_AUDIODEVICEREMOVED',

        # Sensor events
        [ SDL_SENSORUPDATE => 0x1200 ],

        # Render events
        [ SDL_RENDER_TARGETS_RESET => 0x2000 ], 'SDL_RENDER_DEVICE_RESET',

        # Events ::SDL_USEREVENT through ::SDL_LASTEVENT are for your use,
        # and should be allocated with SDL_RegisterEvents()
        [ SDL_USEREVENT => 0x8000 ],

        # This last event is only  for bounding internal arrays
        [ SDL_LASTEVENT => 0xFFFF ]
    ];
    define SDL_EventState =>
        [ [ SDL_QUERY => -1 ], [ SDL_IGNORE => 0 ], [ SDL_DISABLE => 0 ], [ SDL_ENABLE => 1 ] ];
    enum SDL_GameControllerType => [
        [ SDL_CONTROLLER_TYPE_UNKNOWN => 0 ], qw[
            SDL_CONTROLLER_TYPE_XBOX360
            SDL_CONTROLLER_TYPE_XBOXONE
            SDL_CONTROLLER_TYPE_PS3
            SDL_CONTROLLER_TYPE_PS4
            SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_PRO
            SDL_CONTROLLER_TYPE_VIRTUAL
            SDL_CONTROLLER_TYPE_PS5
        ]
        ],
        SDL_GameControllerBindType => [
        [ SDL_CONTROLLER_BINDTYPE_NONE => 0 ], qw[ SDL_CONTROLLER_BINDTYPE_BUTTON
            SDL_CONTROLLER_BINDTYPE_AXIS
            SDL_CONTROLLER_BINDTYPE_HAT]
        ],
        SDL_GameControllerAxis => [
        [ SDL_CONTROLLER_AXIS_INVALID => -1 ], qw[SDL_CONTROLLER_AXIS_LEFTX
            SDL_CONTROLLER_AXIS_LEFTY
            SDL_CONTROLLER_AXIS_RIGHTX
            SDL_CONTROLLER_AXIS_RIGHTY
            SDL_CONTROLLER_AXIS_TRIGGERLEFT
            SDL_CONTROLLER_AXIS_TRIGGERRIGHT
            SDL_CONTROLLER_AXIS_MAX]
        ],
        SDL_GameControllerButton => [
        [ SDL_CONTROLLER_BUTTON_INVALID => -1 ], qw[SDL_CONTROLLER_BUTTON_A
            SDL_CONTROLLER_BUTTON_B
            SDL_CONTROLLER_BUTTON_X
            SDL_CONTROLLER_BUTTON_Y
            SDL_CONTROLLER_BUTTON_BACK
            SDL_CONTROLLER_BUTTON_GUIDE
            SDL_CONTROLLER_BUTTON_START
            SDL_CONTROLLER_BUTTON_LEFTSTICK
            SDL_CONTROLLER_BUTTON_RIGHTSTICK
            SDL_CONTROLLER_BUTTON_LEFTSHOULDER
            SDL_CONTROLLER_BUTTON_RIGHTSHOULDER
            SDL_CONTROLLER_BUTTON_DPAD_UP
            SDL_CONTROLLER_BUTTON_DPAD_DOWN
            SDL_CONTROLLER_BUTTON_DPAD_LEFT
            SDL_CONTROLLER_BUTTON_DPAD_RIGHT
            SDL_CONTROLLER_BUTTON_MISC1
            SDL_CONTROLLER_BUTTON_PADDLE1
            SDL_CONTROLLER_BUTTON_PADDLE2
            SDL_CONTROLLER_BUTTON_PADDLE3
            SDL_CONTROLLER_BUTTON_PADDLE4
            SDL_CONTROLLER_BUTTON_TOUCHPAD
            SDL_CONTROLLER_BUTTON_MAX]
        ];
    define SDL_Haptic => [
        [ SDL_HAPTIC_CONSTANT      => ( 1 << 0 ) ],
        [ SDL_HAPTIC_SINE          => ( 1 << 1 ) ],
        [ SDL_HAPTIC_LEFTRIGHT     => ( 1 << 2 ) ],
        [ SDL_HAPTIC_TRIANGLE      => ( 1 << 3 ) ],
        [ SDL_HAPTIC_SAWTOOTHUP    => ( 1 << 4 ) ],
        [ SDL_HAPTIC_SAWTOOTHDOWN  => ( 1 << 5 ) ],
        [ SDL_HAPTIC_RAMP          => ( 1 << 6 ) ],
        [ SDL_HAPTIC_SPRING        => ( 1 << 7 ) ],
        [ SDL_HAPTIC_DAMPER        => ( 1 << 8 ) ],
        [ SDL_HAPTIC_INERTIA       => ( 1 << 9 ) ],
        [ SDL_HAPTIC_FRICTION      => ( 1 << 10 ) ],
        [ SDL_HAPTIC_CUSTOM        => ( 1 << 11 ) ],
        [ SDL_HAPTIC_GAIN          => ( 1 << 12 ) ],
        [ SDL_HAPTIC_AUTOCENTER    => ( 1 << 13 ) ],
        [ SDL_HAPTIC_STATUS        => ( 1 << 14 ) ],
        [ SDL_HAPTIC_PAUSE         => ( 1 << 15 ) ],
        [ SDL_HAPTIC_POLAR         => 0 ],
        [ SDL_HAPTIC_CARTESIAN     => 1 ],
        [ SDL_HAPTIC_SPHERICAL     => 2 ],
        [ SDL_HAPTIC_STEERING_AXIS => 3 ],
        [ SDL_HAPTIC_INFINITY      => 4294967295 ]
    ];

    # https://github.com/libsdl-org/SDL/blob/main/include/SDL_hints.h
    enum SDL_HintPriority => [qw[SDL_HINT_DEFAULT SDL_HINT_NORMAL SDL_HINT_OVERRIDE]];
    define SDL_Hint       => [
        [ SDL_HINT_ACCELEROMETER_AS_JOYSTICK   => 'SDL_ACCELEROMETER_AS_JOYSTICK' ],
        [ SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED => 'SDL_ALLOW_ALT_TAB_WHILE_GRABBED' ],
        [ SDL_HINT_ALLOW_TOPMOST               => 'SDL_ALLOW_TOPMOST' ],
        [   SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION =>
                'SDL_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION'
        ],
        [   SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION =>
                'SDL_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION'
        ],
        [ SDL_HINT_ANDROID_BLOCK_ON_PAUSE            => 'SDL_ANDROID_BLOCK_ON_PAUSE' ],
        [ SDL_HINT_ANDROID_BLOCK_ON_PAUSE_PAUSEAUDIO => 'SDL_ANDROID_BLOCK_ON_PAUSE_PAUSEAUDIO' ],
        [ SDL_HINT_ANDROID_SEPARATE_MOUSE_AND_TOUCH  => 'SDL_ANDROID_SEPARATE_MOUSE_AND_TOUCH' ],
        [ SDL_HINT_ANDROID_TRAP_BACK_BUTTON          => 'SDL_ANDROID_TRAP_BACK_BUTTON' ],
        [ SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS     => 'SDL_APPLE_TV_CONTROLLER_UI_EVENTS' ],
        [ SDL_HINT_APPLE_TV_REMOTE_ALLOW_ROTATION    => 'SDL_APPLE_TV_REMOTE_ALLOW_ROTATION' ],
        [ SDL_HINT_AUDIO_CATEGORY                    => 'SDL_AUDIO_CATEGORY' ],
        [ SDL_HINT_AUDIO_DEVICE_APP_NAME             => 'SDL_AUDIO_DEVICE_APP_NAME' ],
        [ SDL_HINT_AUDIO_DEVICE_STREAM_NAME          => 'SDL_AUDIO_DEVICE_STREAM_NAME' ],
        [ SDL_HINT_AUDIO_DEVICE_STREAM_ROLE          => 'SDL_AUDIO_DEVICE_STREAM_ROLE' ],
        [ SDL_HINT_AUDIO_RESAMPLING_MODE             => 'SDL_AUDIO_RESAMPLING_MODE' ],
        [ SDL_HINT_AUTO_UPDATE_JOYSTICKS             => 'SDL_AUTO_UPDATE_JOYSTICKS' ],
        [ SDL_HINT_AUTO_UPDATE_SENSORS               => 'SDL_AUTO_UPDATE_SENSORS' ],
        [ SDL_HINT_BMP_SAVE_LEGACY_FORMAT            => 'SDL_BMP_SAVE_LEGACY_FORMAT' ],
        [ SDL_HINT_DISPLAY_USABLE_BOUNDS             => 'SDL_DISPLAY_USABLE_BOUNDS' ],
        [ SDL_HINT_EMSCRIPTEN_ASYNCIFY               => 'SDL_EMSCRIPTEN_ASYNCIFY' ],
        [ SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT       => 'SDL_EMSCRIPTEN_KEYBOARD_ELEMENT' ],
        [ SDL_HINT_ENABLE_STEAM_CONTROLLERS          => 'SDL_ENABLE_STEAM_CONTROLLERS' ],
        [ SDL_HINT_EVENT_LOGGING                     => 'SDL_EVENT_LOGGING' ],
        [ SDL_HINT_FRAMEBUFFER_ACCELERATION          => 'SDL_FRAMEBUFFER_ACCELERATION' ],
        [ SDL_HINT_GAMECONTROLLERCONFIG              => 'SDL_GAMECONTROLLERCONFIG' ],
        [ SDL_HINT_GAMECONTROLLERCONFIG_FILE         => 'SDL_GAMECONTROLLERCONFIG_FILE' ],
        [ SDL_HINT_GAMECONTROLLERTYPE                => 'SDL_GAMECONTROLLERTYPE' ],
        [ SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES     => 'SDL_GAMECONTROLLER_IGNORE_DEVICES' ],
        [   SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT =>
                'SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT'
        ],
        [ SDL_HINT_GAMECONTROLLER_USE_BUTTON_LABELS   => 'SDL_GAMECONTROLLER_USE_BUTTON_LABELS' ],
        [ SDL_HINT_GRAB_KEYBOARD                      => 'SDL_GRAB_KEYBOARD' ],
        [ SDL_HINT_IDLE_TIMER_DISABLED                => 'SDL_IDLE_TIMER_DISABLED' ],
        [ SDL_HINT_IME_INTERNAL_EDITING               => 'SDL_IME_INTERNAL_EDITING' ],
        [ SDL_HINT_IOS_HIDE_HOME_INDICATOR            => 'SDL_IOS_HIDE_HOME_INDICATOR' ],
        [ SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS   => 'SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS' ],
        [ SDL_HINT_JOYSTICK_HIDAPI                    => 'SDL_JOYSTICK_HIDAPI' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_CORRELATE_XINPUT   => 'SDL_JOYSTICK_HIDAPI_CORRELATE_XINPUT' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_GAMECUBE           => 'SDL_JOYSTICK_HIDAPI_GAMECUBE' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_JOY_CONS           => 'SDL_JOYSTICK_HIDAPI_JOY_CONS' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_PS4                => 'SDL_JOYSTICK_HIDAPI_PS4' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE         => 'SDL_JOYSTICK_HIDAPI_PS4_RUMBLE' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_PS5                => 'SDL_JOYSTICK_HIDAPI_PS5' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED     => 'SDL_JOYSTICK_HIDAPI_PS5_PLAYER_LED' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE         => 'SDL_JOYSTICK_HIDAPI_PS5_RUMBLE' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_STADIA             => 'SDL_JOYSTICK_HIDAPI_STADIA' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_STEAM              => 'SDL_JOYSTICK_HIDAPI_STEAM' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_SWITCH             => 'SDL_JOYSTICK_HIDAPI_SWITCH' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_SWITCH_HOME_LED    => 'SDL_JOYSTICK_HIDAPI_SWITCH_HOME_LED' ],
        [ SDL_HINT_JOYSTICK_HIDAPI_XBOX               => 'SDL_JOYSTICK_HIDAPI_XBOX' ],
        [ SDL_HINT_JOYSTICK_RAWINPUT                  => 'SDL_JOYSTICK_RAWINPUT' ],
        [ SDL_HINT_JOYSTICK_THREAD                    => 'SDL_JOYSTICK_THREAD' ],
        [ SDL_HINT_KMSDRM_REQUIRE_DRM_MASTER          => 'SDL_KMSDRM_REQUIRE_DRM_MASTER' ],
        [ SDL_HINT_LINUX_JOYSTICK_DEADZONES           => 'SDL_LINUX_JOYSTICK_DEADZONES' ],
        [ SDL_HINT_MAC_BACKGROUND_APP                 => 'SDL_MAC_BACKGROUND_APP' ],
        [ SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK => 'SDL_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK' ],
        [ SDL_HINT_MOUSE_DOUBLE_CLICK_RADIUS          => 'SDL_MOUSE_DOUBLE_CLICK_RADIUS' ],
        [ SDL_HINT_MOUSE_DOUBLE_CLICK_TIME            => 'SDL_MOUSE_DOUBLE_CLICK_TIME' ],
        [ SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH           => 'SDL_MOUSE_FOCUS_CLICKTHROUGH' ],
        [ SDL_HINT_MOUSE_NORMAL_SPEED_SCALE           => 'SDL_MOUSE_NORMAL_SPEED_SCALE' ],
        [ SDL_HINT_MOUSE_RELATIVE_MODE_WARP           => 'SDL_MOUSE_RELATIVE_MODE_WARP' ],
        [ SDL_HINT_MOUSE_RELATIVE_SCALING             => 'SDL_MOUSE_RELATIVE_SCALING' ],
        [ SDL_HINT_MOUSE_RELATIVE_SPEED_SCALE         => 'SDL_MOUSE_RELATIVE_SPEED_SCALE' ],
        [ SDL_HINT_MOUSE_TOUCH_EVENTS                 => 'SDL_MOUSE_TOUCH_EVENTS' ],
        [ SDL_HINT_NO_SIGNAL_HANDLERS                 => 'SDL_NO_SIGNAL_HANDLERS' ],
        [ SDL_HINT_OPENGL_ES_DRIVER                   => 'SDL_OPENGL_ES_DRIVER' ],
        [ SDL_HINT_ORIENTATIONS                       => 'SDL_ORIENTATIONS' ],
        [ SDL_HINT_PREFERRED_LOCALES                  => 'SDL_PREFERRED_LOCALES' ],
        [ SDL_HINT_QTWAYLAND_CONTENT_ORIENTATION      => 'SDL_QTWAYLAND_CONTENT_ORIENTATION' ],
        [ SDL_HINT_QTWAYLAND_WINDOW_FLAGS             => 'SDL_QTWAYLAND_WINDOW_FLAGS' ],
        [ SDL_HINT_RENDER_BATCHING                    => 'SDL_RENDER_BATCHING' ],
        [ SDL_HINT_RENDER_DIRECT3D11_DEBUG            => 'SDL_RENDER_DIRECT3D11_DEBUG' ],
        [ SDL_HINT_RENDER_DIRECT3D_THREADSAFE         => 'SDL_RENDER_DIRECT3D_THREADSAFE' ],
        [ SDL_HINT_RENDER_DRIVER                      => 'SDL_RENDER_DRIVER' ],
        [ SDL_HINT_RENDER_LOGICAL_SIZE_MODE           => 'SDL_RENDER_LOGICAL_SIZE_MODE' ],
        [ SDL_HINT_RENDER_OPENGL_SHADERS              => 'SDL_RENDER_OPENGL_SHADERS' ],
        [ SDL_HINT_RENDER_SCALE_QUALITY               => 'SDL_RENDER_SCALE_QUALITY' ],
        [ SDL_HINT_RENDER_VSYNC                       => 'SDL_RENDER_VSYNC' ],
        [ SDL_HINT_RETURN_KEY_HIDES_IME               => 'SDL_RETURN_KEY_HIDES_IME' ],
        [ SDL_HINT_RPI_VIDEO_LAYER                    => 'SDL_RPI_VIDEO_LAYER' ],
        [   SDL_HINT_THREAD_FORCE_REALTIME_TIME_CRITICAL =>
                'SDL_THREAD_FORCE_REALTIME_TIME_CRITICAL'
        ],
        [ SDL_HINT_THREAD_PRIORITY_POLICY             => 'SDL_THREAD_PRIORITY_POLICY' ],
        [ SDL_HINT_THREAD_STACK_SIZE                  => 'SDL_THREAD_STACK_SIZE' ],
        [ SDL_HINT_TIMER_RESOLUTION                   => 'SDL_TIMER_RESOLUTION' ],
        [ SDL_HINT_TOUCH_MOUSE_EVENTS                 => 'SDL_TOUCH_MOUSE_EVENTS' ],
        [ SDL_HINT_TV_REMOTE_AS_JOYSTICK              => 'SDL_TV_REMOTE_AS_JOYSTICK' ],
        [ SDL_HINT_VIDEO_ALLOW_SCREENSAVER            => 'SDL_VIDEO_ALLOW_SCREENSAVER' ],
        [ SDL_HINT_VIDEO_DOUBLE_BUFFER                => 'SDL_VIDEO_DOUBLE_BUFFER' ],
        [ SDL_HINT_VIDEO_EXTERNAL_CONTEXT             => 'SDL_VIDEO_EXTERNAL_CONTEXT' ],
        [ SDL_HINT_VIDEO_HIGHDPI_DISABLED             => 'SDL_VIDEO_HIGHDPI_DISABLED' ],
        [ SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES        => 'SDL_VIDEO_MAC_FULLSCREEN_SPACES' ],
        [ SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS       => 'SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS' ],
        [ SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT    => 'SDL_VIDEO_WINDOW_SHARE_PIXEL_FORMAT' ],
        [ SDL_HINT_VIDEO_WIN_D3DCOMPILE               => 'SDL_VIDEO_WIN_D3DCOMPILE' ],
        [ SDL_HINT_VIDEO_WIN_D3DCOMPILER              => 'SDL_VIDEO_WIN_D3DCOMPILER' ],
        [ SDL_HINT_VIDEO_X11_FORCE_EGL                => 'SDL_VIDEO_X11_FORCE_EGL' ],
        [ SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR => 'SDL_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR' ],
        [ SDL_HINT_VIDEO_X11_NET_WM_PING              => 'SDL_VIDEO_X11_NET_WM_PING' ],
        [ SDL_HINT_VIDEO_X11_WINDOW_VISUALID          => 'SDL_VIDEO_X11_WINDOW_VISUALID' ],
        [ SDL_HINT_VIDEO_X11_XINERAMA                 => 'SDL_VIDEO_X11_XINERAMA' ],
        [ SDL_HINT_VIDEO_X11_XRANDR                   => 'SDL_VIDEO_X11_XRANDR' ],
        [ SDL_HINT_VIDEO_X11_XVIDMODE                 => 'SDL_VIDEO_X11_XVIDMODE' ],
        [ SDL_HINT_WAVE_FACT_CHUNK                    => 'SDL_WAVE_FACT_CHUNK' ],
        [ SDL_HINT_WAVE_RIFF_CHUNK_SIZE               => 'SDL_WAVE_RIFF_CHUNK_SIZE' ],
        [ SDL_HINT_WAVE_TRUNCATION                    => 'SDL_WAVE_TRUNCATION' ],
        [ SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING      => 'SDL_WINDOWS_DISABLE_THREAD_NAMING' ],
        [ SDL_HINT_WINDOWS_ENABLE_MESSAGELOOP         => 'SDL_WINDOWS_ENABLE_MESSAGELOOP' ],
        [   SDL_HINT_WINDOWS_FORCE_MUTEX_CRITICAL_SECTIONS =>
                'SDL_WINDOWS_FORCE_MUTEX_CRITICAL_SECTIONS'
        ],
        [ SDL_HINT_WINDOWS_FORCE_SEMAPHORE_KERNEL => 'SDL_WINDOWS_FORCE_SEMAPHORE_KERNEL' ],
        [ SDL_HINT_WINDOWS_INTRESOURCE_ICON       => 'SDL_WINDOWS_INTRESOURCE_ICON' ],
        [ SDL_HINT_WINDOWS_INTRESOURCE_ICON_SMALL => 'SDL_WINDOWS_INTRESOURCE_ICON_SMALL' ],
        [ SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4     => 'SDL_WINDOWS_NO_CLOSE_ON_ALT_F4' ],
        [ SDL_HINT_WINDOWS_USE_D3D9EX             => 'SDL_WINDOWS_USE_D3D9EX' ],
        [   SDL_HINT_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN =>
                'SDL_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN'
        ],
        [ SDL_HINT_WINRT_HANDLE_BACK_BUTTON        => 'SDL_WINRT_HANDLE_BACK_BUTTON' ],
        [ SDL_HINT_WINRT_PRIVACY_POLICY_LABEL      => 'SDL_WINRT_PRIVACY_POLICY_LABEL' ],
        [ SDL_HINT_WINRT_PRIVACY_POLICY_URL        => 'SDL_WINRT_PRIVACY_POLICY_URL' ],
        [ SDL_HINT_XINPUT_ENABLED                  => 'SDL_XINPUT_ENABLED' ],
        [ SDL_HINT_XINPUT_USE_OLD_JOYSTICK_MAPPING => 'SDL_XINPUT_USE_OLD_JOYSTICK_MAPPING' ]
    ];
    enum SDL_JoystickType => [
        qw[
            SDL_JOYSTICK_TYPE_UNKNOWN
            SDL_JOYSTICK_TYPE_GAMECONTROLLER
            SDL_JOYSTICK_TYPE_WHEEL
            SDL_JOYSTICK_TYPE_ARCADE_STICK
            SDL_JOYSTICK_TYPE_FLIGHT_STICK
            SDL_JOYSTICK_TYPE_DANCE_PAD
            SDL_JOYSTICK_TYPE_GUITAR
            SDL_JOYSTICK_TYPE_DRUM_KIT
            SDL_JOYSTICK_TYPE_ARCADE_PAD
            SDL_JOYSTICK_TYPE_THROTTLE
        ]
        ],
        SDL_JoystickPowerLevel => [
        [ SDL_JOYSTICK_POWER_UNKNOWN => -1 ], qw[SDL_JOYSTICK_POWER_EMPTY
            SDL_JOYSTICK_POWER_LOW
            SDL_JOYSTICK_POWER_MEDIUM
            SDL_JOYSTICK_POWER_FULL
            SDL_JOYSTICK_POWER_WIRED
            SDL_JOYSTICK_POWER_MAX]
        ];
    define hatPositoin => [
        [ SDL_HAT_CENTERED  => 0x00 ],
        [ SDL_HAT_UP        => 0x01 ],
        [ SDL_HAT_RIGHT     => 0x02 ],
        [ SDL_HAT_DOWN      => 0x04 ],
        [ SDL_HAT_LEFT      => 0x08 ],
        [ SDL_HAT_RIGHTUP   => sub () { ( SDL_HAT_RIGHT() | SDL_HAT_UP() ) } ],
        [ SDL_HAT_RIGHTDOWN => sub () { ( SDL_HAT_RIGHT() | SDL_HAT_DOWN() ) } ],
        [ SDL_HAT_LEFTUP    => sub () { ( SDL_HAT_LEFT() | SDL_HAT_UP() ) } ],
        [ SDL_HAT_LEFTDOWN  => sub () { ( SDL_HAT_LEFT() | SDL_HAT_DOWN() ) } ]
    ];
    define SDL_KeyCode => [
        [ SDLK_SCANCODE_MASK      => ( 1 << 30 ) ],
        [ SDL_SCANCODE_TO_KEYCODE => sub ($X) { ( $X | SDLK_SCANCODE_MASK() ) } ],
        [ SDLK_UNKNOWN   => 0 ],        [ SDLK_RETURN  => ord "\r" ], [ SDLK_ESCAPE => ord "\x1B" ],
        [ SDLK_BACKSPACE => ord "\b" ], [ SDLK_TAB     => ord "\t" ], [ SDLK_SPACE  => ord ' ' ],
        [ SDLK_EXCLAIM  => ord '!' ], [ SDLK_QUOTEDBL  => ord '"' ], [ SDLK_HASH       => ord '#' ],
        [ SDLK_PERCENT  => ord '%' ], [ SDLK_DOLLAR    => ord '$' ], [ SDLK_AMPERSAND  => ord '&' ],
        [ SDLK_QUOTE    => ord "'" ], [ SDLK_LEFTPAREN => ord '(' ], [ SDLK_RIGHTPAREN => ord ')' ],
        [ SDLK_ASTERISK => ord '*' ], [ SDLK_PLUS      => ord '+' ], [ SDLK_COMMA      => ord ',' ],
        [ SDLK_MINUS    => ord '-' ], [ SDLK_PERIOD    => ord '.' ], [ SDLK_SLASH      => ord '/' ],
        [ SDLK_0 => ord '0' ], [ SDLK_1 => ord '1' ], [ SDLK_2 => ord '2' ], [ SDLK_3 => ord '3' ],
        [ SDLK_4 => ord '4' ], [ SDLK_5 => ord '5' ], [ SDLK_6 => ord '6' ], [ SDLK_7 => ord '7' ],
        [ SDLK_8         => ord '8' ], [ SDLK_9        => ord '9' ], [ SDLK_COLON  => ord ':' ],
        [ SDLK_SEMICOLON => ord ';' ], [ SDLK_LESS     => ord '<' ], [ SDLK_EQUALS => ord '=' ],
        [ SDLK_GREATER   => ord '>' ], [ SDLK_QUESTION => ord '?' ], [ SDLK_AT     => ord '@' ],

        # Skip uppercase letters
        [ SDLK_LEFTBRACKET  => ord '[' ],
        [ SDLK_BACKSLASH    => ord "\\" ],
        [ SDLK_RIGHTBRACKET => ord ']' ],
        [ SDLK_CARET        => ord '^' ],
        [ SDLK_UNDERSCORE   => ord '_' ],
        [ SDLK_BACKQUOTE    => ord '`' ],
        [ SDLK_a            => ord 'a' ],
        [ SDLK_b            => ord 'b' ],
        [ SDLK_c            => ord 'c' ],
        [ SDLK_d            => ord 'd' ],
        [ SDLK_e            => ord 'e' ],
        [ SDLK_f            => ord 'f' ],
        [ SDLK_g            => ord 'g' ],
        [ SDLK_h            => ord 'h' ],
        [ SDLK_i            => ord 'i' ],
        [ SDLK_j            => ord 'j' ],
        [ SDLK_k            => ord 'k' ],
        [ SDLK_l            => ord 'l' ],
        [ SDLK_m            => ord 'm' ],
        [ SDLK_n            => ord 'n' ],
        [ SDLK_o            => ord 'o' ],
        [ SDLK_p            => ord 'p' ],
        [ SDLK_q            => ord 'q' ],
        [ SDLK_r            => ord 'r' ],
        [ SDLK_s            => ord 's' ],
        [ SDLK_t            => ord 't' ],
        [ SDLK_u            => ord 'u' ],
        [ SDLK_v            => ord 'v' ],
        [ SDLK_w            => ord 'w' ],
        [ SDLK_x            => ord 'x' ],
        [ SDLK_y            => ord 'y' ],
        [ SDLK_z            => ord 'z' ],
        [ SDLK_CAPSLOCK     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CAPSLOCK() ) } ],
        [ SDLK_F1           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F1() ) } ],
        [ SDLK_F2           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F2() ) } ],
        [ SDLK_F3           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F3() ) } ],
        [ SDLK_F4           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F4() ) } ],
        [ SDLK_F5           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F5() ) } ],
        [ SDLK_F6           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F6() ) } ],
        [ SDLK_F7           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F7() ) } ],
        [ SDLK_F8           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F8() ) } ],
        [ SDLK_F9           => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F9() ) } ],
        [ SDLK_F10          => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F10() ) } ],
        [ SDLK_F11          => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F11() ) } ],
        [ SDLK_F12          => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F12() ) } ],
        [   SDLK_PRINTSCREEN => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_PRINTSCREEN() ) }
        ],
        [ SDLK_SCROLLLOCK => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_SCROLLLOCK() ) } ],
        [ SDLK_PAUSE      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_PAUSE() ) } ],
        [ SDLK_INSERT     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_INSERT() ) } ],
        [ SDLK_HOME       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_HOME() ) } ],
        [ SDLK_PAGEUP     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_PAGEUP() ) } ],
        [ SDLK_DELETE     => ord "\x7F" ],
        [ SDLK_END        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_END() ) } ],
        [ SDLK_PAGEDOWN   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_PAGEDOWN() ) } ],
        [ SDLK_RIGHT      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_RIGHT() ) } ],
        [ SDLK_LEFT       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_LEFT() ) } ],
        [ SDLK_DOWN       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_DOWN() ) } ],
        [ SDLK_UP         => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_UP() ) } ],
        [   SDLK_NUMLOCKCLEAR =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_NUMLOCKCLEAR() ) }
        ],
        [ SDLK_KP_DIVIDE => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_DIVIDE() ) } ],
        [   SDLK_KP_MULTIPLY => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MULTIPLY() ) }
        ],
        [ SDLK_KP_MINUS  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MINUS() ) } ],
        [ SDLK_KP_PLUS   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_PLUS() ) } ],
        [ SDLK_KP_ENTER  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_ENTER() ) } ],
        [ SDLK_KP_1      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_1() ) } ],
        [ SDLK_KP_2      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_2() ) } ],
        [ SDLK_KP_3      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_3() ) } ],
        [ SDLK_KP_4      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_4() ) } ],
        [ SDLK_KP_5      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_5() ) } ],
        [ SDLK_KP_6      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_6() ) } ],
        [ SDLK_KP_7      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_7() ) } ],
        [ SDLK_KP_8      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_8() ) } ],
        [ SDLK_KP_9      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_9() ) } ],
        [ SDLK_KP_0      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_0() ) } ],
        [ SDLK_KP_PERIOD => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_PERIOD() ) } ],
        [   SDLK_APPLICATION => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_APPLICATION() ) }
        ],
        [ SDLK_POWER      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_POWER() ) } ],
        [ SDLK_KP_EQUALS  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_EQUALS() ) } ],
        [ SDLK_F13        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F13() ) } ],
        [ SDLK_F14        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F14() ) } ],
        [ SDLK_F15        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F15() ) } ],
        [ SDLK_F16        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F16() ) } ],
        [ SDLK_F17        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F17() ) } ],
        [ SDLK_F18        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F18() ) } ],
        [ SDLK_F19        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F19() ) } ],
        [ SDLK_F20        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F20() ) } ],
        [ SDLK_F21        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F21() ) } ],
        [ SDLK_F22        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F22() ) } ],
        [ SDLK_F23        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F23() ) } ],
        [ SDLK_F24        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_F24() ) } ],
        [ SDLK_EXECUTE    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_EXECUTE() ) } ],
        [ SDLK_HELP       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_HELP() ) } ],
        [ SDLK_MENU       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_MENU() ) } ],
        [ SDLK_SELECT     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_SELECT() ) } ],
        [ SDLK_STOP       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_STOP() ) } ],
        [ SDLK_AGAIN      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AGAIN() ) } ],
        [ SDLK_UNDO       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_UNDO() ) } ],
        [ SDLK_CUT        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CUT() ) } ],
        [ SDLK_COPY       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_COPY() ) } ],
        [ SDLK_PASTE      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_PASTE() ) } ],
        [ SDLK_FIND       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_FIND() ) } ],
        [ SDLK_MUTE       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_MUTE() ) } ],
        [ SDLK_VOLUMEUP   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_VOLUMEUP() ) } ],
        [ SDLK_VOLUMEDOWN => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_VOLUMEDOWN() ) } ],
        [ SDLK_KP_COMMA   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_COMMA() ) } ],
        [   SDLK_KP_EQUALSAS400 => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_EQUALSAS400() );
            }
        ],
        [ SDLK_ALTERASE   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_ALTERASE() ) } ],
        [ SDLK_SYSREQ     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_SYSREQ() ) } ],
        [ SDLK_CANCEL     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CANCEL() ) } ],
        [ SDLK_CLEAR      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CLEAR() ) } ],
        [ SDLK_PRIOR      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_PRIOR() ) } ],
        [ SDLK_RETURN2    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_RETURN2() ) } ],
        [ SDLK_SEPARATOR  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_SEPARATOR() ) } ],
        [ SDLK_OUT        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_OUT() ) } ],
        [ SDLK_OPER       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_OPER() ) } ],
        [ SDLK_CLEARAGAIN => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CLEARAGAIN() ) } ],
        [ SDLK_CRSEL      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CRSEL() ) } ],
        [ SDLK_EXSEL      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_EXSEL() ) } ],
        [ SDLK_KP_00      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_00() ) } ],
        [ SDLK_KP_000     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_000() ) } ],
        [   SDLK_THOUSANDSSEPARATOR => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_THOUSANDSSEPARATOR() );
            }
        ],
        [   SDLK_DECIMALSEPARATOR => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_DECIMALSEPARATOR() );
            }
        ],
        [   SDLK_CURRENCYUNIT =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CURRENCYUNIT() ) }
        ],
        [   SDLK_CURRENCYSUBUNIT => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CURRENCYSUBUNIT() );
            }
        ],
        [   SDLK_KP_LEFTPAREN =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_LEFTPAREN() ) }
        ],
        [   SDLK_KP_RIGHTPAREN =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_RIGHTPAREN() ) }
        ],
        [   SDLK_KP_LEFTBRACE =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_LEFTBRACE() ) }
        ],
        [   SDLK_KP_RIGHTBRACE =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_RIGHTBRACE() ) }
        ],
        [ SDLK_KP_TAB => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_TAB() ) } ],
        [   SDLK_KP_BACKSPACE =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_BACKSPACE() ) }
        ],
        [ SDLK_KP_A       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_A() ) } ],
        [ SDLK_KP_B       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_B() ) } ],
        [ SDLK_KP_C       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_C() ) } ],
        [ SDLK_KP_D       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_D() ) } ],
        [ SDLK_KP_E       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_E() ) } ],
        [ SDLK_KP_F       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_F() ) } ],
        [ SDLK_KP_XOR     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_XOR() ) } ],
        [ SDLK_KP_POWER   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_POWER() ) } ],
        [ SDLK_KP_PERCENT => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_PERCENT() ) } ],
        [ SDLK_KP_LESS    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_LESS() ) } ],
        [ SDLK_KP_GREATER => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_GREATER() ) } ],
        [   SDLK_KP_AMPERSAND =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_AMPERSAND() ) }
        ],
        [   SDLK_KP_DBLAMPERSAND => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_DBLAMPERSAND() );
            }
        ],
        [   SDLK_KP_VERTICALBAR => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_VERTICALBAR() );
            }
        ],
        [   SDLK_KP_DBLVERTICALBAR => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_DBLVERTICALBAR() );
            }
        ],
        [ SDLK_KP_COLON  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_COLON() ) } ],
        [ SDLK_KP_HASH   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_HASH() ) } ],
        [ SDLK_KP_SPACE  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_SPACE() ) } ],
        [ SDLK_KP_AT     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_AT() ) } ],
        [ SDLK_KP_EXCLAM => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_EXCLAM() ) } ],
        [   SDLK_KP_MEMSTORE => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MEMSTORE() ) }
        ],
        [   SDLK_KP_MEMRECALL =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MEMRECALL() ) }
        ],
        [   SDLK_KP_MEMCLEAR => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MEMCLEAR() ) }
        ],
        [ SDLK_KP_MEMADD => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MEMADD() ) } ],
        [   SDLK_KP_MEMSUBTRACT => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MEMSUBTRACT() );
            }
        ],
        [   SDLK_KP_MEMMULTIPLY => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MEMMULTIPLY() );
            }
        ],
        [   SDLK_KP_MEMDIVIDE =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_MEMDIVIDE() ) }
        ],
        [   SDLK_KP_PLUSMINUS =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_PLUSMINUS() ) }
        ],
        [ SDLK_KP_CLEAR => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_CLEAR() ) } ],
        [   SDLK_KP_CLEARENTRY =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_CLEARENTRY() ) }
        ],
        [ SDLK_KP_BINARY  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_BINARY() ) } ],
        [ SDLK_KP_OCTAL   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_OCTAL() ) } ],
        [ SDLK_KP_DECIMAL => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_DECIMAL() ) } ],
        [   SDLK_KP_HEXADECIMAL => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KP_HEXADECIMAL() );
            }
        ],
        [ SDLK_LCTRL     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_LCTRL() ) } ],
        [ SDLK_LSHIFT    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_LSHIFT() ) } ],
        [ SDLK_LALT      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_LALT() ) } ],
        [ SDLK_LGUI      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_LGUI() ) } ],
        [ SDLK_RCTRL     => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_RCTRL() ) } ],
        [ SDLK_RSHIFT    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_RSHIFT() ) } ],
        [ SDLK_RALT      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_RALT() ) } ],
        [ SDLK_RGUI      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_RGUI() ) } ],
        [ SDLK_MODE      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_MODE() ) } ],
        [ SDLK_AUDIONEXT => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AUDIONEXT() ) } ],
        [ SDLK_AUDIOPREV => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AUDIOPREV() ) } ],
        [ SDLK_AUDIOSTOP => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AUDIOSTOP() ) } ],
        [ SDLK_AUDIOPLAY => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AUDIOPLAY() ) } ],
        [ SDLK_AUDIOMUTE => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AUDIOMUTE() ) } ],
        [   SDLK_MEDIASELECT => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_MEDIASELECT() ) }
        ],
        [ SDLK_WWW        => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_WWW() ) } ],
        [ SDLK_MAIL       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_MAIL() ) } ],
        [ SDLK_CALCULATOR => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_CALCULATOR() ) } ],
        [ SDLK_COMPUTER   => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_COMPUTER() ) } ],
        [ SDLK_AC_SEARCH  => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AC_SEARCH() ) } ],
        [ SDLK_AC_HOME    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AC_HOME() ) } ],
        [ SDLK_AC_BACK    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AC_BACK() ) } ],
        [ SDLK_AC_FORWARD => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AC_FORWARD() ) } ],
        [ SDLK_AC_STOP    => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AC_STOP() ) } ],
        [ SDLK_AC_REFRESH => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AC_REFRESH() ) } ],
        [   SDLK_AC_BOOKMARKS =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AC_BOOKMARKS() ) }
        ],
        [   SDLK_BRIGHTNESSDOWN => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_BRIGHTNESSDOWN() );
            }
        ],
        [   SDLK_BRIGHTNESSUP =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_BRIGHTNESSUP() ) }
        ],
        [   SDLK_DISPLAYSWITCH =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_DISPLAYSWITCH() ) }
        ],
        [   SDLK_KBDILLUMTOGGLE => sub () {
                ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KBDILLUMTOGGLE() );
            }
        ],
        [   SDLK_KBDILLUMDOWN =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KBDILLUMDOWN() ) }
        ],
        [ SDLK_KBDILLUMUP => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_KBDILLUMUP() ) } ],
        [ SDLK_EJECT      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_EJECT() ) } ],
        [ SDLK_SLEEP      => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_SLEEP() ) } ],
        [ SDLK_APP1       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_APP1() ) } ],
        [ SDLK_APP2       => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_APP2() ) } ],
        [   SDLK_AUDIOREWIND => sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AUDIOREWIND() ) }
        ],
        [   SDLK_AUDIOFASTFORWARD =>
                sub () { ord SDL_SCANCODE_TO_KEYCODE( SDL_SCANCODE_AUDIOFASTFORWARD() ) }
        ]
    ];
    enum SDL_Keymod => [
        [ KMOD_NONE     => 0x0000 ],
        [ KMOD_LSHIFT   => 0x0001 ],
        [ KMOD_RSHIFT   => 0x0002 ],
        [ KMOD_LCTRL    => 0x0040 ],
        [ KMOD_RCTRL    => 0x0080 ],
        [ KMOD_LALT     => 0x0100 ],
        [ KMOD_RALT     => 0x0200 ],
        [ KMOD_LGUI     => 0x0400 ],
        [ KMOD_RGUI     => 0x0800 ],
        [ KMOD_NUM      => 0x1000 ],
        [ KMOD_CAPS     => 0x2000 ],
        [ KMOD_MODE     => 0x4000 ],
        [ KMOD_RESERVED => 0x8000 ],
        [ KMOD_CTRL     => sub () { KMOD_LCTRL() | KMOD_RCTRL() } ],
        [ KMOD_SHIFT    => sub () { KMOD_LSHIFT() | KMOD_RSHIFT() } ],
        [ KMOD_ALT      => sub () { KMOD_LALT() | KMOD_RALT() } ],
        [ KMOD_GUI      => sub () { KMOD_LGUI() | KMOD_RGUI() } ]
    ];
    enum SDL_LogCategory => [
        qw[
            SDL_LOG_CATEGORY_APPLICATION SDL_LOG_CATEGORY_ERROR SDL_LOG_CATEGORY_ASSERT
            SDL_LOG_CATEGORY_SYSTEM      SDL_LOG_CATEGORY_AUDIO SDL_LOG_CATEGORY_VIDEO
            SDL_LOG_CATEGORY_RENDER      SDL_LOG_CATEGORY_INPUT SDL_LOG_CATEGORY_TEST
            SDL_LOG_CATEGORY_RESERVED1   SDL_LOG_CATEGORY_RESERVED2
            SDL_LOG_CATEGORY_RESERVED3   SDL_LOG_CATEGORY_RESERVED4
            SDL_LOG_CATEGORY_RESERVED5   SDL_LOG_CATEGORY_RESERVED6
            SDL_LOG_CATEGORY_RESERVED7   SDL_LOG_CATEGORY_RESERVED8
            SDL_LOG_CATEGORY_RESERVED9   SDL_LOG_CATEGORY_RESERVED10
            SDL_LOG_CATEGORY_CUSTOM
        ]
        ],
        SDL_LogPriority => [
        [ SDL_LOG_PRIORITY_VERBOSE => 1 ], qw[SDL_LOG_PRIORITY_DEBUG SDL_LOG_PRIORITY_INFO
            SDL_LOG_PRIORITY_WARN SDL_LOG_PRIORITY_ERROR SDL_LOG_PRIORITY_CRITICAL
            SDL_NUM_LOG_PRIORITIES]
        ];
    enum
        SDL_MessageBoxFlags => [
        [ SDL_MESSAGEBOX_ERROR                 => 0x00000010 ],
        [ SDL_MESSAGEBOX_WARNING               => 0x00000020 ],
        [ SDL_MESSAGEBOX_INFORMATION           => 0x00000040 ],
        [ SDL_MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT => 0x00000080 ],
        [ SDL_MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT => 0x00000100 ]
        ],
        SDL_MessageBoxButtonFlags => [
        [ SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT => 0x00000001 ],
        [ SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT => 0x00000002 ]
        ],
        SDL_MessageBoxColorType => [
        qw[SDL_MESSAGEBOX_COLOR_BACKGROUND
            SDL_MESSAGEBOX_COLOR_TEXT
            SDL_MESSAGEBOX_COLOR_BUTTON_BORDER
            SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND
            SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED
            SDL_MESSAGEBOX_COLOR_MAX]
        ],
        SDL_SystemCursor => [
        qw[SDL_SYSTEM_CURSOR_ARROW
            SDL_SYSTEM_CURSOR_IBEAM
            SDL_SYSTEM_CURSOR_WAIT
            SDL_SYSTEM_CURSOR_CROSSHAIR
            SDL_SYSTEM_CURSOR_WAITARROW
            SDL_SYSTEM_CURSOR_SIZENWSE
            SDL_SYSTEM_CURSOR_SIZENESW
            SDL_SYSTEM_CURSOR_SIZEWE
            SDL_SYSTEM_CURSOR_SIZENS
            SDL_SYSTEM_CURSOR_SIZEALL
            SDL_SYSTEM_CURSOR_NO
            SDL_SYSTEM_CURSOR_HAND
            SDL_NUM_SYSTEM_CURSORS]
        ],
        SDL_MouseWheelDirection => [
        qw[
            SDL_MOUSEWHEEL_NORMAL
            SDL_MOUSEWHEEL_FLIPPED
        ]
        ];
    define mouseButton => [
        [ SDL_BUTTON        => sub ($x) { 1 << ( ($x) - 1 ) } ],
        [ SDL_BUTTON_LEFT   => 1 ],
        [ SDL_BUTTON_MIDDLE => 2 ],
        [ SDL_BUTTON_RIGHT  => 3 ],
        [ SDL_BUTTON_X1     => 4 ],
        [ SDL_BUTTON_X2     => 5 ],
        [ SDL_BUTTON_LMASK  => sub () { SDL_BUTTON( SDL_BUTTON_LEFT() ); } ],
        [ SDL_BUTTON_MMASK  => sub () { SDL_BUTTON( SDL_BUTTON_MIDDLE() ); } ],
        [ SDL_BUTTON_RMASK  => sub () { SDL_BUTTON( SDL_BUTTON_RIGHT() ); } ],
        [ SDL_BUTTON_X1MASK => sub () { SDL_BUTTON( SDL_BUTTON_X1() ); } ],
        [ SDL_BUTTON_X2MASK => sub () { SDL_BUTTON( SDL_BUTTON_X2() ); } ]
    ];
    define alpha       => [ [ SDL_ALPHA_OPAQUE => 255 ], [ SDL_ALPHA_TRANSPARENT => 0 ] ];
    enum SDL_PixelType => [
        qw[SDL_PIXELTYPE_UNKNOWN
            SDL_PIXELTYPE_INDEX1
            SDL_PIXELTYPE_INDEX4
            SDL_PIXELTYPE_INDEX8
            SDL_PIXELTYPE_PACKED8
            SDL_PIXELTYPE_PACKED16
            SDL_PIXELTYPE_PACKED32
            SDL_PIXELTYPE_ARRAYU8
            SDL_PIXELTYPE_ARRAYU16
            SDL_PIXELTYPE_ARRAYU32
            SDL_PIXELTYPE_ARRAYF16
            SDL_PIXELTYPE_ARRAYF32]
        ],
        SDL_BitmapOrder => [
        qw[
            SDL_BITMAPORDER_NONE
            SDL_BITMAPORDER_4321
            SDL_BITMAPORDER_1234]
        ],
        SDL_PackedOrder => [
        qw[
            SDL_PACKEDORDER_NONE
            SDL_PACKEDORDER_XRGB
            SDL_PACKEDORDER_RGBX
            SDL_PACKEDORDER_ARGB
            SDL_PACKEDORDER_RGBA
            SDL_PACKEDORDER_XBGR
            SDL_PACKEDORDER_BGRX
            SDL_PACKEDORDER_ABGR
            SDL_PACKEDORDER_BGRA
        ]
        ],
        SDL_ArrayOrder => [
        qw[SDL_ARRAYORDER_NONE
            SDL_ARRAYORDER_RGB
            SDL_ARRAYORDER_RGBA
            SDL_ARRAYORDER_ARGB
            SDL_ARRAYORDER_BGR
            SDL_ARRAYORDER_BGRA
            SDL_ARRAYORDER_ABGR]
        ],
        SDL_PackedLayout => [
        qw[SDL_PACKEDLAYOUT_NONE
            SDL_PACKEDLAYOUT_332
            SDL_PACKEDLAYOUT_4444
            SDL_PACKEDLAYOUT_1555
            SDL_PACKEDLAYOUT_5551
            SDL_PACKEDLAYOUT_565
            SDL_PACKEDLAYOUT_8888
            SDL_PACKEDLAYOUT_2101010
            SDL_PACKEDLAYOUT_1010102]
        ];
    define pixels => [
        [ SDL_DEFINE_PIXELFOURCC => sub ( $A, $B, $C, $D ) { SDL_FOURCC( $A, $B, $C, $D ) } ],
        [   SDL_DEFINE_PIXELFORMAT => sub ( $type, $order, $layout, $bits, $bytes ) {
                ( ( 1 << 28 ) | ( ($type) << 24 ) | ( ($order) << 20 ) | ( ($layout) << 16 )
                        | ( ($bits) << 8 ) | ( ($bytes) << 0 ) )
            }
        ],
        [ SDL_PIXELFLAG    => sub ($X) { ( ( ($X) >> 28 ) & 0x0F ) } ],
        [ SDL_PIXELTYPE    => sub ($X) { ( ( ($X) >> 24 ) & 0x0F ) } ],
        [ SDL_PIXELORDER   => sub ($X) { ( ( ($X) >> 20 ) & 0x0F ) } ],
        [ SDL_PIXELLAYOUT  => sub ($X) { ( ( ($X) >> 16 ) & 0x0F ) } ],
        [ SDL_BITSPERPIXEL => sub ($X) { ( ( ($X) >> 8 ) & 0xFF ) } ],
        [   SDL_BYTESPERPIXEL => sub ($X) {
                (
                    SDL_ISPIXELFORMAT_FOURCC($X) ? (
                        (
                            ( ($X) == SDL_PIXELFORMAT_YUY2() )     ||
                                ( ($X) == SDL_PIXELFORMAT_UYVY() ) ||
                                ( ($X) == SDL_PIXELFORMAT_YVYU() )
                        ) ? 2 : 1
                        ) :
                        ( ( ($X) >> 0 ) & 0xFF )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_INDEXED => sub ($format) {
                (
                    !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX1() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX4() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX8() ) )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_PACKED => sub ($format) {
                (
                    !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED8() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED16() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED32() ) )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_ARRAY => sub ($format) {
                (
                    !SDL_ISPIXELFORMAT_FOURCC($format) &&
                        ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU8() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU16() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU32() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF16() ) ||
                        ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF32() ) )
                )
            }
        ],
        [   SDL_ISPIXELFORMAT_ALPHA => sub ($format) {
                (
                    (
                        SDL_ISPIXELFORMAT_PACKED($format) &&
                            ( ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_ARGB() ) ||
                            ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_RGBA() ) ||
                            ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_ABGR() ) ||
                            ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_BGRA() ) )
                    ) ||
                        (
                        SDL_ISPIXELFORMAT_ARRAY($format) &&
                        ( ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_ARGB() ) ||
                            ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_RGBA() ) ||
                            ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_ABGR() ) ||
                            ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_BGRA() ) )
                        )
                )
            }
        ],

        # The flag is set to 1 because 0x1? is not in the printable ASCII range
        [   SDL_ISPIXELFORMAT_FOURCC =>
                sub ($format) { ( ($format) && ( SDL_PIXELFLAG($format) != 1 ) ) }
        ]
    ];
    enum SDL_PixelFormatEnum => [
        'SDL_PIXELFORMAT_UNKNOWN',
        [   SDL_PIXELFORMAT_INDEX1LSB => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX1(), SDL_BITMAPORDER_4321(), 0, 1, 0 );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX1MSB => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX1(), SDL_BITMAPORDER_1234(), 0, 1, 0 );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX4LSB => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX4(), SDL_BITMAPORDER_4321(), 0, 4, 0 );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX4MSB => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX4(), SDL_BITMAPORDER_1234(), 0, 4, 0 );
            }
        ],
        [   SDL_PIXELFORMAT_INDEX8 =>
                sub () { SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX8(), 0, 0, 8, 1 ) }
        ],
        [   SDL_PIXELFORMAT_RGB332 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED8(), SDL_PACKEDORDER_XRGB(),
                    SDL_PACKEDLAYOUT_332(), 8, 1 );
            }
        ],
        [   SDL_PIXELFORMAT_XRGB4444 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XRGB(),
                    SDL_PACKEDLAYOUT_4444(), 12, 2 );
            }
        ],
        [ SDL_PIXELFORMAT_RGB444 => sub () { SDL_PIXELFORMAT_XRGB4444() } ],
        [   SDL_PIXELFORMAT_XBGR4444 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XBGR(),
                    SDL_PACKEDLAYOUT_4444(), 12, 2 );
            }
        ],
        [ SDL_PIXELFORMAT_BGR444 => sub () { SDL_PIXELFORMAT_XBGR4444() } ],
        [   SDL_PIXELFORMAT_XRGB1555 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XRGB(),
                    SDL_PACKEDLAYOUT_1555(), 15, 2 );
            }
        ],
        [ SDL_PIXELFORMAT_RGB555 => sub () { SDL_PIXELFORMAT_XRGB1555() } ],
        [   SDL_PIXELFORMAT_XBGR1555 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XBGR(),
                    SDL_PACKEDLAYOUT_1555(), 15, 2 );
            }
        ],
        [ SDL_PIXELFORMAT_BGR555 => sub () { SDL_PIXELFORMAT_XBGR1555() } ],
        [   SDL_PIXELFORMAT_ARGB4444 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ARGB(),
                    SDL_PACKEDLAYOUT_4444(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_RGBA4444 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_RGBA(),
                    SDL_PACKEDLAYOUT_4444(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_ABGR4444 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ABGR(),
                    SDL_PACKEDLAYOUT_4444(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_BGRA4444 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_BGRA(),
                    SDL_PACKEDLAYOUT_4444(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_ARGB1555 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ARGB(),
                    SDL_PACKEDLAYOUT_1555(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_RGBA5551 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_RGBA(),
                    SDL_PACKEDLAYOUT_5551(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_ABGR1555 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ABGR(),
                    SDL_PACKEDLAYOUT_1555(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_BGRA5551 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_BGRA(),
                    SDL_PACKEDLAYOUT_5551(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_RGB565 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XRGB(),
                    SDL_PACKEDLAYOUT_565(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_BGR565 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XBGR(),
                    SDL_PACKEDLAYOUT_565(), 16, 2 );
            }
        ],
        [   SDL_PIXELFORMAT_RGB24 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_ARRAYU8(), SDL_ARRAYORDER_RGB(), 0, 24, 3 );
            }
        ],
        [   SDL_PIXELFORMAT_BGR24 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_ARRAYU8(), SDL_ARRAYORDER_BGR(), 0, 24, 3 );
            }
        ],
        [   SDL_PIXELFORMAT_XRGB8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_XRGB(),
                    SDL_PACKEDLAYOUT_8888(), 24, 4 );
            }
        ],
        [ SDL_PIXELFORMAT_RGB888 => sub () { SDL_PIXELFORMAT_XRGB8888() } ],
        [   SDL_PIXELFORMAT_RGBX8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_RGBX(),
                    SDL_PACKEDLAYOUT_8888(), 24, 4 );
            }
        ],
        [   SDL_PIXELFORMAT_XBGR8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_XBGR(),
                    SDL_PACKEDLAYOUT_8888(), 24, 4 );
            }
        ],
        [ SDL_PIXELFORMAT_BGR888 => sub () { SDL_PIXELFORMAT_XBGR8888() } ],
        [   SDL_PIXELFORMAT_BGRX8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_BGRX(),
                    SDL_PACKEDLAYOUT_8888(), 24, 4 );
            }
        ],
        [   SDL_PIXELFORMAT_ARGB8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_ARGB(),
                    SDL_PACKEDLAYOUT_8888(), 32, 4 );
            }
        ],
        [   SDL_PIXELFORMAT_RGBA8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_RGBA(),
                    SDL_PACKEDLAYOUT_8888(), 32, 4 );
            }
        ],
        [   SDL_PIXELFORMAT_ABGR8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_ABGR(),
                    SDL_PACKEDLAYOUT_8888(), 32, 4 );
            }
        ],
        [   SDL_PIXELFORMAT_BGRA8888 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_BGRA(),
                    SDL_PACKEDLAYOUT_8888(), 32, 4 );
            }
        ],
        [   SDL_PIXELFORMAT_ARGB2101010 => sub () {
                SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_ARGB(),
                    SDL_PACKEDLAYOUT_2101010(),
                    32, 4 );
            }
        ], (    # Aliases for RGBA byte arrays of color data, for the current platform
            SDL2::FFI::bigendian() ? (
                [ SDL_PIXELFORMAT_RGBA32 => sub() { SDL_PIXELFORMAT_RGBA8888() } ],
                [ SDL_PIXELFORMAT_ARGB32 => sub() { SDL_PIXELFORMAT_ARGB8888() } ],
                [ SDL_PIXELFORMAT_BGRA32 => sub() { SDL_PIXELFORMAT_BGRA8888() } ],
                [ SDL_PIXELFORMAT_ABGR32 => sub() { SDL_PIXELFORMAT_ABGR8888() } ]
                ) : (
                [ SDL_PIXELFORMAT_RGBA32 => sub() { SDL_PIXELFORMAT_ABGR8888() } ],
                [ SDL_PIXELFORMAT_ARGB32 => sub() { SDL_PIXELFORMAT_BGRA8888() } ],
                [ SDL_PIXELFORMAT_BGRA32 => sub() { SDL_PIXELFORMAT_ARGB8888() } ],
                [ SDL_PIXELFORMAT_ABGR32 => sub() { SDL_PIXELFORMAT_RGBA8888() } ],
                )
        ),
        [ SDL_PIXELFORMAT_YV12         => sub () { SDL_DEFINE_PIXELFOURCC( 'Y', 'V', '1', '2' ) } ],
        [ SDL_PIXELFORMAT_IYUV         => sub () { SDL_DEFINE_PIXELFOURCC( 'I', 'Y', 'U', 'V' ) } ],
        [ SDL_PIXELFORMAT_YUY2         => sub () { SDL_DEFINE_PIXELFOURCC( 'Y', 'U', 'Y', '2' ) } ],
        [ SDL_PIXELFORMAT_UYVY         => sub () { SDL_DEFINE_PIXELFOURCC( 'U', 'Y', 'V', 'Y' ) } ],
        [ SDL_PIXELFORMAT_YVYU         => sub () { SDL_DEFINE_PIXELFOURCC( 'Y', 'V', 'Y', 'U' ) } ],
        [ SDL_PIXELFORMAT_NV12         => sub () { SDL_DEFINE_PIXELFOURCC( 'N', 'V', '1', '2' ) } ],
        [ SDL_PIXELFORMAT_NV21         => sub () { SDL_DEFINE_PIXELFOURCC( 'N', 'V', '2', '1' ) } ],
        [ SDL_PIXELFORMAT_EXTERNAL_OES => sub () { SDL_DEFINE_PIXELFOURCC( 'O', 'E', 'S', ' ' ) } ]
    ];
    enum SDL_PowerState => [
        qw[
            SDL_POWERSTATE_UNKNOWN
            SDL_POWERSTATE_ON_BATTERY SDL_POWERSTATE_NO_BATTERY
            SDL_POWERSTATE_CHARGING   SDL_POWERSTATE_CHARGED]
    ];

    # START HERE!!!!!!!!!!!!!
    enum SDL_AssertState => [
        qw[ SDL_ASSERTION_RETRY
            SDL_ASSERTION_BREAK
            SDL_ASSERTION_ABORT
            SDL_ASSERTION_IGNORE
            SDL_ASSERTION_ALWAYS_IGNORE
        ]
    ];
    enum SDL_WindowFlags => [
        [ SDL_WINDOW_FULLSCREEN         => 0x00000001 ], [ SDL_WINDOW_OPENGL      => 0x00000002 ],
        [ SDL_WINDOW_SHOWN              => 0x00000004 ], [ SDL_WINDOW_HIDDEN      => 0x00000008 ],
        [ SDL_WINDOW_BORDERLESS         => 0x00000010 ], [ SDL_WINDOW_RESIZABLE   => 0x00000020 ],
        [ SDL_WINDOW_MINIMIZED          => 0x00000040 ], [ SDL_WINDOW_MAXIMIZED   => 0x00000080 ],
        [ SDL_WINDOW_MOUSE_GRABBED      => 0x00000100 ], [ SDL_WINDOW_INPUT_FOCUS => 0x00000200 ],
        [ SDL_WINDOW_MOUSE_FOCUS        => 0x00000400 ],
        [ SDL_WINDOW_FULLSCREEN_DESKTOP => sub { ( SDL_WINDOW_FULLSCREEN() | 0x00001000 ) } ],
        [ SDL_WINDOW_FOREIGN            => 0x00000800 ], [ SDL_WINDOW_ALLOW_HIGHDPI => 0x00002000 ],
        [ SDL_WINDOW_MOUSE_CAPTURE      => 0x00004000 ], [ SDL_WINDOW_ALWAYS_ON_TOP => 0x00008000 ],
        [ SDL_WINDOW_SKIP_TASKBAR       => 0x00010000 ], [ SDL_WINDOW_UTILITY       => 0x00020000 ],
        [ SDL_WINDOW_TOOLTIP            => 0x00040000 ], [ SDL_WINDOW_POPUP_MENU    => 0x00080000 ],
        [ SDL_WINDOW_KEYBOARD_GRABBED   => 0x00100000 ], [ SDL_WINDOW_VULKAN        => 0x10000000 ],
        [ SDL_WINDOW_METAL              => 0x20000000 ],
        [ SDL_WINDOW_INPUT_GRABBED      => sub { SDL_WINDOW_MOUSE_GRABBED() } ],, qw[
            SDL_WINDOWEVENT_NONE
            SDL_WINDOWEVENT_SHOWN
            SDL_WINDOWEVENT_HIDDEN
            SDL_WINDOWEVENT_EXPOSED
            SDL_WINDOWEVENT_MOVED
            SDL_WINDOWEVENT_RESIZED
            SDL_WINDOWEVENT_SIZE_CHANGED
            SDL_WINDOWEVENT_MINIMIZED
            SDL_WINDOWEVENT_MAXIMIZED
            SDL_WINDOWEVENT_RESTORED
            SDL_WINDOWEVENT_ENTER
            SDL_WINDOWEVENT_LEAVE
            SDL_WINDOWEVENT_FOCUS_GAINED
            SDL_WINDOWEVENT_FOCUS_LOST
            SDL_WINDOWEVENT_CLOSE
            SDL_WINDOWEVENT_TAKE_FOCUS
            SDL_WINDOWEVENT_HIT_TEST
        ]
        ],
        SDL_DisplayEventID => [
        qw[SDL_DISPLAYEVENT_NONE SDL_DISPLAYEVENT_ORIENTATION
            SDL_DISPLAYEVENT_CONNECTED SDL_DISPLAYEVENT_DISCONNECTED
        ]
        ],
        SDL_DisplayOrientation => [
        qw[SDL_ORIENTATION_UNKNOWN
            SDL_ORIENTATION_LANDSCAPE SDL_ORIENTATION_LANDSCAPE_FLIPPED
            SDL_ORIENTATION_PORTRAIT  SDL_ORIENTATION_PORTRAIT_FLIPPED
        ]
        ],
        SDL_GLattr => [
        qw[
            SDL_GL_RED_SIZE
            SDL_GL_GREEN_SIZE
            SDL_GL_BLUE_SIZE
            SDL_GL_ALPHA_SIZE
            SDL_GL_BUFFER_SIZE
            SDL_GL_DOUBLEBUFFER
            SDL_GL_DEPTH_SIZE
            SDL_GL_STENCIL_SIZE
            SDL_GL_ACCUM_RED_SIZE
            SDL_GL_ACCUM_GREEN_SIZE
            SDL_GL_ACCUM_BLUE_SIZE
            SDL_GL_ACCUM_ALPHA_SIZE
            SDL_GL_STEREO
            SDL_GL_MULTISAMPLEBUFFERS
            SDL_GL_MULTISAMPLESAMPLES
            SDL_GL_ACCELERATED_VISUAL
            SDL_GL_RETAINED_BACKING
            SDL_GL_CONTEXT_MAJOR_VERSION
            SDL_GL_CONTEXT_MINOR_VERSION
            SDL_GL_CONTEXT_EGL
            SDL_GL_CONTEXT_FLAGS
            SDL_GL_CONTEXT_PROFILE_MASK
            SDL_GL_SHARE_WITH_CURRENT_CONTEXT
            SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
            SDL_GL_CONTEXT_RELEASE_BEHAVIOR
            SDL_GL_CONTEXT_RESET_NOTIFICATION
            SDL_GL_CONTEXT_NO_ERROR
        ]
        ],
        SDL_GLprofile => [
        [ SDL_GL_CONTEXT_PROFILE_CORE          => 0x0001 ],
        [ SDL_GL_CONTEXT_PROFILE_COMPATIBILITY => 0x0002 ],
        [ SDL_GL_CONTEXT_PROFILE_ES            => 0x0004 ]
        ],
        SDL_GLcontextFlag => [
        [ SDL_GL_CONTEXT_DEBUG_FLAG              => 0x0001 ],
        [ SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG => 0x0002 ],
        [ SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG      => 0x0004 ],
        [ SDL_GL_CONTEXT_RESET_ISOLATION_FLAG    => 0x0008 ]
        ],
        SDL_GLcontextReleaseFlag => [
        [ SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE  => 0x0000 ],
        [ SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH => 0x0001 ]
        ],
        SDL_GLContextResetNotification => [
        [ SDL_GL_CONTEXT_RESET_NO_NOTIFICATION => 0x0000 ],
        [ SDL_GL_CONTEXT_RESET_LOSE_CONTEXT    => 0x0001 ]
        ],
        SDL_RendererFlags => [
        [ SDL_RENDERER_SOFTWARE      => 0x00000001 ],
        [ SDL_RENDERER_ACCELERATED   => 0x00000002 ],
        [ SDL_RENDERER_PRESENTVSYNC  => 0x00000004 ],
        [ SDL_RENDERER_TARGETTEXTURE => 0x00000008 ]
        ],
        SDL_ScaleMode     => [qw[SDL_SCALEMODENEAREST SDL_SCALEMODELINEAR SDL_SCALEMODEBEST]],
        SDL_TextureAccess =>
        [qw[SDL_TEXTUREACCESS_STATIC SDL_TEXTUREACCESS_STREAMING SDL_TEXTUREACCESS_TARGET]],
        SDL_TextureModulate => [
        [ SDL_TEXTUREMODULATE_NONE  => 0x00000000 ],
        [ SDL_TEXTUREMODULATE_COLOR => 0x00000001 ],
        [ SDL_TEXTUREMODULATE_ALPHA => 0x00000002 ]
        ],
        SDL_RendererFlip => [
        [ SDL_FLIP_NONE       => 0x00000000 ],
        [ SDL_FLIP_HORIZONTAL => 0x00000001 ],
        [ SDL_FLIP_VERTICAL   => 0x00000002 ]
        ],
        SDL_EventAction => [
        qw[
            SDL_ADDEVENT
            SDL_PEEKEVENT
            SDL_GETEVENT]
        ],
        pixel_type => [
        qw[
            SDL_PIXELTYPE_UNKNOWN
            SDL_PIXELTYPE_INDEX1
            SDL_PIXELTYPE_INDEX4
            SDL_PIXELTYPE_INDEX8
            SDL_PIXELTYPE_PACKED8
            SDL_PIXELTYPE_PACKED16
            SDL_PIXELTYPE_PACKED32
            SDL_PIXELTYPE_ARRAYU8
            SDL_PIXELTYPE_ARRAYU16
            SDL_PIXELTYPE_ARRAYU32
            SDL_PIXELTYPE_ARRAYF16
            SDL_PIXELTYPE_ARRAYF32
        ]
        ],
        bitmap_order => [
        qw[
            SDL_BITMAPORDER_NONE
            SDL_BITMAPORDER_4321
            SDL_BITMAPORDER_1234
        ]
        ],
        packed_order => [
        qw[
            SDL_PACKEDORDER_NONE
            SDL_PACKEDORDER_XRGB
            SDL_PACKEDORDER_RGBX
            SDL_PACKEDORDER_ARGB
            SDL_PACKEDORDER_RGBA
            SDL_PACKEDORDER_XBGR
            SDL_PACKEDORDER_BGRX
            SDL_PACKEDORDER_ABGR
            SDL_PACKEDORDER_BGRA
        ]
        ],
        array_order => [
        qw[
            SDL_ARRAYORDER_NONE
            SDL_ARRAYORDER_RGB
            SDL_ARRAYORDER_RGBA
            SDL_ARRAYORDER_ARGB
            SDL_ARRAYORDER_BGR
            SDL_ARRAYORDER_BGRA
            SDL_ARRAYORDER_ABGR
        ]
        ],
        packed_layout => [
        qw[
            SDL_PACKEDLAYOUT_NONE
            SDL_PACKEDLAYOUT_332
            SDL_PACKEDLAYOUT_4444
            SDL_PACKEDLAYOUT_1555
            SDL_PACKEDLAYOUT_5551
            SDL_PACKEDLAYOUT_565
            SDL_PACKEDLAYOUT_8888
            SDL_PACKEDLAYOUT_2101010
            SDL_PACKEDLAYOUT_1010102
        ]
        ],
        ;

    # Keyboard codes
    sub SDLK_SCANCODE_MASK           { 1 << 30 }
    sub SDL_SCANCODE_TO_KEYCODE ($X) { $X | SDLK_SCANCODE_MASK }
    enum SDL_Scancode =>
        [ [ SDL_SCANCODE_UNKNOWN => 0 ], [ SDL_SCANCODE_A => 4 ], [ SDL_SCANCODE_ESCAPE => 41 ] ];

=pod

    /**
     *  \name Usage page 0x07
     *
     *  These values are from usage page 0x07 (USB keyboard page).
     */
    /* @{ */

    SDL_SCANCODE_A = 4,
    SDL_SCANCODE_B = 5,
    SDL_SCANCODE_C = 6,
    SDL_SCANCODE_D = 7,
    SDL_SCANCODE_E = 8,
    SDL_SCANCODE_F = 9,
    SDL_SCANCODE_G = 10,
    SDL_SCANCODE_H = 11,
    SDL_SCANCODE_I = 12,
    SDL_SCANCODE_J = 13,
    SDL_SCANCODE_K = 14,
    SDL_SCANCODE_L = 15,
    SDL_SCANCODE_M = 16,
    SDL_SCANCODE_N = 17,
    SDL_SCANCODE_O = 18,
    SDL_SCANCODE_P = 19,
    SDL_SCANCODE_Q = 20,
    SDL_SCANCODE_R = 21,
    SDL_SCANCODE_S = 22,
    SDL_SCANCODE_T = 23,
    SDL_SCANCODE_U = 24,
    SDL_SCANCODE_V = 25,
    SDL_SCANCODE_W = 26,
    SDL_SCANCODE_X = 27,
    SDL_SCANCODE_Y = 28,
    SDL_SCANCODE_Z = 29,

    SDL_SCANCODE_1 = 30,
    SDL_SCANCODE_2 = 31,
    SDL_SCANCODE_3 = 32,
    SDL_SCANCODE_4 = 33,
    SDL_SCANCODE_5 = 34,
    SDL_SCANCODE_6 = 35,
    SDL_SCANCODE_7 = 36,
    SDL_SCANCODE_8 = 37,
    SDL_SCANCODE_9 = 38,
    SDL_SCANCODE_0 = 39,

    SDL_SCANCODE_RETURN = 40,
    SDL_SCANCODE_ESCAPE = 41,
    SDL_SCANCODE_BACKSPACE = 42,
    SDL_SCANCODE_TAB = 43,
    SDL_SCANCODE_SPACE = 44,

    SDL_SCANCODE_MINUS = 45,
    SDL_SCANCODE_EQUALS = 46,
    SDL_SCANCODE_LEFTBRACKET = 47,
    SDL_SCANCODE_RIGHTBRACKET = 48,
    SDL_SCANCODE_BACKSLASH = 49, /**< Located at the lower left of the return
                                  *   key on ISO keyboards and at the right end
                                  *   of the QWERTY row on ANSI keyboards.
                                  *   Produces REVERSE SOLIDUS (backslash) and
                                  *   VERTICAL LINE in a US layout, REVERSE
                                  *   SOLIDUS and VERTICAL LINE in a UK Mac
                                  *   layout, NUMBER SIGN and TILDE in a UK
                                  *   Windows layout, DOLLAR SIGN and POUND SIGN
                                  *   in a Swiss German layout, NUMBER SIGN and
                                  *   APOSTROPHE in a German layout, GRAVE
                                  *   ACCENT and POUND SIGN in a French Mac
                                  *   layout, and ASTERISK and MICRO SIGN in a
                                  *   French Windows layout.
                                  */
    SDL_SCANCODE_NONUSHASH = 50, /**< ISO USB keyboards actually use this code
                                  *   instead of 49 for the same key, but all
                                  *   OSes I've seen treat the two codes
                                  *   identically. So, as an implementor, unless
                                  *   your keyboard generates both of those
                                  *   codes and your OS treats them differently,
                                  *   you should generate SDL_SCANCODE_BACKSLASH
                                  *   instead of this code. As a user, you
                                  *   should not rely on this code because SDL
                                  *   will never generate it with most (all?)
                                  *   keyboards.
                                  */
    SDL_SCANCODE_SEMICOLON = 51,
    SDL_SCANCODE_APOSTROPHE = 52,
    SDL_SCANCODE_GRAVE = 53, /**< Located in the top left corner (on both ANSI
                              *   and ISO keyboards). Produces GRAVE ACCENT and
                              *   TILDE in a US Windows layout and in US and UK
                              *   Mac layouts on ANSI keyboards, GRAVE ACCENT
                              *   and NOT SIGN in a UK Windows layout, SECTION
                              *   SIGN and PLUS-MINUS SIGN in US and UK Mac
                              *   layouts on ISO keyboards, SECTION SIGN and
                              *   DEGREE SIGN in a Swiss German layout (Mac:
                              *   only on ISO keyboards), CIRCUMFLEX ACCENT and
                              *   DEGREE SIGN in a German layout (Mac: only on
                              *   ISO keyboards), SUPERSCRIPT TWO and TILDE in a
                              *   French Windows layout, COMMERCIAL AT and
                              *   NUMBER SIGN in a French Mac layout on ISO
                              *   keyboards, and LESS-THAN SIGN and GREATER-THAN
                              *   SIGN in a Swiss German, German, or French Mac
                              *   layout on ANSI keyboards.
                              */
    SDL_SCANCODE_COMMA = 54,
    SDL_SCANCODE_PERIOD = 55,
    SDL_SCANCODE_SLASH = 56,

    SDL_SCANCODE_CAPSLOCK = 57,

    SDL_SCANCODE_F1 = 58,
    SDL_SCANCODE_F2 = 59,
    SDL_SCANCODE_F3 = 60,
    SDL_SCANCODE_F4 = 61,
    SDL_SCANCODE_F5 = 62,
    SDL_SCANCODE_F6 = 63,
    SDL_SCANCODE_F7 = 64,
    SDL_SCANCODE_F8 = 65,
    SDL_SCANCODE_F9 = 66,
    SDL_SCANCODE_F10 = 67,
    SDL_SCANCODE_F11 = 68,
    SDL_SCANCODE_F12 = 69,

    SDL_SCANCODE_PRINTSCREEN = 70,
    SDL_SCANCODE_SCROLLLOCK = 71,
    SDL_SCANCODE_PAUSE = 72,
    SDL_SCANCODE_INSERT = 73, /**< insert on PC, help on some Mac keyboards (but
                                   does send code 73, not 117) */
    SDL_SCANCODE_HOME = 74,
    SDL_SCANCODE_PAGEUP = 75,
    SDL_SCANCODE_DELETE = 76,
    SDL_SCANCODE_END = 77,
    SDL_SCANCODE_PAGEDOWN = 78,
    SDL_SCANCODE_RIGHT = 79,
    SDL_SCANCODE_LEFT = 80,
    SDL_SCANCODE_DOWN = 81,
    SDL_SCANCODE_UP = 82,

    SDL_SCANCODE_NUMLOCKCLEAR = 83, /**< num lock on PC, clear on Mac keyboards
                                     */
    SDL_SCANCODE_KP_DIVIDE = 84,
    SDL_SCANCODE_KP_MULTIPLY = 85,
    SDL_SCANCODE_KP_MINUS = 86,
    SDL_SCANCODE_KP_PLUS = 87,
    SDL_SCANCODE_KP_ENTER = 88,
    SDL_SCANCODE_KP_1 = 89,
    SDL_SCANCODE_KP_2 = 90,
    SDL_SCANCODE_KP_3 = 91,
    SDL_SCANCODE_KP_4 = 92,
    SDL_SCANCODE_KP_5 = 93,
    SDL_SCANCODE_KP_6 = 94,
    SDL_SCANCODE_KP_7 = 95,
    SDL_SCANCODE_KP_8 = 96,
    SDL_SCANCODE_KP_9 = 97,
    SDL_SCANCODE_KP_0 = 98,
    SDL_SCANCODE_KP_PERIOD = 99,

    SDL_SCANCODE_NONUSBACKSLASH = 100, /**< This is the additional key that ISO
                                        *   keyboards have over ANSI ones,
                                        *   located between left shift and Y.
                                        *   Produces GRAVE ACCENT and TILDE in a
                                        *   US or UK Mac layout, REVERSE SOLIDUS
                                        *   (backslash) and VERTICAL LINE in a
                                        *   US or UK Windows layout, and
                                        *   LESS-THAN SIGN and GREATER-THAN SIGN
                                        *   in a Swiss German, German, or French
                                        *   layout. */
    SDL_SCANCODE_APPLICATION = 101, /**< windows contextual menu, compose */
    SDL_SCANCODE_POWER = 102, /**< The USB document says this is a status flag,
                               *   not a physical key - but some Mac keyboards
                               *   do have a power key. */
    SDL_SCANCODE_KP_EQUALS = 103,
    SDL_SCANCODE_F13 = 104,
    SDL_SCANCODE_F14 = 105,
    SDL_SCANCODE_F15 = 106,
    SDL_SCANCODE_F16 = 107,
    SDL_SCANCODE_F17 = 108,
    SDL_SCANCODE_F18 = 109,
    SDL_SCANCODE_F19 = 110,
    SDL_SCANCODE_F20 = 111,
    SDL_SCANCODE_F21 = 112,
    SDL_SCANCODE_F22 = 113,
    SDL_SCANCODE_F23 = 114,
    SDL_SCANCODE_F24 = 115,
    SDL_SCANCODE_EXECUTE = 116,
    SDL_SCANCODE_HELP = 117,
    SDL_SCANCODE_MENU = 118,
    SDL_SCANCODE_SELECT = 119,
    SDL_SCANCODE_STOP = 120,
    SDL_SCANCODE_AGAIN = 121,   /**< redo */
    SDL_SCANCODE_UNDO = 122,
    SDL_SCANCODE_CUT = 123,
    SDL_SCANCODE_COPY = 124,
    SDL_SCANCODE_PASTE = 125,
    SDL_SCANCODE_FIND = 126,
    SDL_SCANCODE_MUTE = 127,
    SDL_SCANCODE_VOLUMEUP = 128,
    SDL_SCANCODE_VOLUMEDOWN = 129,
/* not sure whether there's a reason to enable these */
/*     SDL_SCANCODE_LOCKINGCAPSLOCK = 130,  */
/*     SDL_SCANCODE_LOCKINGNUMLOCK = 131, */
/*     SDL_SCANCODE_LOCKINGSCROLLLOCK = 132, */
    SDL_SCANCODE_KP_COMMA = 133,
    SDL_SCANCODE_KP_EQUALSAS400 = 134,

    SDL_SCANCODE_INTERNATIONAL1 = 135, /**< used on Asian keyboards, see
                                            footnotes in USB doc */
    SDL_SCANCODE_INTERNATIONAL2 = 136,
    SDL_SCANCODE_INTERNATIONAL3 = 137, /**< Yen */
    SDL_SCANCODE_INTERNATIONAL4 = 138,
    SDL_SCANCODE_INTERNATIONAL5 = 139,
    SDL_SCANCODE_INTERNATIONAL6 = 140,
    SDL_SCANCODE_INTERNATIONAL7 = 141,
    SDL_SCANCODE_INTERNATIONAL8 = 142,
    SDL_SCANCODE_INTERNATIONAL9 = 143,
    SDL_SCANCODE_LANG1 = 144, /**< Hangul/English toggle */
    SDL_SCANCODE_LANG2 = 145, /**< Hanja conversion */
    SDL_SCANCODE_LANG3 = 146, /**< Katakana */
    SDL_SCANCODE_LANG4 = 147, /**< Hiragana */
    SDL_SCANCODE_LANG5 = 148, /**< Zenkaku/Hankaku */
    SDL_SCANCODE_LANG6 = 149, /**< reserved */
    SDL_SCANCODE_LANG7 = 150, /**< reserved */
    SDL_SCANCODE_LANG8 = 151, /**< reserved */
    SDL_SCANCODE_LANG9 = 152, /**< reserved */

    SDL_SCANCODE_ALTERASE = 153, /**< Erase-Eaze */
    SDL_SCANCODE_SYSREQ = 154,
    SDL_SCANCODE_CANCEL = 155,
    SDL_SCANCODE_CLEAR = 156,
    SDL_SCANCODE_PRIOR = 157,
    SDL_SCANCODE_RETURN2 = 158,
    SDL_SCANCODE_SEPARATOR = 159,
    SDL_SCANCODE_OUT = 160,
    SDL_SCANCODE_OPER = 161,
    SDL_SCANCODE_CLEARAGAIN = 162,
    SDL_SCANCODE_CRSEL = 163,
    SDL_SCANCODE_EXSEL = 164,

    SDL_SCANCODE_KP_00 = 176,
    SDL_SCANCODE_KP_000 = 177,
    SDL_SCANCODE_THOUSANDSSEPARATOR = 178,
    SDL_SCANCODE_DECIMALSEPARATOR = 179,
    SDL_SCANCODE_CURRENCYUNIT = 180,
    SDL_SCANCODE_CURRENCYSUBUNIT = 181,
    SDL_SCANCODE_KP_LEFTPAREN = 182,
    SDL_SCANCODE_KP_RIGHTPAREN = 183,
    SDL_SCANCODE_KP_LEFTBRACE = 184,
    SDL_SCANCODE_KP_RIGHTBRACE = 185,
    SDL_SCANCODE_KP_TAB = 186,
    SDL_SCANCODE_KP_BACKSPACE = 187,
    SDL_SCANCODE_KP_A = 188,
    SDL_SCANCODE_KP_B = 189,
    SDL_SCANCODE_KP_C = 190,
    SDL_SCANCODE_KP_D = 191,
    SDL_SCANCODE_KP_E = 192,
    SDL_SCANCODE_KP_F = 193,
    SDL_SCANCODE_KP_XOR = 194,
    SDL_SCANCODE_KP_POWER = 195,
    SDL_SCANCODE_KP_PERCENT = 196,
    SDL_SCANCODE_KP_LESS = 197,
    SDL_SCANCODE_KP_GREATER = 198,
    SDL_SCANCODE_KP_AMPERSAND = 199,
    SDL_SCANCODE_KP_DBLAMPERSAND = 200,
    SDL_SCANCODE_KP_VERTICALBAR = 201,
    SDL_SCANCODE_KP_DBLVERTICALBAR = 202,
    SDL_SCANCODE_KP_COLON = 203,
    SDL_SCANCODE_KP_HASH = 204,
    SDL_SCANCODE_KP_SPACE = 205,
    SDL_SCANCODE_KP_AT = 206,
    SDL_SCANCODE_KP_EXCLAM = 207,
    SDL_SCANCODE_KP_MEMSTORE = 208,
    SDL_SCANCODE_KP_MEMRECALL = 209,
    SDL_SCANCODE_KP_MEMCLEAR = 210,
    SDL_SCANCODE_KP_MEMADD = 211,
    SDL_SCANCODE_KP_MEMSUBTRACT = 212,
    SDL_SCANCODE_KP_MEMMULTIPLY = 213,
    SDL_SCANCODE_KP_MEMDIVIDE = 214,
    SDL_SCANCODE_KP_PLUSMINUS = 215,
    SDL_SCANCODE_KP_CLEAR = 216,
    SDL_SCANCODE_KP_CLEARENTRY = 217,
    SDL_SCANCODE_KP_BINARY = 218,
    SDL_SCANCODE_KP_OCTAL = 219,
    SDL_SCANCODE_KP_DECIMAL = 220,
    SDL_SCANCODE_KP_HEXADECIMAL = 221,

    SDL_SCANCODE_LCTRL = 224,
    SDL_SCANCODE_LSHIFT = 225,
    SDL_SCANCODE_LALT = 226, /**< alt, option */
    SDL_SCANCODE_LGUI = 227, /**< windows, command (apple), meta */
    SDL_SCANCODE_RCTRL = 228,
    SDL_SCANCODE_RSHIFT = 229,
    SDL_SCANCODE_RALT = 230, /**< alt gr, option */
    SDL_SCANCODE_RGUI = 231, /**< windows, command (apple), meta */

    SDL_SCANCODE_MODE = 257,    /**< I'm not sure if this is really not covered
                                 *   by any of the above, but since there's a
                                 *   special KMOD_MODE for it I'm adding it here
                                 */

    /* @} *//* Usage page 0x07 */

    /**
     *  \name Usage page 0x0C
     *
     *  These values are mapped from usage page 0x0C (USB consumer page).
     */
    /* @{ */

    SDL_SCANCODE_AUDIONEXT = 258,
    SDL_SCANCODE_AUDIOPREV = 259,
    SDL_SCANCODE_AUDIOSTOP = 260,
    SDL_SCANCODE_AUDIOPLAY = 261,
    SDL_SCANCODE_AUDIOMUTE = 262,
    SDL_SCANCODE_MEDIASELECT = 263,
    SDL_SCANCODE_WWW = 264,
    SDL_SCANCODE_MAIL = 265,
    SDL_SCANCODE_CALCULATOR = 266,
    SDL_SCANCODE_COMPUTER = 267,
    SDL_SCANCODE_AC_SEARCH = 268,
    SDL_SCANCODE_AC_HOME = 269,
    SDL_SCANCODE_AC_BACK = 270,
    SDL_SCANCODE_AC_FORWARD = 271,
    SDL_SCANCODE_AC_STOP = 272,
    SDL_SCANCODE_AC_REFRESH = 273,
    SDL_SCANCODE_AC_BOOKMARKS = 274,

    /* @} *//* Usage page 0x0C */

    /**
     *  \name Walther keys
     *
     *  These are values that Christian Walther added (for mac keyboard?).
     */
    /* @{ */

    SDL_SCANCODE_BRIGHTNESSDOWN = 275,
    SDL_SCANCODE_BRIGHTNESSUP = 276,
    SDL_SCANCODE_DISPLAYSWITCH = 277, /**< display mirroring/dual display
                                           switch, video mode switch */
    SDL_SCANCODE_KBDILLUMTOGGLE = 278,
    SDL_SCANCODE_KBDILLUMDOWN = 279,
    SDL_SCANCODE_KBDILLUMUP = 280,
    SDL_SCANCODE_EJECT = 281,
    SDL_SCANCODE_SLEEP = 282,

    SDL_SCANCODE_APP1 = 283,
    SDL_SCANCODE_APP2 = 284,

    /* @} *//* Walther keys */

    /**
     *  \name Usage page 0x0C (additional media keys)
     *
     *  These values are mapped from usage page 0x0C (USB consumer page).
     */
    /* @{ */

    SDL_SCANCODE_AUDIOREWIND = 285,
    SDL_SCANCODE_AUDIOFASTFORWARD = 286,

    /* @} *//* Usage page 0x0C (additional media keys) */

    /* Add any other keys here. */

    SDL_NUM_SCANCODES = 512 /**< not a key, just marks the number of scancodes
                                 for array bounds */
=cut

=encoding utf-8

=head1 NAME

SDL2::Enum - Enumerations and Defined Constants Related to SDL

=head1 SYNOPSIS

    use SDL2::FFI qw[:all]; # Yep, you import from SDL2::FFI

=head1 DESCRIPTION


=head1 C<:init>

These are the flags which may be passed to L<< C<SDL_Init( ...
)>|SDL2::FFI/C<SDL_Init( ... )> >>. You should specify the subsystems which you
will be using in your application.

=over

=item C<SDL_INIT_TIMER> - Timer subsystem

=item C<SDL_INIT_AUDIO> - Audio subsystem

=item C<SDL_INIT_VIDEO> - Video subsystem. Automatically initializes the events subsystem

=item C<SDL_INIT_JOYSTICK> - Joystick subsystem. Automatically initializes the events subsystem

=item C<SDL_INIT_HAPTIC> - Haptic (force feedback) subsystem

=item C<SDL_INIT_GAMECONTROLLER> - Controller subsystem. Automatically initializes the joystick subsystem

=item C<SDL_INIT_EVENTS> - Events subsystem

=item C<SDL_INIT_SENSOR> - Sensor subsystem

=item C<SDL_INIT_EVERYTHING> - All of the above subsystems

=item C<SDL_INIT_NOPARACHUTE> - Compatibility; this flag is ignored

=back

=cut

=head1 C<:audioformat>

Audio format flags.

These are what the 16 bits in SDL_AudioFormat currently mean... (Unspecified
bits are always zero).

    ++-----------------------sample is signed if set
    ||
    ||       ++-----------sample is bigendian if set
    ||       ||
    ||       ||          ++---sample is float if set
    ||       ||          ||
    ||       ||          || +---sample bit size---+
    ||       ||          || |                     |
    15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00

=over

=item C<SDL_AUDIO_MASK_BITSIZE>

=item C<SDL_AUDIO_MASK_DATATYPE>

=item C<SDL_AUDIO_MASK_ENDIAN>

=item C<SDL_AUDIO_MASK_SIGNED>

=item C<SDL_AUDIO_BITSIZE( ... >

=item C<SDL_AUDIO_ISFLOAT( ... )>

=item C<SDL_AUDIO_ISBIGENDIAN( ... )>

=item C<SDL_AUDIO_ISSIGNED( ... )>

=item C<SDL_AUDIO_ISINT( ... )>

=item C<SDL_AUDIO_ISLITTLEENDIAN( ... )>

=item C<SDL_AUDIO_ISUNSIGNED( ... )>

=back

Defaults to LSB byte order.

=over

=item C<AUDIO_U8> - Unsigned 8-bit samples

=item C<AUDIO_S8> - Signed 8-bit samples

=item C<AUDIO_U16LSB> - Unsigned 16-bit samples

=item C<AUDIO_S16LSB> - Signed 16-bit samples

=item C<AUDIO_U16MSB> - As above, but big-endian byte order

=item C<AUDIO_S16MSB> - As above, but big-endian byte order

=item C<AUDIO_U16> - C<AUDIO_U16LSB>

=item C<AUDIO_S16> - C<AUDIO_S16LSB>

=back

int32 support.

=over

=item C<AUDIO_S32LSB> - 32-bit integer samples

=item C<AUDIO_S32MSB> - As above, but big-endian byte order

=item C<AUDIO_S32> - C<AUDIO_S32LSB>

=back

float 32 support.

=over

=item C<AUDIO_F32LSB> - 32-bit floating point samples

=item C<AUDIO_F32MSB> - As above, but big-endian byte order

=item C<AUDIO_F32> - C<AUDIO_F32LSB>

=back

Native audio byte ordering.

=over

=item C<AUDIO_U16SYS>

=item C<AUDIO_S16SYS>

=item C<AUDIO_S32SYS>

=item C<AUDIO_F32SYS>

=back

Which audio format changes are allowed when opening a device.

=over

=item C<SDL_AUDIO_ALLOW_FREQUENCY_CHANGE>

=item C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>

=item C<SDL_AUDIO_ALLOW_CHANNELS_CHANGE>

=item C<SDL_AUDIO_ALLOW_SAMPLES_CHANGE>

=item C<SDL_AUDIO_ALLOW_ANY_CHANGE>

=back

Upper limit of filters in SDL_AudioCVT

=over

C<SDL_AUDIOCVT_MAX_FILTERS> - The maximum number of SDL_AudioFilter functions
in SDL_AudioCVT is currently limited to 9. The C<SDL2::AudioCVT->filters( )>
array has 10 pointers, one of which is the terminating NULL pointer.

=back

=head1 C<:audiostatus>

Get the current audio state.

=over

=item C<SDL_AUDIO_STOPPED>

=item C<SDL_AUDIO_PLAYING>

=item C<SDL_AUDIO_PAUSED>

=back

=head1 C<:blendmode>

The blend mode used in L<< C<SDL_RenderCopy( ... )>|SDL::FFI/C<SDL_RenderCopy(
... )> >> and drawing operations.

=over

=item C<SDL_BLENDMODE_NONE> - no blending

    dstRGBA = srcRGBA

=item C<SDL_BLENDMODE_BLEND> - alpha blending

    dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
    dstA = srcA + (dstA * (1-srcA))

=item C<SDL_BLENDMODE_ADD> - additive blending

    dstRGB = (srcRGB * srcA) + dstRGB
    dstA = dstA

=item C<SDL_BLENDMODE_MOD> - color modulate

    dstRGB = srcRGB * dstRGB
    dstA = dstA

=item C<SDL_BLENDMODE_MUL> - color multiply

    dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
    dstA = (srcA * dstA) + (dstA * (1-srcA))

=item C<SDL_BLENDMODE_INVALID>

=back

Additional custom blend modes can be returned by L<<
C<SDL_ComposeCustomBlendMode( ... )>|SDL2::FFI/C<SDL_ComposeCustomBlendMode(
... )> >>.

=head2 C<:blendoperation>

The blend operation used when combining source and destination pixel
components.

=over

=item C<SDL_BLENDOPERATION_ADD> - supported by all renderers

    dst + src

=item C<SDL_BLENDOPERATION_SUBTRACT> - supported by D3D9, D3D11, OpenGL, OpenGLES

    dst - src

=item C<SDL_BLENDOPERATION_REV_SUBTRACT> - supported by D3D9, D3D11, OpenGL, OpenGLES

    src - dst

=item C<SDL_BLENDOPERATION_MINIMUM> - supported by D3D11

    min(dst, src)

=item C<SDL_BLENDOPERATION_MAXIMUM> - supported by D3D11

    max(dst, src)

=back

=head1 C<:blendfactor>

The normalized factor used to multiply pixel components.

=over

=item C<SDL_BLENDFACTOR_ZERO> - C< 0, 0, 0, 0 >

=item C<SDL_BLENDFACTOR_ONE> - C< 1, 1, 1, 1 >

=item C<SDL_BLENDFACTOR_SRC_COLOR> - C< srcR, srcG, srcB, srcA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR> - C< 1-srcR, 1-srcG, 1-srcB, 1-srcA >

=item C<SDL_BLENDFACTOR_SRC_ALPHA> - C< srcA, srcA, srcA, srcA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA> - C< 1-srcA, 1-srcA, 1-srcA, 1-srcA >

=item C<SDL_BLENDFACTOR_DST_COLOR> - C< dstR, dstG, dstB, dstA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR> - C< 1-dstR, 1-dstG, 1-dstB, 1-dstA >

=item C<SDL_BLENDFACTOR_DST_ALPHA> - C< dstA, dstA, dstA, dstA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA> - C< 1-dstA, 1-dstA, 1-dstA, 1-dstA >

=back

=head1 C<:errorcode>

=over

=item C<SDL_ENOMEM> - Out of memory

=item C<SDL_EFREAD> - Error reading file

=item C<SDL_EFWRITE> - Error writing file

=item C<SDL_EFSEEK> - Error seeking in file

=item C<SDL_UNSUPPORTED>

=item C<SDL_LASTERROR>

=back

=head1 C<:eventstate>

General keyboard/mouse state definitions

=over

=item C<SDL_RELEASED>

=item C<SDL_PRESSED>

=back

=head1 C<:eventtype>

The types of events that can be delivered.

=over

=item C<SDL_FIRSTEVENT> - Unused

=item C<SDL_QUIT> - User-requested quit

=item C<SDL_APP_TERMINATING> - The application is being terminated by the OS

Called on iOS in C<applicationWillTerminate()>

Called on Android in C<onDestroy()>

=item C<SDL_APP_LOWMEMORY> - The application is low on memory, free memory if possible

Called on iOS in C<applicationDidReceiveMemoryWarning()>

Called on Android in C<onLowMemory()>

=item C<SDL_APP_WILLENTERBACKGROUND> - The application is about to enter the background

Called on iOS in C<applicationWillResignActive()>

Called on Android in C<onPause()>

=item C<SDL_APP_DIDENTERBACKGROUND> - The application did enter the background and may not get CPU for some time

Called on iOS in C<applicationDidEnterBackground()>

Called on Android in C<onPause()>

=item C<SDL_APP_WILLENTERFOREGROUND> - The application is about to enter the foreground

Called on iOS in C<applicationWillEnterForeground()>

Called on Android in C<onResume()>

=item C<SDL_APP_DIDENTERFOREGROUND> - The application is now interactive

Called on iOS in C<applicationDidBecomeActive()>

Called on Android in C<onResume()>

=item C<SDL_LOCALECHANGED> - The user's locale preferences have changed

=item C<SDL_DISPLAYEVENT> - Display state change

=item C<SDL_WINDOWEVENT> - Window state change

=item C<SDL_SYSWMEVENT> - System specific event

=item C<SDL_KEYDOWN> - Key pressed

=item C<SDL_KEYUP> - Key released

=item C<SDL_TEXTEDITING> - Keyboard text editing (composition)

=item C<SDL_TEXTINPUT> - Keyboard text input

=item C<SDL_KEYMAPCHANGED> - Keymap changed due to a system event such as an input language or keyboard layout change

=item C<SDL_MOUSEMOTION> - Mouse moved

=item C<SDL_MOUSEBUTTONDOWN> - Mouse button pressed

=item C<SDL_MOUSEBUTTONUP> - Mouse button released

=item C<SDL_MOUSEWHEEL> - Mouse wheel motion

=item C<SDL_JOYAXISMOTION> - Joystick axis motion

=item C<SDL_JOYBALLMOTION> - Joystick trackball motion

=item C<SDL_JOYHATMOTION> - Joystick hat position change

=item C<SDL_JOYBUTTONDOWN> - Joystick button pressed

=item C<SDL_JOYBUTTONUP> - Joystick button released

=item C<SDL_JOYDEVICEADDED> - A new joystick has been inserted into the system

=item C<SDL_JOYDEVICEREMOVED> - An opened joystick has been removed

=item C<SDL_CONTROLLERAXISMOTION> - Game controller axis motion

=item C<SDL_CONTROLLERBUTTONDOWN> - Game controller button pressed

=item C<SDL_CONTROLLERBUTTONUP> - Game controller button released

=item C<SDL_CONTROLLERDEVICEADDED> - A new Game controller has been inserted into the system

=item C<SDL_CONTROLLERDEVICEREMOVED> - An opened Game controller has been removed

=item C<SDL_CONTROLLERDEVICEREMAPPED> - The controller mapping was updated

=item C<SDL_CONTROLLERTOUCHPADDOWN> - Game controller touchpad was touched

=item C<SDL_CONTROLLERTOUCHPADMOTION> - Game controller touchpad finger was moved

=item C<SDL_CONTROLLERTOUCHPADUP> - Game controller touchpad finger was lifted

=item C<SDL_CONTROLLERSENSORUPDATE> - Game controller sensor was updated

=item C<SDL_FINGERDOWN>

=item C<SDL_FINGERUP>

=item C<SDL_FINGERMOTION>

=item C<SDL_DOLLARGESTURE>

=item C<SDL_DOLLARRECORD>

=item C<SDL_MULTIGESTURE>

=item C<SDL_CLIPBOARDUPDATE> - The clipboard changed

=item C<SDL_DROPFILE> - The system requests a file open

=item C<SDL_DROPTEXT> - text/plain drag-and-drop event

=item C<SDL_DROPBEGIN> - A new set of drops is beginning (NULL filename)

=item C<SDL_DROPCOMPLETE> - Current set of drops is now complete (NULL filename)

=item C<SDL_AUDIODEVICEADDED> - A new audio device is available

=item C<SDL_AUDIODEVICEREMOVED> - An audio device has been removed

=item C<SDL_SENSORUPDATE> - A sensor was updated

=item C<SDL_RENDER_TARGETS_RESET> - The render targets have been reset and their contents need to be updated

=item C<SDL_RENDER_DEVICE_RESET> - The device has been reset and all textures need to be recreated

=item C<SDL_USEREVENT>

=item C<SDL_LASTEVENT> - This last event is only for bounding internal arrays

=back

Events C<SDL_USEREVENT> through C<SDL_LASTEVENT> are for your use and should be
allocated with  L<< C<SDL_RegisterEvents( ...
)>|SDL2::FFI/C<SDL_RegisterEvents( ... )> >>.

=head1 C<:eventState>

=over

=item C<SDL_QUERY>

=item C<SDL_IGNORE>

=item C<SDL_DISABLE>

=item C<SDL_ENABLE>

=back

=head1 C<:gameControllerType>

=over

=item C<SDL_CONTROLLER_TYPE_UNKNOWN>

=item C<SDL_CONTROLLER_TYPE_XBOX360>

=item C<SDL_CONTROLLER_TYPE_XBOXONE>

=item C<SDL_CONTROLLER_TYPE_PS3>

=item C<SDL_CONTROLLER_TYPE_PS4>

=item C<SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_PRO>

=item C<SDL_CONTROLLER_TYPE_VIRTUAL>

=item C<SDL_CONTROLLER_TYPE_PS5>

=back

=head1 C<:gameControllerBindType>

=over

=item C<SDL_CONTROLLER_BINDTYPE_NONE>

=item C<SDL_CONTROLLER_BINDTYPE_BUTTON>

=item C<SDL_CONTROLLER_BINDTYPE_AXIS>

=item C<SDL_CONTROLLER_BINDTYPE_HAT>

=back

=head2 C<:gameControllerAxis>

The list of axes available from a controller

Thumbstick axis values range from C<SDL_JOYSTICK_AXIS_MIN> to
C<SDL_JOYSTICK_AXIS_MAX>, and are centered within ~8000 of zero, though
advanced UI will allow users to set or autodetect the dead zone, which varies
between controllers.

Trigger axis values range from C<0> to C<SDL_JOYSTICK_AXIS_MAX>.

=over

=item C<SDL_CONTROLLER_AXIS_INVALID>

=item C<SDL_CONTROLLER_AXIS_LEFTX>

=item C<SDL_CONTROLLER_AXIS_LEFTY>

=item C<SDL_CONTROLLER_AXIS_RIGHTX>

=item C<SDL_CONTROLLER_AXIS_RIGHTY>

=item C<SDL_CONTROLLER_AXIS_TRIGGERLEFT>

=item C<SDL_CONTROLLER_AXIS_TRIGGERRIGHT>

=item C<SDL_CONTROLLER_AXIS_MAX>

=back

=head1 C<:gameControllerButton>

The list of buttons available from a controller

=over

=item C<SDL_CONTROLLER_BUTTON_INVALID>

=item C<SDL_CONTROLLER_BUTTON_A>

=item C<SDL_CONTROLLER_BUTTON_B>

=item C<SDL_CONTROLLER_BUTTON_X>

=item C<SDL_CONTROLLER_BUTTON_Y>

=item C<SDL_CONTROLLER_BUTTON_BACK>

=item C<SDL_CONTROLLER_BUTTON_GUIDE>

=item C<SDL_CONTROLLER_BUTTON_START>

=item C<SDL_CONTROLLER_BUTTON_LEFTSTICK>

=item C<SDL_CONTROLLER_BUTTON_RIGHTSTICK>

=item C<SDL_CONTROLLER_BUTTON_LEFTSHOULDER>

=item C<SDL_CONTROLLER_BUTTON_RIGHTSHOULDER>

=item C<SDL_CONTROLLER_BUTTON_DPAD_UP>

=item C<SDL_CONTROLLER_BUTTON_DPAD_DOWN>

=item C<SDL_CONTROLLER_BUTTON_DPAD_LEFT>

=item C<SDL_CONTROLLER_BUTTON_DPAD_RIGHT>

=item C<SDL_CONTROLLER_BUTTON_MISC1> - Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button

=item C<SDL_CONTROLLER_BUTTON_PADDLE1> - Xbox Elite paddle P1

=item C<SDL_CONTROLLER_BUTTON_PADDLE2> - Xbox Elite paddle P3

=item C<SDL_CONTROLLER_BUTTON_PADDLE3> - Xbox Elite paddle P2

=item C<SDL_CONTROLLER_BUTTON_PADDLE4> - Xbox Elite paddle P4

=item C<SDL_CONTROLLER_BUTTON_TOUCHPAD> - PS4/PS5 touchpad button

=item C<SDL_CONTROLLER_BUTTON_MAX>

=back

=head1 C<:haptic>

Different haptic features a device can have.

=over

=item C<SDL_HAPTIC_CONSTANT> - Constant haptic effect

=item C<SDL_HAPTIC_SINE> - Periodic haptic effect that simulates sine waves

=item C<SDL_HAPTIC_LEFTRIGHT> - Haptic effect for direct control over high/low frequency motors

=item C<SDL_HAPTIC_TRIANGLE> - Periodic haptic effect that simulates triangular waves

=item C<SDL_HAPTIC_SAWTOOTHUP> - Periodic haptic effect that simulates saw tooth up waves

=item C<SDL_HAPTIC_SAWTOOTHDOWN> - Periodic haptic effect that simulates saw tooth down waves

=item C<SDL_HAPTIC_RAMP> - Ramp haptic effect

=item C<SDL_HAPTIC_SPRING> - Condition haptic effect that simulates a spring.  Effect is based on the axes position

=item C<SDL_HAPTIC_DAMPER> - Condition haptic effect that simulates dampening.  Effect is based on the axes velocity

=item C<SDL_HAPTIC_INERTIA> - Condition haptic effect that simulates inertia.  Effect is based on the axes acceleration

=item C<SDL_HAPTIC_FRICTION> - Condition haptic effect that simulates friction.  Effect is based on the axes movement

=item C<SDL_HAPTIC_CUSTOM> - User defined custom haptic effect

=back

These last few are features the device has, not effects.

=over

=item C<SDL_HAPTIC_GAIN> - Device supports setting the global gain.

=item C<SDL_HAPTIC_AUTOCENTER> - Device supports setting autocenter

=item C<SDL_HAPTIC_STATUS> - Device supports querying effect status

=item C<SDL_HAPTIC_PAUSE> - Devices supports being paused

=back

Direction encodings

=over

=item C<SDL_HAPTIC_POLAR> - Uses polar coordinates for the direction

=item C<SDL_HAPTIC_CARTESIAN> - Uses cartesian coordinates for the direction

=item C<SDL_HAPTIC_SPHERICAL> - Uses spherical coordinates for the direction

=item C<SDL_HAPTIC_STEERING_AXIS> - Use this value to play an effect on the steering wheel axis. This provides better compatibility across platforms and devices as SDL will guess the correct axis

=back

Misc defines.

=over

=item C<SDL_HAPTIC_INFINITY> - Used to play a device an infinite number of times

=back

=head1 C<:hints>

An enumeration of hint priorities as C<SDL_HintPriority>.

=over

=item C<SDL_HINT_DEFAULT> - low priority, used for default values

=item C<SDL_HINT_NORMAL> - medium priority

=item C<SDL_HINT_OVERRIDE> - high priority

=back

The following enum values can be passed to L<Configuration
Variable|SDL2::FFI/Configuration Variables> related functions.

=over

=item C<SDL_HINT_ACCELEROMETER_AS_JOYSTICK>

A hint that specifies whether the Android / iOS built-in accelerometer should
be listed as a joystick device, rather than listing actual joysticks only.

Values:

    0   list only real joysticks and accept input from them
    1   list real joysticks along with the accelorometer as if it were a 3 axis joystick (the default)

Example:

    # This disables the use of gyroscopes as axis device
    SDL_SetHint(SDL_HINT_ACCELEROMETER_AS_JOYSTICK, "0");

=item C<SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION>

A hint that specifies the Android APK expansion main file version.

Values:

    X   the Android APK expansion main file version (should be a string number like "1", "2" etc.)

This hint must be set together with the hint
C<SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION>.

If both hints were set then C<SDL_RWFromFile( )> will look into expansion files
after a given relative path was not found in the internal storage and assets.

By default this hint is not set and the APK expansion files are not searched.

=item C<SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION>

A hint that specifies the Android APK expansion patch file version.

Values:

    X   the Android APK expansion patch file version (should be a string number like "1", "2" etc.)

This hint must be set together with the hint
C<SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION>.

If both hints were set then C<SDL_RWFromFile( )> will look into expansion files
after a given relative path was not found in the internal storage and assets.

By default this hint is not set and the APK expansion files are not searched.

=item C<SDL_HINT_ANDROID_SEPARATE_MOUSE_AND_TOUCH>

A hint that specifies a variable to control whether mouse and touch events are
to be treated together or separately.

Values:

    0   mouse events will be handled as touch events and touch will raise fake mouse events (default)
    1   mouse events will be handled separately from pure touch events

By default mouse events will be handled as touch events and touch will raise
fake mouse events.

The value of this hint is used at runtime, so it can be changed at any time.

=item C<SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS>

A hint that specifies whether controllers used with the Apple TV generate UI
events.

Values:

    0   controller input does not gnerate UI events (default)
    1   controller input generates UI events

When UI events are generated by controller input, the app will be backgrounded
when the Apple TV remote's menu button is pressed, and when the pause or B
buttons on gamepads are pressed.

More information about properly making use of controllers for the Apple TV can
be found here:
https://developer.apple.com/tvos/human-interface-guidelines/remote-and-controllers/

=item C<SDL_HINT_APPLE_TV_REMOTE_ALLOW_ROTATION>

A hint that specifies whether the Apple TV remote's joystick axes will
automatically match the rotation of the remote.


Values:

    0   remote orientation does not affect joystick axes (default)
    1   joystick axes are based on the orientation of the remote

=item C<SDL_HINT_BMP_SAVE_LEGACY_FORMAT>

A hint that specifies whether SDL should not use version 4 of the bitmap header
when saving BMPs.

Values:

    0   version 4 of the bitmap header will be used when saving BMPs (default)
    1   version 4 of the bitmap header will not be used when saving BMPs

The bitmap header version 4 is required for proper alpha channel support and
SDL will use it when required. Should this not be desired, this hint can force
the use of the 40 byte header version which is supported everywhere.

If the hint is not set then surfaces with a colorkey or an alpha channel are
saved to a 32-bit BMP file with an alpha mask. SDL will use the bitmap header
version 4 and set the alpha mask accordingly. This is the default behavior
since SDL 2.0.5.

If the hint is set then surfaces with a colorkey or an alpha channel are saved
to a 32-bit BMP file without an alpha mask. The alpha channel data will be in
the file, but applications are going to ignore it. This was the default
behavior before SDL 2.0.5.

=item C<SDL_HINT_EMSCRIPTEN_ASYNCIFY>

A hint that specifies if SDL should give back control to the browser
automatically when running with asyncify.

Values:

    0   disable emscripten_sleep calls (if you give back browser control manually or use asyncify for other purposes)
    1   enable emscripten_sleep calls (default)

This hint only applies to the Emscripten platform.

=item C<SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT>

A hint that specifies a value to override the binding element for keyboard
inputs for Emscripten builds.

Values:

    #window     the JavaScript window object (default)
    #document   the JavaScript document object
    #screen     the JavaScript window.screen object
    #canvas     the default WebGL canvas element

Any other string without a leading # sign applies to the element on the page
with that ID.

This hint only applies to the Emscripten platform.

=item C<SDL_HINT_FRAMEBUFFER_ACCELERATION>

A hint that specifies how 3D acceleration is used with L<SDL_GetWindowSurface(
... )|SDL2/SDL_GetWindowSurface( ... )>.

Values:

    0   disable 3D acceleration
    1   enable 3D acceleration, using the default renderer
    X   enable 3D acceleration, using X where X is one of the valid rendering drivers. (e.g. "direct3d", "opengl", etc.)

By default SDL tries to make a best guess whether to use acceleration or not on
each platform.

SDL can try to accelerate the screen surface returned by
L<SDL_GetWindowSurface( ... )|SDL2/SDL_GetWindowSurface( ... )> by using
streaming textures with a 3D rendering engine. This variable controls whether
and how this is done.

=item C<SDL_HINT_GAMECONTROLLERCONFIG>

A variable that lets you provide a file with extra gamecontroller db entries.

This hint must be set before calling C<SDL_Init(SDL_INIT_GAMECONTROLLER)>.

You can update mappings after the system is initialized with
C<SDL_GameControllerMappingForGUID( )> and C<SDL_GameControllerAddMapping( )>.

=item C<SDL_HINT_GRAB_KEYBOARD>

A variable setting the double click time, in milliseconds.

=item C<SDL_HINT_IDLE_TIMER_DISABLED>

A hint that specifies a variable controlling whether the idle timer is disabled
on iOS.

Values:

    0   enable idle timer (default)
    1   disable idle timer

When an iOS application does not receive touches for some time, the screen is
dimmed automatically. For games where the accelerometer is the only input this
is problematic. This functionality can be disabled by setting this hint.

As of SDL 2.0.4, C<SDL_EnableScreenSaver( )> and C<SDL_DisableScreenSaver( )>
accomplish the same thing on iOS. They should be preferred over this hint.

=item C<SDL_HINT_IME_INTERNAL_EDITING>

A variable to control whether we trap the Android back button to handle it
manually. This is necessary for the right mouse button to work on some Android
devices, or to be able to trap the back button for use in your code reliably.
If set to true, the back button will show up as an C<SDL_KEYDOWN> /
C<SDL_KEYUP> pair with a keycode of C<SDL_SCANCODE_AC_BACK>.

The variable can be set to the following values:

    0   Back button will be handled as usual for system. (default)
    1   Back button will be trapped, allowing you to handle the key press
        manually. (This will also let right mouse click work on systems
        where the right mouse button functions as back.)

The value of this hint is used at runtime, so it can be changed at any time.

=item C<SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS>

A variable controlling whether the HIDAPI joystick drivers should be used.

This variable can be set to the following values:

    0   HIDAPI drivers are not used
    1   HIDAPI drivers are used (default)

This variable is the default for all drivers, but can be overridden by the
hints for specific drivers below.

=item C<SDL_HINT_MAC_BACKGROUND_APP>

A hint that specifies if the SDL app should not be forced to become a
foreground process on Mac OS X.

Values:

    0   force the SDL app to become a foreground process (default)
    1   do not force the SDL app to become a foreground process

This hint only applies to Mac OSX.

=item C<SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK>

A hint that specifies whether ctrl+click should generate a right-click event on
Mac.

Values:

    0   disable emulating right click (default)
    1   enable emulating right click

=item C<SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH>

A hint that specifies if mouse click events are sent when clicking to focus an
SDL window.

Values:

    0   no mouse click events are sent when clicking to focus (default)
    1   mouse click events are sent when clicking to focus

=item C<SDL_HINT_MOUSE_RELATIVE_MODE_WARP>

A hint that specifies whether relative mouse mode is implemented using mouse
warping.

Values:

    0   relative mouse mode uses the raw input (default)
    1   relative mouse mode uses mouse warping

=item C<SDL_HINT_NO_SIGNAL_HANDLERS>

A hint that specifies not to catch the C<SIGINT> or C<SIGTERM> signals.

Values:

    0   SDL will install a SIGINT and SIGTERM handler, and when it
        catches a signal, convert it into an SDL_QUIT event
    1   SDL will not install a signal handler at all

=item C<SDL_HINT_ORIENTATIONS>

A variable controlling which orientations are allowed on iOS/Android.

In some circumstances it is necessary to be able to explicitly control which UI
orientations are allowed.

This variable is a space delimited list of the following values:

=over

=item C<LandscapeLeft>

=item C<LandscapeRight>

=item C<Portrait>

=item C<PortraitUpsideDown>

=back

=item C<SDL_HINT_RENDER_DIRECT3D11_DEBUG>

A variable controlling whether to enable Direct3D 11+'s Debug Layer.

This variable does not have any effect on the Direct3D 9 based renderer.

This variable can be set to the following values:

    0   Disable Debug Layer use (default)
    1   Enable Debug Layer use

=item C<SDL_HINT_RENDER_DIRECT3D_THREADSAFE>

A variable controlling whether the Direct3D device is initialized for
thread-safe operations.

This variable can be set to the following values:

    0   Thread-safety is not enabled (faster; default)
    1   Thread-safety is enabled

=item C<SDL_HINT_RENDER_DRIVER>

A variable specifying which render driver to use.

If the application doesn't pick a specific renderer to use, this variable
specifies the name of the preferred renderer. If the preferred renderer can't
be initialized, the normal default renderer is used.

This variable is case insensitive and can be set to the following values:

=over

=item C<direct3d>

=item C<opengl>

=item C<opengles2>

=item C<opengles>

=item C<metal>

=item C<software>

=back

The default varies by platform, but it's the first one in the list that is
available on the current platform.

=item C<SDL_HINT_RENDER_OPENGL_SHADERS>

A variable controlling whether the OpenGL render driver uses shaders if they
are available.

This variable can be set to the following values:

    0   Disable shaders
    1   Enable shaders (default)

=item C<SDL_HINT_RENDER_SCALE_QUALITY>

A variable controlling the scaling quality

This variable can be set to the following values:     0 or nearest    Nearest
pixel sampling (default)     1 or linear     Linear filtering (supported by
OpenGL and Direct3D)     2 or best       Currently this is the same as linear

=item C<SDL_HINT_RENDER_VSYNC>

A variable controlling whether updates to the SDL screen surface should be
synchronized with the vertical refresh, to avoid tearing.

This variable can be set to the following values:

    0   Disable vsync
    1   Enable vsync

By default SDL does not sync screen surface updates with vertical refresh.

=item C<SDL_HINT_RPI_VIDEO_LAYER>

Tell SDL which Dispmanx layer to use on a Raspberry PI

Also known as Z-order. The variable can take a negative or positive value.

The default is C<10000>.

=item C<SDL_HINT_THREAD_STACK_SIZE>

A string specifying SDL's threads stack size in bytes or C<0> for the backend's
default size

Use this hint in case you need to set SDL's threads stack size to other than
the default. This is specially useful if you build SDL against a non glibc libc
library (such as musl) which provides a relatively small default thread stack
size (a few kilobytes versus the default 8MB glibc uses). Support for this hint
is currently available only in the pthread, Windows, and PSP backend.

Instead of this hint, in 2.0.9 and later, you can use
C<SDL_CreateThreadWithStackSize( )>. This hint only works with the classic
C<SDL_CreateThread( )>.

=item C<SDL_HINT_TIMER_RESOLUTION>

A variable that controls the timer resolution, in milliseconds.

he higher resolution the timer, the more frequently the CPU services timer
interrupts, and the more precise delays are, but this takes up power and CPU
time.  This hint is only used on Windows.

See this blog post for more information:
L<http://randomascii.wordpress.com/2013/07/08/windows-timer-resolution-megawatts-wasted/>

If this variable is set to C<0>, the system timer resolution is not set.

The default value is C<1>. This hint may be set at any time.

=item C<SDL_HINT_VIDEO_ALLOW_SCREENSAVER>

A variable controlling whether the screensaver is enabled.

This variable can be set to the following values:

    0   Disable screensaver
    1   Enable screensaver

By default SDL will disable the screensaver.

=item C<SDL_HINT_VIDEO_HIGHDPI_DISABLED>

If set to C<1>, then do not allow high-DPI windows. ("Retina" on Mac and iOS)

=item C<SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES>

A variable that dictates policy for fullscreen Spaces on Mac OS X.

This hint only applies to Mac OS X.

The variable can be set to the following values:

    0   Disable Spaces support (FULLSCREEN_DESKTOP won't use them and
        SDL_WINDOW_RESIZABLE windows won't offer the "fullscreen"
        button on their titlebars).
    1   Enable Spaces support (FULLSCREEN_DESKTOP will use them and
        SDL_WINDOW_RESIZABLE windows will offer the "fullscreen"
        button on their titlebars).

The default value is C<1>. Spaces are disabled regardless of this hint if the
OS isn't at least Mac OS X Lion (10.7). This hint must be set before any
windows are created.

=item C<SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS>

Minimize your C<SDL_Window> if it loses key focus when in fullscreen mode.
Defaults to false.

Warning: Before SDL 2.0.14, this defaulted to true! In 2.0.14, we're seeing if
"true" causes more problems than it solves in modern times.

=item C<SDL_HINT_VIDEO_WIN_D3DCOMPILER>

A variable specifying which shader compiler to preload when using the Chrome
ANGLE binaries

SDL has EGL and OpenGL ES2 support on Windows via the ANGLE project. It can use
two different sets of binaries, those compiled by the user from source or those
provided by the Chrome browser. In the later case, these binaries require that
SDL loads a DLL providing the shader compiler.

This variable can be set to the following values:

=over

=item C<d3dcompiler_46.dll>

default, best for Vista or later.

=item C<d3dcompiler_43.dll>

for XP support.

=item C<none>

do not load any library, useful if you compiled ANGLE from source and included
the compiler in your binaries.

=back

=item C<SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT>

A variable that is the address of another C<SDL_Window*> (as a hex string
formatted with C<%p>).

If this hint is set before C<SDL_CreateWindowFrom( )> and the C<SDL_Window*> it
is set to has C<SDL_WINDOW_OPENGL> set (and running on WGL only, currently),
then two things will occur on the newly created C<SDL_Window>:

=over

=item 1. Its pixel format will be set to the same pixel format as this C<SDL_Window>. This is needed for example when sharing an OpenGL context across multiple windows.

=item 2. The flag SDL_WINDOW_OPENGL will be set on the new window so it can be used for OpenGL rendering.

=back

This variable can be set to the address (as a string C<%p>) of the
C<SDL_Window*> that new windows created with L<< C<SDL_CreateWindowFrom( ...
)>|/C<SDL_CreateWindowFrom( ... )> >>should share a pixel format with.

=item C<SDL_HINT_VIDEO_X11_NET_WM_PING>

A variable controlling whether the X11 _NET_WM_PING protocol should be
supported.

This variable can be set to the following values:

    0    Disable _NET_WM_PING
    1   Enable _NET_WM_PING

By default SDL will use _NET_WM_PING, but for applications that know they will
not always be able to respond to ping requests in a timely manner they can turn
it off to avoid the window manager thinking the app is hung. The hint is
checked in CreateWindow.

=item C<SDL_HINT_VIDEO_X11_XINERAMA>

A variable controlling whether the X11 Xinerama extension should be used.

This variable can be set to the following values:

    0   Disable Xinerama
    1   Enable Xinerama

By default SDL will use Xinerama if it is available.

=item C<SDL_HINT_VIDEO_X11_XRANDR>

A variable controlling whether the X11 XRandR extension should be used.

This variable can be set to the following values:

    0   Disable XRandR
    1   Enable XRandR

By default SDL will not use XRandR because of window manager issues.

=item C<SDL_HINT_VIDEO_X11_XVIDMODE>

A variable controlling whether the X11 VidMode extension should be used.

This variable can be set to the following values:

    0   Disable XVidMode
    1   Enable XVidMode

By default SDL will use XVidMode if it is available.

=item C<SDL_HINT_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN>

A variable controlling whether the window frame and title bar are interactive
when the cursor is hidden.

This variable can be set to the following values:

    0   The window frame is not interactive when the cursor is hidden (no move, resize, etc)
    1   The window frame is interactive when the cursor is hidden

By default SDL will allow interaction with the window frame when the cursor is
hidden.

=item C<SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING>

Tell SDL not to name threads on Windows with the 0x406D1388 Exception. The
0x406D1388 Exception is a trick used to inform Visual Studio of a thread's
name, but it tends to cause problems with other debuggers, and the .NET
runtime. Note that SDL 2.0.6 and later will still use the (safer)
SetThreadDescription API, introduced in the Windows 10 Creators Update, if
available.

The variable can be set to the following values:

    0   SDL will raise the 0x406D1388 Exception to name threads.
        This is the default behavior of SDL <= 2.0.4.
    1   SDL will not raise this exception, and threads will be unnamed. (default)
        This is necessary with .NET languages or debuggers that aren't Visual Studio.

=item C<SDL_HINT_WINDOWS_INTRESOURCE_ICON>

A variable to specify custom icon resource id from RC file on Windows platform.

=item C<SDL_HINT_WINDOWS_INTRESOURCE_ICON_SMALL>

A variable to specify custom icon resource id from RC file on Windows platform.

=item C<SDL_HINT_WINDOWS_ENABLE_MESSAGELOOP>

A variable controlling whether the windows message loop is processed by SDL .

This variable can be set to the following values:

    0   The window message loop is not run
    1   The window message loop is processed in SDL_PumpEvents( )

By default SDL will process the windows message loop.

=item C<SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4>

Tell SDL not to generate window-close events for Alt+F4 on Windows.

The variable can be set to the following values:

    0   SDL will generate a window-close event when it sees Alt+F4.
    1   SDL will only do normal key handling for Alt+F4.

=item C<SDL_HINT_WINRT_HANDLE_BACK_BUTTON>

Allows back-button-press events on Windows Phone to be marked as handled.

Windows Phone devices typically feature a Back button.  When pressed, the OS
will emit back-button-press events, which apps are expected to handle in an
appropriate manner.  If apps do not explicitly mark these events as 'Handled',
then the OS will invoke its default behavior for unhandled back-button-press
events, which on Windows Phone 8 and 8.1 is to terminate the app (and attempt
to switch to the previous app, or to the device's home screen).

Setting the C<SDL_HINT_WINRT_HANDLE_BACK_BUTTON> hint to "1" will cause SDL to
mark back-button-press events as Handled, if and when one is sent to the app.

Internally, Windows Phone sends back button events as parameters to special
back-button-press callback functions.  Apps that need to respond to
back-button-press events are expected to register one or more callback
functions for such, shortly after being launched (during the app's
initialization phase).  After the back button is pressed, the OS will invoke
these callbacks.  If the app's callback(s) do not explicitly mark the event as
handled by the time they return, or if the app never registers one of these
callback, the OS will consider the event un-handled, and it will apply its
default back button behavior (terminate the app).

SDL registers its own back-button-press callback with the Windows Phone OS.
This callback will emit a pair of SDL key-press events (C<SDL_KEYDOWN> and
C<SDL_KEYUP>), each with a scancode of SDL_SCANCODE_AC_BACK, after which it
will check the contents of the hint, C<SDL_HINT_WINRT_HANDLE_BACK_BUTTON>. If
the hint's value is set to C<1>, the back button event's Handled property will
get set to a C<true> value. If the hint's value is set to something else, or if
it is unset, SDL will leave the event's Handled property alone. (By default,
the OS sets this property to 'false', to note.)

SDL apps can either set C<SDL_HINT_WINRT_HANDLE_BACK_BUTTON> well before a back
button is pressed, or can set it in direct-response to a back button being
pressed.

In order to get notified when a back button is pressed, SDL apps should
register a callback function with C<SDL_AddEventWatch( )>, and have it listen
for C<SDL_KEYDOWN> events that have a scancode of C<SDL_SCANCODE_AC_BACK>.
(Alternatively, C<SDL_KEYUP> events can be listened-for. Listening for either
event type is suitable.)  Any value of C<SDL_HINT_WINRT_HANDLE_BACK_BUTTON> set
by such a callback, will be applied to the OS' current back-button-press event.

More details on back button behavior in Windows Phone apps can be found at the
following page, on Microsoft's developer site:
L<http://msdn.microsoft.com/en-us/library/windowsphone/develop/jj247550(v=vs.105).aspx>

=item C<SDL_HINT_WINRT_PRIVACY_POLICY_LABEL>

Label text for a WinRT app's privacy policy link.

Network-enabled WinRT apps must include a privacy policy. On Windows 8, 8.1,
and RT, Microsoft mandates that this policy be available via the Windows
Settings charm. SDL provides code to add a link there, with its label text
being set via the optional hint, C<SDL_HINT_WINRT_PRIVACY_POLICY_LABEL>.

Please note that a privacy policy's contents are not set via this hint.  A
separate hint, C<SDL_HINT_WINRT_PRIVACY_POLICY_URL>, is used to link to the
actual text of the policy.

The contents of this hint should be encoded as a UTF8 string.

The default value is "Privacy Policy". This hint should only be set during app
initialization, preferably before any calls to L<< C<SDL_Init( ...
)>|/C<SDL_Init( ... )> >>.

For additional information on linking to a privacy policy, see the
documentation for C<SDL_HINT_WINRT_PRIVACY_POLICY_URL>.

=item C<SDL_HINT_WINRT_PRIVACY_POLICY_URL>

A URL to a WinRT app's privacy policy.

All network-enabled WinRT apps must make a privacy policy available to its
users.  On Windows 8, 8.1, and RT, Microsoft mandates that this policy be be
available in the Windows Settings charm, as accessed from within the app. SDL
provides code to add a URL-based link there, which can point to the app's
privacy policy.

To setup a URL to an app's privacy policy, set
C<SDL_HINT_WINRT_PRIVACY_POLICY_URL> before calling any L<< C<SDL_Init( ...
)>|/C<SDL_Init( ... )> >> functions.  The contents of the hint should be a
valid URL.  For example, L<http://www.example.com>.

The default value is an empty string (C<>), which will prevent SDL from adding
a privacy policy link to the Settings charm. This hint should only be set
during app init.

The label text of an app's "Privacy Policy" link may be customized via another
hint, C<SDL_HINT_WINRT_PRIVACY_POLICY_LABEL>.

Please note that on Windows Phone, Microsoft does not provide standard UI for
displaying a privacy policy link, and as such,
SDL_HINT_WINRT_PRIVACY_POLICY_URL will not get used on that platform.
Network-enabled phone apps should display their privacy policy through some
other, in-app means.

=item C<SDL_HINT_XINPUT_ENABLED>

A variable that lets you disable the detection and use of Xinput gamepad
devices

The variable can be set to the following values:

    0   Disable XInput detection (only uses direct input)
    1   Enable XInput detection (default)

=item C<SDL_HINT_XINPUT_USE_OLD_JOYSTICK_MAPPING>

A variable that causes SDL to use the old axis and button mapping for XInput
devices.

This hint is for backwards compatibility only and will be removed in SDL 2.1

The default value is C<0>.  This hint must be set before L<< C<SDL_Init( ...
)>|/C<SDL_Init( ... )> >>

=item C<SDL_HINT_QTWAYLAND_WINDOW_FLAGS>

Flags to set on QtWayland windows to integrate with the native window manager.

On QtWayland platforms, this hint controls the flags to set on the windows. For
example, on Sailfish OS, C<OverridesSystemGestures> disables swipe gestures.

This variable is a space-separated list of the following values (empty = no
flags):

=over

=item C<OverridesSystemGestures>

=item C<StaysOnTop>

=item C<BypassWindowManager>

=back

=item C<SDL_HINT_QTWAYLAND_CONTENT_ORIENTATION>

A variable describing the content orientation on QtWayland-based platforms.

On QtWayland platforms, windows are rotated client-side to allow for custom
transitions. In order to correctly position overlays (e.g. volume bar) and
gestures (e.g. events view, close/minimize gestures), the system needs to know
in which orientation the application is currently drawing its contents.

This does not cause the window to be rotated or resized, the application needs
to take care of drawing the content in the right orientation (the framebuffer
is always in portrait mode).

This variable can be one of the following values:

=over

=item C<primary> (default)

=item C<portrait>

=item C<landscape>

=item C<inverted-portrait>

=item C<inverted-landscape>

=back

=item C<SDL_HINT_RENDER_LOGICAL_SIZE_MODE>

A variable controlling the scaling policy for C<SDL_RenderSetLogicalSize>.

This variable can be set to the following values:

=over

=item C<0> or C<letterbox>

Uses letterbox/sidebars to fit the entire rendering on screen.

=item C<1> or C<overscan>

Will zoom the rendering so it fills the entire screen, allowing edges to be
drawn offscreen.

=back

By default letterbox is used.

=item C<SDL_HINT_VIDEO_EXTERNAL_CONTEXT>

A variable controlling whether the graphics context is externally managed.

This variable can be set to the following values:

    0   SDL will manage graphics contexts that are attached to windows.
    1   Disable graphics context management on windows.

By default SDL will manage OpenGL contexts in certain situations. For example,
on Android the context will be automatically saved and restored when pausing
the application. Additionally, some platforms will assume usage of OpenGL if
Vulkan isn't used. Setting this to C<1> will prevent this behavior, which is
desirable when the application manages the graphics context, such as an
externally managed OpenGL context or attaching a Vulkan surface to the window.

=item <SDL_HINT_VIDEO_X11_WINDOW_VISUALID>

A variable forcing the visual ID chosen for new X11 windows.

=item C<SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR>

A variable controlling whether the X11 _NET_WM_BYPASS_COMPOSITOR hint should be
used.

This variable can be set to the following values:

    0   Disable _NET_WM_BYPASS_COMPOSITOR
    1   Enable _NET_WM_BYPASS_COMPOSITOR

By default SDL will use _NET_WM_BYPASS_COMPOSITOR.

=item C<SDL_HINT_VIDEO_X11_FORCE_EGL>

A variable controlling whether X11 should use GLX or EGL by default

This variable can be set to the following values:

    0   Use GLX
    1   Use EGL

By default SDL will use GLX when both are present.

=item C<SDL_HINT_MOUSE_DOUBLE_CLICK_TIME>

A variable setting the double click time, in milliseconds.

=item C<SDL_HINT_MOUSE_DOUBLE_CLICK_RADIUS>

A variable setting the double click radius, in pixels.

=item C<SDL_HINT_MOUSE_NORMAL_SPEED_SCALE>

A variable setting the speed scale for mouse motion, in floating point, when
the mouse is not in relative mode.

=item C<SDL_HINT_MOUSE_RELATIVE_SPEED_SCALE>

A variable setting the scale for mouse motion, in floating point, when the
mouse is in relative mode.

=item C<SDL_HINT_MOUSE_RELATIVE_SCALING>

A variable controlling whether relative mouse motion is affected by renderer
scaling

This variable can be set to the following values:

    0   Relative motion is unaffected by DPI or renderer's logical size
    1   Relative motion is scaled according to DPI scaling and logical size

By default relative mouse deltas are affected by DPI and renderer scaling.

=item C<SDL_HINT_TOUCH_MOUSE_EVENTS>

A variable controlling whether touch events should generate synthetic mouse
events

This variable can be set to the following values:

    0   Touch events will not generate mouse events
    1   Touch events will generate mouse events

By default SDL will generate mouse events for touch events.

=item C<SDL_HINT_MOUSE_TOUCH_EVENTS>

A variable controlling whether mouse events should generate synthetic touch
events

This variable can be set to the following values:

    0   Mouse events will not generate touch events (default for desktop platforms)
    1   Mouse events will generate touch events (default for mobile platforms, such as Android and iOS)

=item C<SDL_HINT_IOS_HIDE_HOME_INDICATOR>

A variable controlling whether the home indicator bar on iPhone X should be
hidden.

This variable can be set to the following values:

    0   The indicator bar is not hidden (default for windowed applications)
    1   The indicator bar is hidden and is shown when the screen is touched (useful for movie playback applications)
    2   The indicator bar is dim and the first swipe makes it visible and the second swipe performs the "home" action (default for fullscreen applications)

=item C<SDL_HINT_TV_REMOTE_AS_JOYSTICK>

A variable controlling whether the Android / tvOS remotes should be listed as
joystick devices, instead of sending keyboard events.

This variable can be set to the following values:

    0   Remotes send enter/escape/arrow key events
    1   Remotes are available as 2 axis, 2 button joysticks (the default).

=item C<SDL_HINT_GAMECONTROLLERTYPE>

A variable that overrides the automatic controller type detection

The variable should be comma separated entries, in the form: VID/PID=type

The VID and PID should be hexadecimal with exactly 4 digits, e.g. C<0x00fd>

The type should be one of:

=over

=item C<Xbox360>

=item C<XboxOne>

=item C<PS3>

=item C<PS4>

=item C<PS5>

=item C<SwitchPro>

This hint affects what driver is used, and must be set before calling
C<SDL_Init(SDL_INIT_GAMECONTROLLER)>.

=item C<SDL_HINT_GAMECONTROLLERCONFIG_FILE>

A variable that lets you provide a file with extra gamecontroller db entries.

The file should contain lines of gamecontroller config data, see
SDL_gamecontroller.h

This hint must be set before calling C<SDL_Init(SDL_INIT_GAMECONTROLLER)>

You can update mappings after the system is initialized with
C<SDL_GameControllerMappingForGUID( )> and C<SDL_GameControllerAddMapping( )>.

=item C<SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES>

A variable containing a list of devices to skip when scanning for game
controllers.

The format of the string is a comma separated list of USB VID/PID pairs in
hexadecimal form, e.g.

    0xAAAA/0xBBBB,0xCCCC/0xDDDD

The variable can also take the form of @file, in which case the named file will
be loaded and interpreted as the value of the variable.

=item C<SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT>

If set, all devices will be skipped when scanning for game controllers except
for the ones listed in this variable.

The format of the string is a comma separated list of USB VID/PID pairs in
hexadecimal form, e.g.

    0xAAAA/0xBBBB,0xCCCC/0xDDDD

The variable can also take the form of @file, in which case the named file will
be loaded and interpreted as the value of the variable.

=item C<SDL_HINT_GAMECONTROLLER_USE_BUTTON_LABELS>

If set, game controller face buttons report their values according to their
labels instead of their positional layout.

For example, on Nintendo Switch controllers, normally you'd get:

        (Y)
    (X)     (B)
        (A)

but if this hint is set, you'll get:

        (X)
    (Y)     (A)
        (B)

The variable can be set to the following values:

    0   Report the face buttons by position, as though they were on an Xbox controller.
    1   Report the face buttons by label instead of position

The default value is C<1>. This hint may be set at any time.

=item C<SDL_HINT_JOYSTICK_HIDAPI>

A variable controlling whether the HIDAPI joystick drivers should be used.

This variable can be set to the following values:

    0   HIDAPI drivers are not used
    1   HIDAPI drivers are used (the default)

This variable is the default for all drivers, but can be overridden by the
hints for specific drivers below.

=item C<SDL_HINT_JOYSTICK_HIDAPI_PS4>

A variable controlling whether the HIDAPI driver for PS4 controllers should be
used.

This variable can be set to the following values:

    0   HIDAPI driver is not used
    1   HIDAPI driver is used

The default is the value of C<SDL_HINT_JOYSTICK_HIDAPI>

=item C<SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE>

A variable controlling whether extended input reports should be used for PS4
controllers when using the HIDAPI driver.

This variable can be set to the following values:

    0   extended reports are not enabled (default)
    1   extended reports

Extended input reports allow rumble on Bluetooth PS4 controllers, but break
DirectInput handling for applications that don't use SDL.

Once extended reports are enabled, they can not be disabled without power
cycling the controller.

For compatibility with applications written for versions of SDL prior to the
introduction of PS5 controller support, this value will also control the state
of extended reports on PS5 controllers when the
C<SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE> hint is not explicitly set.

=item C<SDL_HINT_JOYSTICK_HIDAPI_PS5>

A variable controlling whether the HIDAPI driver for PS5 controllers should be
used.

This variable can be set to the following values:

    0   HIDAPI driver is not used
    1   HIDAPI driver is used

The default is the value of C<SDL_HINT_JOYSTICK_HIDAPI>.

=item C<SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE>

A variable controlling whether extended input reports should be used for PS5
controllers when using the HIDAPI driver.

This variable can be set to the following values:

    0   extended reports are not enabled (default)
    1   extended reports

Extended input reports allow rumble on Bluetooth PS5 controllers, but break
DirectInput handling for applications that don't use SDL.

Once extended reports are enabled, they can not be disabled without power
cycling the controller.

For compatibility with applications written for versions of SDL prior to the
introduction of PS5 controller support, this value defaults to the value of
C<SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE>.

=item C<SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED>

A variable controlling whether the player LEDs should be lit to indicate which
player is associated with a PS5 controller.

This variable can be set to the following values:

    0   player LEDs are not enabled
    1   player LEDs are enabled (default)

=item C<SDL_HINT_JOYSTICK_HIDAPI_STADIA>

A variable controlling whether the HIDAPI driver for Google Stadia controllers
should be used.

This variable can be set to the following values:

    0   HIDAPI driver is not used
    1   HIDAPI driver is used

The default is the value of C<SDL_HINT_JOYSTICK_HIDAPI>.

=item C<SDL_HINT_JOYSTICK_HIDAPI_STEAM>

A variable controlling whether the HIDAPI driver for Steam Controllers should
be used.

This variable can be set to the following values:

    0   HIDAPI driver is not used
    1   HIDAPI driver is used

The default is the value of C<SDL_HINT_JOYSTICK_HIDAPI>.

=item C<SDL_HINT_JOYSTICK_HIDAPI_SWITCH>

A variable controlling whether the HIDAPI driver for Nintendo Switch
controllers should be used.

This variable can be set to the following values:

    0   HIDAPI driver is not used
    1   HIDAPI driver is used

The default is the value of C<SDL_HINT_JOYSTICK_HIDAPI>.

=item C<SDL_HINT_JOYSTICK_HIDAPI_SWITCH_HOME_LED>

A variable controlling whether the Home button LED should be turned on when a
Nintendo Switch controller is opened

This variable can be set to the following values:

    0   home button LED is left off
    1   home button LED is turned on (default)

=item C<SDL_HINT_JOYSTICK_HIDAPI_JOY_CONS>

A variable controlling whether Switch Joy-Cons should be treated the same as
Switch Pro Controllers when using the HIDAPI driver.

This variable can be set to the following values:

    0   basic Joy-Con support with no analog input (default)
    1   Joy-Cons treated as half full Pro Controllers with analog inputs and sensors

This does not combine Joy-Cons into a single controller. That's up to the user.

=item C<SDL_HINT_JOYSTICK_HIDAPI_XBOX>

A variable controlling whether the HIDAPI driver for XBox controllers should be
used.

This variable can be set to the following values:

    0   HIDAPI driver is not used
    1   HIDAPI driver is used

The default is C<0> on Windows, otherwise the value of
C<SDL_HINT_JOYSTICK_HIDAPI>.

=item C<SDL_HINT_JOYSTICK_HIDAPI_CORRELATE_XINPUT>

A variable controlling whether the HIDAPI driver for XBox controllers on
Windows should pull correlated data from XInput.

This variable can be set to the following values:

    0   HIDAPI Xbox driver will only use HIDAPI data
    1   HIDAPI Xbox driver will also pull data from XInput, providing better trigger axes, guide button
        presses, and rumble support

The default is C<1>.  This hint applies to any joysticks opened after setting
the hint.

=item C<SDL_HINT_JOYSTICK_HIDAPI_GAMECUBE>

A variable controlling whether the HIDAPI driver for Nintendo GameCube
controllers should be used.

This variable can be set to the following values:

    0   HIDAPI driver is not used
    1   HIDAPI driver is used

The default is the value of C<SDL_HINT_JOYSTICK_HIDAPI>.

=item C<SDL_HINT_ENABLE_STEAM_CONTROLLERS>

A variable that controls whether Steam Controllers should be exposed using the
SDL joystick and game controller APIs

The variable can be set to the following values:

    0   Do not scan for Steam Controllers
    1   Scan for Steam Controllers (default)

The default value is C<1>.  This hint must be set before initializing the
joystick subsystem.

=item C<SDL_HINT_JOYSTICK_RAWINPUT>

A variable controlling whether the RAWINPUT joystick drivers should be used for
better handling XInput-capable devices.

This variable can be set to the following values:

    0   RAWINPUT drivers are not used
    1   RAWINPUT drivers are used (default)

=item C<SDL_HINT_JOYSTICK_THREAD>

A variable controlling whether a separate thread should be used for handling
joystick detection and raw input messages on Windows

This variable can be set to the following values:

    0   A separate thread is not used (default)
    1   A separate thread is used for handling raw input messages

=item C<SDL_HINT_LINUX_JOYSTICK_DEADZONES>

A variable controlling whether joysticks on Linux adhere to their HID-defined
deadzones or return unfiltered values.

This variable can be set to the following values:

    0   Return unfiltered joystick axis values (default)
    1   Return axis values with deadzones taken into account

=item C<SDL_HINT_ALLOW_TOPMOST>

If set to C<0> then never set the top most bit on a SDL Window, even if the
video mode expects it. This is a debugging aid for developers and not expected
to be used by end users. The default is C<1>.

This variable can be set to the following values:

    0   don't allow topmost
    1   allow topmost (default)

=item C<SDL_HINT_THREAD_PRIORITY_POLICY>

A string specifying additional information to use with
C<SDL_SetThreadPriority>.

By default C<SDL_SetThreadPriority> will make appropriate system changes in
order to apply a thread priority. For example on systems using pthreads the
scheduler policy is changed automatically to a policy that works well with a
given priority. Code which has specific requirements can override SDL's default
behavior with this hint.

pthread hint values are C<current>, C<other>, C<fifo> and C<rr>. Currently no
other platform hint values are defined but may be in the future.

Note:

On Linux, the kernel may send C<SIGKILL> to realtime tasks which exceed the
distro configured execution budget for rtkit. This budget can be queried
through C<RLIMIT_RTTIME> after calling C<SDL_SetThreadPriority( )>.

=item C<SDL_HINT_THREAD_FORCE_REALTIME_TIME_CRITICAL>

Specifies whether C<SDL_THREAD_PRIORITY_TIME_CRITICAL> should be treated as
realtime.

On some platforms, like Linux, a realtime priority thread may be subject to
restrictions that require special handling by the application. This hint exists
to let SDL know that the app is prepared to handle said restrictions.

On Linux, SDL will apply the following configuration to any thread that becomes
realtime:

=over

=item * The SCHED_RESET_ON_FORK bit will be set on the scheduling policy,

=item * An RLIMIT_RTTIME budget will be configured to the rtkit specified limit.

Exceeding this limit will result in the kernel sending C<SIGKILL> to the app,

Refer to the man pages for more information.

=back

This variable can be set to the following values:

    0   default platform specific behaviour
    1   Force SDL_THREAD_PRIORITY_TIME_CRITICAL to a realtime scheduling policy

=item C<SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT>

A variable that is the address of another SDL_Window* (as a hex string
formatted with C<%p>).

If this hint is set before C<SDL_CreateWindowFrom( )> and the C<SDL_Window*> it
is set to has C<SDL_WINDOW_OPENGL> set (and running on WGL only, currently),
then two things will occur on the newly created C<SDL_Window>:

=over

=item 1. Its pixel format will be set to the same pixel format as this C<SDL_Window>. This is needed for example when sharing an OpenGL context across multiple windows.

=item 2. The flag C<SDL_WINDOW_OPENGL> will be set on the new window so it can be used for OpenGL rendering.

This variable can be set to the following values:

=over

=item The address (as a string C<%p>) of the C<SDL_Window*> that new windows created with L<< C<SDL_CreateWindowFrom( ... )>|/C<SDL_CreateWindowFrom( ... )> >> should share a pixel format with.

=back

=item C<SDL_HINT_ANDROID_TRAP_BACK_BUTTON>

A variable to control whether we trap the Android back button to handle it
manually. This is necessary for the right mouse button to work on some Android
devices, or to be able to trap the back button for use in your code reliably.
If set to true, the back button will show up as an SDL_KEYDOWN / SDL_KEYUP pair
with a keycode of C<SDL_SCANCODE_AC_BACK>.

The variable can be set to the following values:

=over

=item C<0>

Back button will be handled as usual for system. (default)

=item C<1>

Back button will be trapped, allowing you to handle the key press manually.
(This will also let right mouse click work on systems where the right mouse
button functions as back.)

=back

The value of this hint is used at runtime, so it can be changed at any time.

=back

=item C<SDL_HINT_ANDROID_BLOCK_ON_PAUSE>

A variable to control whether the event loop will block itself when the app is
paused.

The variable can be set to the following values:

=over

=item C<0>

Non blocking.

=item C<1>

Blocking. (default)

=back

The value should be set before SDL is initialized.

=back

=item C<SDL_HINT_ANDROID_BLOCK_ON_PAUSE_PAUSEAUDIO>

A variable to control whether SDL will pause audio in background (Requires
C<SDL_ANDROID_BLOCK_ON_PAUSE> as "Non blocking")

The variable can be set to the following values:

=over

=item C<0>

Non paused.


=item C<1>

Paused. (default)

=back

The value should be set before SDL is initialized.

=item C<SDL_HINT_RETURN_KEY_HIDES_IME>

A variable to control whether the return key on the soft keyboard should hide
the soft keyboard on Android and iOS.

The variable can be set to the following values:

=over

=item C<0>

The return key will be handled as a key event. This is the behaviour of SDL <=
2.0.3. (default)

=item C<1>

The return key will hide the keyboard.

=back

The value of this hint is used at runtime, so it can be changed at any time.

=item C<SDL_HINT_WINDOWS_FORCE_MUTEX_CRITICAL_SECTIONS>

Force SDL to use Critical Sections for mutexes on Windows. On Windows 7 and
newer, Slim Reader/Writer Locks are available. They offer better performance,
allocate no kernel resources and use less memory. SDL will fall back to
Critical Sections on older OS versions or if forced to by this hint.

This also affects Condition Variables. When SRW mutexes are used, SDL will use
Windows Condition Variables as well. Else, a generic SDL_cond implementation
will be used that works with all mutexes.

This variable can be set to the following values:

=over

=item C<0>

Use SRW Locks when available. If not, fall back to Critical Sections. (default)

=item C<1>

Force the use of Critical Sections in all cases.

=back

=item C<SDL_HINT_WINDOWS_FORCE_SEMAPHORE_KERNEL>

Force SDL to use Kernel Semaphores on Windows. Kernel Semaphores are
inter-process and require a context switch on every interaction. On Windows 8
and newer, the WaitOnAddress API is available. Using that and atomics to
implement semaphores increases performance. SDL will fall back to Kernel
Objects on older OS versions or if forced to by this hint.

This variable can be set to the following values:

=over

=item C<0>

Use Atomics and WaitOnAddress API when available. If not, fall back to Kernel
Objects. (default)

=item C<1>

Force the use of Kernel Objects in all cases.

=back

=item C<SDL_HINT_WINDOWS_USE_D3D9EX>

Use the D3D9Ex API introduced in Windows Vista, instead of normal D3D9.
Direct3D 9Ex contains changes to state management that can eliminate device
loss errors during scenarios like Alt+Tab or UAC prompts. D3D9Ex may require
some changes to your application to cope with the new behavior, so this is
disabled by default.

This hint must be set before initializing the video subsystem.

For more information on Direct3D 9Ex, see:

=over

=item L<https://docs.microsoft.com/en-us/windows/win32/direct3darticles/graphics-apis-in-windows-vista#direct3d-9ex>

=item L<https://docs.microsoft.com/en-us/windows/win32/direct3darticles/direct3d-9ex-improvements>

=back

This variable can be set to the following values:

=over

=item C<0>

Use the original Direct3D 9 API (default)

=item C<1>

Use the Direct3D 9Ex API on Vista and later (and fall back if D3D9Ex is
unavailable)

=back

=item C<SDL_HINT_VIDEO_DOUBLE_BUFFER>

Tell the video driver that we only want a double buffer.

By default, most lowlevel 2D APIs will use a triple buffer scheme that wastes
no CPU time on waiting for vsync after issuing a flip, but introduces a frame
of latency. On the other hand, using a double buffer scheme instead is
recommended for cases where low latency is an important factor because we save
a whole frame of latency. We do so by waiting for vsync immediately after
issuing a flip, usually just after eglSwapBuffers call in the backend's
*_SwapWindow function.

Since it's driver-specific, it's only supported where possible and implemented.
Currently supported the following drivers:

=over

=item KMSDRM (kmsdrm)

=item Raspberry Pi (raspberrypi)

=back

=item C<SDL_HINT_KMSDRM_REQUIRE_DRM_MASTER>

Determines whether SDL enforces that DRM master is required in order to
initialize the KMSDRM video backend.

The DRM subsystem has a concept of a "DRM master" which is a DRM client that
has the ability to set planes, set cursor, etc. When SDL is DRM master, it can
draw to the screen using the SDL rendering APIs. Without DRM master, SDL is
still able to process input and query attributes of attached displays, but it
cannot change display state or draw to the screen directly.

In some cases, it can be useful to have the KMSDRM backend even if it cannot be
used for rendering. An app may want to use SDL for input processing while using
another rendering API (such as an MMAL overlay on Raspberry Pi) or using its
own code to render to DRM overlays that SDL doesn't support.

This hint must be set before initializing the video subsystem.

This variable can be set to the following values:

=over

=item C<0>

SDL will allow usage of the KMSDRM backend without DRM master

=item C<1>

SDL Will require DRM master to use the KMSDRM backend (default)

=back

=item C<SDL_HINT_OPENGL_ES_DRIVER>

A variable controlling what driver to use for OpenGL ES contexts.

On some platforms, currently Windows and X11, OpenGL drivers may support
creating contexts with an OpenGL ES profile. By default SDL uses these
profiles, when available, otherwise it attempts to load an OpenGL ES library,
e.g. that provided by the ANGLE project. This variable controls whether SDL
follows this default behaviour or will always load an OpenGL ES library.

Circumstances where this is useful include

=over

=item - Testing an app with a particular OpenGL ES implementation, e.g ANGLE, or emulator, e.g. those from ARM, Imagination or Qualcomm.

=item Resolving OpenGL ES function addresses at link time by linking with the OpenGL ES library instead of querying them at run time with C<SDL_GL_GetProcAddress( )>.

=back

Caution: for an application to work with the default behaviour across different
OpenGL drivers it must query the OpenGL ES function addresses at run time using
C<SDL_GL_GetProcAddress( )>.

This variable is ignored on most platforms because OpenGL ES is native or not
supported.

This variable can be set to the following values:

=over

=item C<0>

Use ES profile of OpenGL, if available. (Default when not set.)

=item C<1>

Load OpenGL ES library using the default library names.

=back

=item C<SDL_HINT_AUDIO_RESAMPLING_MODE>

A variable controlling speed/quality tradeoff of audio resampling.

If available, SDL can use libsamplerate ( http://www.mega-nerd.com/SRC/ ) to
handle audio resampling. There are different resampling modes available that
produce different levels of quality, using more CPU.

If this hint isn't specified to a valid setting, or libsamplerate isn't
available, SDL will use the default, internal resampling algorithm.

Note that this is currently only applicable to resampling audio that is being
written to a device for playback or audio being read from a device for capture.
SDL_AudioCVT always uses the default resampler (although this might change for
SDL 2.1).

This hint is currently only checked at audio subsystem initialization.

This variable can be set to the following values:

=over

=item C<0> or C<default>

Use SDL's internal resampling (Default when not set - low quality, fast)

=item C<1> or C<fast>

Use fast, slightly higher quality resampling, if available

=item C<2> or C<medium>

Use medium quality resampling, if available

=item C<3> or C<best>

Use high quality resampling, if available

=back

=item C<SDL_HINT_AUDIO_CATEGORY>

A variable controlling the audio category on iOS and Mac OS X.

This variable can be set to the following values:

=over

=item C<ambient>

Use the AVAudioSessionCategoryAmbient audio category, will be muted by the
phone mute switch (default)

=item C<playback>

Use the AVAudioSessionCategoryPlayback category

=back

For more information, see Apple's documentation:
L<https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html>

=item C<SDL_HINT_RENDER_BATCHING>

A variable controlling whether the 2D render API is compatible or efficient.

This variable can be set to the following values:

=over

=item C<0>

Don't use batching to make rendering more efficient.

=item C<1>

Use batching, but might cause problems if app makes its own direct OpenGL
calls.

=back

Up to SDL 2.0.9, the render API would draw immediately when requested. Now it
batches up draw requests and sends them all to the GPU only when forced to
(during SDL_RenderPresent, when changing render targets, by updating a texture
that the batch needs, etc). This is significantly more efficient, but it can
cause problems for apps that expect to render on top of the render API's
output. As such, SDL will disable batching if a specific render backend is
requested (since this might indicate that the app is planning to use the
underlying graphics API directly). This hint can be used to explicitly request
batching in this instance. It is a contract that you will either never use the
underlying graphics API directly, or if you do, you will call
C<SDL_RenderFlush( )> before you do so any current batch goes to the GPU before
your work begins. Not following this contract will result in undefined
behavior.

=item C<SDL_HINT_AUTO_UPDATE_JOYSTICKS>

A variable controlling whether SDL updates joystick state when getting input
events

This variable can be set to the following values:

=over

=item C<0>

You'll call C<SDL_JoystickUpdate( )> manually

=item C<1>

SDL will automatically call C<SDL_JoystickUpdate( )> (default)

=back

This hint can be toggled on and off at runtime.

=item C<SDL_HINT_AUTO_UPDATE_SENSORS>

A variable controlling whether SDL updates sensor state when getting input
events

This variable can be set to the following values:

=over

=item C<0>

You'll call C<SDL_SensorUpdate ( )> manually

=item C<1>

SDL will automatically call C<SDL_SensorUpdate( )> (default)

=back

This hint can be toggled on and off at runtime.

=item C<SDL_HINT_EVENT_LOGGING>

A variable controlling whether SDL logs all events pushed onto its internal
queue.

This variable can be set to the following values:

=over

=item C<0>

Don't log any events (default)

=item C<1>

Log all events except mouse and finger motion, which are pretty spammy.

=item C<2>

Log all events.

=back

This is generally meant to be used to debug SDL itself, but can be useful for
application developers that need better visibility into what is going on in the
event queue. Logged events are sent through C<SDL_Log( )>, which means by
default they appear on stdout on most platforms or maybe C<OutputDebugString(
)> on Windows, and can be funneled by the app with C<SDL_LogSetOutputFunction(
)>, etc.

This hint can be toggled on and off at runtime, if you only need to log events
for a small subset of program execution.

=item C<SDL_HINT_WAVE_RIFF_CHUNK_SIZE>

Controls how the size of the RIFF chunk affects the loading of a WAVE file.

The size of the RIFF chunk (which includes all the sub-chunks of the WAVE file)
is not always reliable. In case the size is wrong, it's possible to just ignore
it and step through the chunks until a fixed limit is reached.

Note that files that have trailing data unrelated to the WAVE file or corrupt
files may slow down the loading process without a reliable boundary. By
default, SDL stops after 10000 chunks to prevent wasting time. Use the
environment variable SDL_WAVE_CHUNK_LIMIT to adjust this value.

This variable can be set to the following values:

=over

=item C<force>

Always use the RIFF chunk size as a boundary for the chunk search

=item C<ignorezero>

Like "force", but a zero size searches up to 4 GiB (default)

=item C<ignore>

Ignore the RIFF chunk size and always search up to 4 GiB

=item C<maximum>

Search for chunks until the end of file (not recommended)

=back

=item C<SDL_HINT_WAVE_TRUNCATION>

Controls how a truncated WAVE file is handled.

A WAVE file is considered truncated if any of the chunks are incomplete or the
data chunk size is not a multiple of the block size. By default, SDL decodes
until the first incomplete block, as most applications seem to do.

This variable can be set to the following values:

=over

=item C<verystrict>

Raise an error if the file is truncated

=item C<strict>

Like "verystrict", but the size of the RIFF chunk is ignored

=item C<dropframe>

Decode until the first incomplete sample frame

=item C<dropblock>

Decode until the first incomplete block (default)

=back

=item C<SDL_HINT_WAVE_FACT_CHUNK>

Controls how the fact chunk affects the loading of a WAVE file.

The fact chunk stores information about the number of samples of a WAVE file.
The Standards Update from Microsoft notes that this value can be used to
'determine the length of the data in seconds'. This is especially useful for
compressed formats (for which this is a mandatory chunk) if they produce
multiple sample frames per block and truncating the block is not allowed. The
fact chunk can exactly specify how many sample frames there should be in this
case.

Unfortunately, most application seem to ignore the fact chunk and so SDL
ignores it by default as well.

This variable can be set to the following values:

=over

=item C<truncate>

Use the number of samples to truncate the wave data if the fact chunk is
present and valid

=item C<strict>

Like "truncate", but raise an error if the fact chunk is invalid, not present
for non-PCM formats, or if the data chunk doesn't have that many samples

=item C<ignorezero>

Like "truncate", but ignore fact chunk if the number of samples is zero

=item C<ignore>

Ignore fact chunk entirely (default)

=back

=item C<SDL_HINT_DISPLAY_USABLE_BOUNDS>

Override for C<SDL_GetDisplayUsableBounds( )>

If set, this hint will override the expected results for
C<SDL_GetDisplayUsableBounds( )> for display index 0. Generally you don't want
to do this, but this allows an embedded system to request that some of the
screen be reserved for other uses when paired with a well-behaved application.

The contents of this hint must be 4 comma-separated integers, the first is the
bounds x, then y, width and height, in that order.

=item C<SDL_HINT_AUDIO_DEVICE_APP_NAME>

Specify an application name for an audio device.

Some audio backends (such as PulseAudio) allow you to describe your audio
stream. Among other things, this description might show up in a system control
panel that lets the user adjust the volume on specific audio streams instead of
using one giant master volume slider.

This hints lets you transmit that information to the OS. The contents of this
hint are used while opening an audio device. You should use a string that
describes your program ("My Game 2: The Revenge")

Setting this to "" or leaving it unset will have SDL use a reasonable default:
probably the application's name or "SDL Application" if SDL doesn't have any
better information.

On targets where this is not supported, this hint does nothing.

=item C<SDL_HINT_AUDIO_DEVICE_STREAM_NAME>

Specify an application name for an audio device.

Some audio backends (such as PulseAudio) allow you to describe your audio
stream. Among other things, this description might show up in a system control
panel that lets the user adjust the volume on specific audio streams instead of
using one giant master volume slider.

This hints lets you transmit that information to the OS. The contents of this
hint are used while opening an audio device. You should use a string that
describes your what your program is playing ("audio stream" is probably
sufficient in many cases, but this could be useful for something like "team
chat" if you have a headset playing VoIP audio separately).

Setting this to "" or leaving it unset will have SDL use a reasonable default:
"audio stream" or something similar.

On targets where this is not supported, this hint does nothing.

=item C<SDL_HINT_AUDIO_DEVICE_STREAM_ROLE>

Specify an application role for an audio device.

Some audio backends (such as Pipewire) allow you to describe the role of your
audio stream. Among other things, this description might show up in a system
control panel or software for displaying and manipulating media
playback/capture graphs.

This hints lets you transmit that information to the OS. The contents of this
hint are used while opening an audio device. You should use a string that
describes your what your program is playing (Game, Music, Movie, etc...).

Setting this to "" or leaving it unset will have SDL use a reasonable default:
"Game" or something similar.

On targets where this is not supported, this hint does nothing.

=item C<SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED>

Specify the behavior of Alt+Tab while the keyboard is grabbed.

By default, SDL emulates Alt+Tab functionality while the keyboard is grabbed
and your window is full-screen. This prevents the user from getting stuck in
your application if you've enabled keyboard grab.

The variable can be set to the following values:

=over

=item C<0>

SDL will not handle Alt+Tab. Your application is responsible for handling
Alt+Tab while the keyboard is grabbed.

=item C<1>

SDL will minimize your window when Alt+Tab is pressed (default)

=back

=item C<SDL_HINT_PREFERRED_LOCALES>

Override for SDL_GetPreferredLocales( )

If set, this will be favored over anything the OS might report for the user's
preferred locales. Changing this hint at runtime will not generate a
SDL_LOCALECHANGED event (but if you can change the hint, you can push your own
event, if you want).

The format of this hint is a comma-separated list of language and locale,
combined with an underscore, as is a common format: "en_GB". Locale is
optional: "en". So you might have a list like this: "en_GB,jp,es_PT"

=back

=head1 C<:joystickType>

=over

=item C<SDL_JOYSTICK_TYPE_UNKNOWN>

=item C<SDL_JOYSTICK_TYPE_GAMECONTROLLER>

=item C<SDL_JOYSTICK_TYPE_WHEEL>

=item C<SDL_JOYSTICK_TYPE_ARCADE_STICK>

=item C<SDL_JOYSTICK_TYPE_FLIGHT_STICK>

=item C<SDL_JOYSTICK_TYPE_DANCE_PAD>

=item C<SDL_JOYSTICK_TYPE_GUITAR>

=item C<SDL_JOYSTICK_TYPE_DRUM_KIT>

=item C<SDL_JOYSTICK_TYPE_ARCADE_PAD>

=item C<SDL_JOYSTICK_TYPE_THROTTLE>

=back

=head1 C<:joystickPowerLevel>

=over

=item C<SDL_JOYSTICK_POWER_UNKNOWN>

=item C<SDL_JOYSTICK_POWER_EMPTY> - C<< <= 5% >>

=item C<SDL_JOYSTICK_POWER_LOW> - C<< <= 20% >>

=item C<SDL_JOYSTICK_POWER_MEDIUM> - C<< <= 70% >>

=item C<SDL_JOYSTICK_POWER_FULL> - C<< <= 100% >>

=item C<SDL_JOYSTICK_POWER_WIRED>

=item C<SDL_JOYSTICK_POWER_MAX>

=back

=head1 C<:hatPosition>

Hat positions.

=over

=item C<SDL_HAT_CENTERED>

=item C<SDL_HAT_UP>

=item C<SDL_HAT_RIGHT>

=item C<SDL_HAT_DOWN>

=item C<SDL_HAT_LEFT>

=item C<SDL_HAT_RIGHTUP>

=item C<SDL_HAT_RIGHTDOWN>

=item C<SDL_HAT_LEFTUP>

=item C<SDL_HAT_LEFTDOWN>

=back

=head1 C<:keyCode>

The SDL virtual key representation.

Values of this type are used to represent keyboard keys using the current
layout of the keyboard. These values include Unicode values representing the
unmodified character that would be generated by pressing the key, or an
C<SDLK_*> constant for those keys that do not generate characters.

A special exception is the number keys at the top of the keyboard which always
map to C<SDLK_0...SDLK_9>, regardless of layout.

=over

=item C<SDLK_UNKNOWN>

=item C<SDLK_RETURN>

=item C<SDLK_ESCAPE>

=item C<SDLK_BACKSPACE>

=item C<SDLK_TAB>

=item C<SDLK_SPACE>

=item C<SDLK_EXCLAIM>

=item C<SDLK_QUOTEDBL>

=item C<SDLK_HASH>

=item C<SDLK_PERCENT>

=item C<SDLK_DOLLAR>

=item C<SDLK_AMPERSAND>

=item C<SDLK_QUOTE>

=item C<SDLK_LEFTPAREN>

=item C<SDLK_RIGHTPAREN>

=item C<SDLK_ASTERISK>

=item C<SDLK_PLUS>

=item C<SDLK_COMMA>

=item C<SDLK_MINUS>

=item C<SDLK_PERIOD>

=item C<SDLK_SLASH>

=item C<SDLK_0>

=item C<SDLK_1>

=item C<SDLK_2>

=item C<SDLK_3>

=item C<SDLK_4>

=item C<SDLK_5>

=item C<SDLK_6>

=item C<SDLK_7>

=item C<SDLK_8>

=item C<SDLK_9>

=item C<SDLK_COLON>

=item C<SDLK_SEMICOLON>

=item C<SDLK_LESS>

=item C<SDLK_EQUALS>

=item C<SDLK_GREATER>

=item C<SDLK_QUESTION>

=item C<SDLK_AT>

=item C<SDLK_LEFTBRACKET>

=item C<SDLK_BACKSLASH>

=item C<SDLK_RIGHTBRACKET>

=item C<SDLK_CARET>

=item C<SDLK_UNDERSCORE>

=item C<SDLK_BACKQUOTE>

=item C<SDLK_a>

=item C<SDLK_b>

=item C<SDLK_c>

=item C<SDLK_d>

=item C<SDLK_e>

=item C<SDLK_f>

=item C<SDLK_g>

=item C<SDLK_h>

=item C<SDLK_i>

=item C<SDLK_j>

=item C<SDLK_k>

=item C<SDLK_l>

=item C<SDLK_m>

=item C<SDLK_n>

=item C<SDLK_o>

=item C<SDLK_p>

=item C<SDLK_q>

=item C<SDLK_r>

=item C<SDLK_s>

=item C<SDLK_t>

=item C<SDLK_u>

=item C<SDLK_v>

=item C<SDLK_w>

=item C<SDLK_x>

=item C<SDLK_y>

=item C<SDLK_z>

=item C<SDLK_CAPSLOCK>

=item C<SDLK_F1>

=item C<SDLK_F2>

=item C<SDLK_F3>

=item C<SDLK_F4>

=item C<SDLK_F5>

=item C<SDLK_F6>

=item C<SDLK_F7>

=item C<SDLK_F8>

=item C<SDLK_F9>

=item C<SDLK_F10>

=item C<SDLK_F11>

=item C<SDLK_F12>

=item C<SDLK_PRINTSCREEN>

=item C<SDLK_SCROLLLOCK>

=item C<SDLK_PAUSE>

=item C<SDLK_INSERT>

=item C<SDLK_HOME>

=item C<SDLK_PAGEUP>

=item C<SDLK_DELETE>

=item C<SDLK_END>

=item C<SDLK_PAGEDOWN>

=item C<SDLK_RIGHT>

=item C<SDLK_LEFT>

=item C<SDLK_DOWN>

=item C<SDLK_UP>

=item C<SDLK_NUMLOCKCLEAR>

=item C<SDLK_KP_DIVIDE>

=item C<SDLK_KP_MULTIPLY>

=item C<SDLK_KP_MINUS>

=item C<SDLK_KP_PLUS>

=item C<SDLK_KP_ENTER>

=item C<SDLK_KP_1>

=item C<SDLK_KP_2>

=item C<SDLK_KP_3>

=item C<SDLK_KP_4>

=item C<SDLK_KP_5>

=item C<SDLK_KP_6>

=item C<SDLK_KP_7>

=item C<SDLK_KP_8>

=item C<SDLK_KP_9>

=item C<SDLK_KP_0>

=item C<SDLK_KP_PERIOD>

=item C<SDLK_APPLICATION>

=item C<SDLK_POWER>

=item C<SDLK_KP_EQUALS>

=item C<SDLK_F13>

=item C<SDLK_F14>

=item C<SDLK_F15>

=item C<SDLK_F16>

=item C<SDLK_F17>

=item C<SDLK_F18>

=item C<SDLK_F19>

=item C<SDLK_F20>

=item C<SDLK_F21>

=item C<SDLK_F22>

=item C<SDLK_F23>

=item C<SDLK_F24>

=item C<SDLK_EXECUTE>

=item C<SDLK_HELP>

=item C<SDLK_MENU>

=item C<SDLK_SELECT>

=item C<SDLK_STOP>

=item C<SDLK_AGAIN>

=item C<SDLK_UNDO>

=item C<SDLK_CUT>

=item C<SDLK_COPY>

=item C<SDLK_PASTE>

=item C<SDLK_FIND>

=item C<SDLK_MUTE>

=item C<SDLK_VOLUMEUP>

=item C<SDLK_VOLUMEDOWN>

=item C<SDLK_KP_COMMA>

=item C<SDLK_KP_EQUALSAS400>

=item C<SDLK_ALTERASE>

=item C<SDLK_SYSREQ>

=item C<SDLK_CANCEL>

=item C<SDLK_CLEAR>

=item C<SDLK_PRIOR>

=item C<SDLK_RETURN2>

=item C<SDLK_SEPARATOR>

=item C<SDLK_OUT>

=item C<SDLK_OPER>

=item C<SDLK_CLEARAGAIN>

=item C<SDLK_CRSEL>

=item C<SDLK_EXSEL>

=item C<SDLK_KP_00>

=item C<SDLK_KP_000>

=item C<SDLK_THOUSANDSSEPARATOR>

=item C<SDLK_DECIMALSEPARATOR>

=item C<SDLK_CURRENCYUNIT>

=item C<SDLK_CURRENCYSUBUNIT>

=item C<SDLK_KP_LEFTPAREN>

=item C<SDLK_KP_RIGHTPAREN>

=item C<SDLK_KP_LEFTBRACE>

=item C<SDLK_KP_RIGHTBRACE>

=item C<SDLK_KP_TAB>

=item C<SDLK_KP_BACKSPACE>

=item C<SDLK_KP_A>

=item C<SDLK_KP_B>

=item C<SDLK_KP_C>

=item C<SDLK_KP_D>

=item C<SDLK_KP_E>

=item C<SDLK_KP_F>

=item C<SDLK_KP_XOR>

=item C<SDLK_KP_POWER>

=item C<SDLK_KP_PERCENT>

=item C<SDLK_KP_LESS>

=item C<SDLK_KP_GREATER>

=item C<SDLK_KP_AMPERSAND>

=item C<SDLK_KP_DBLAMPERSAND>

=item C<SDLK_KP_VERTICALBAR>

=item C<SDLK_KP_DBLVERTICALBAR>

=item C<SDLK_KP_COLON>

=item C<SDLK_KP_HASH>

=item C<SDLK_KP_SPACE>

=item C<SDLK_KP_AT>

=item C<SDLK_KP_EXCLAM>

=item C<SDLK_KP_MEMSTORE>

=item C<SDLK_KP_MEMRECALL>

=item C<SDLK_KP_MEMCLEAR>

=item C<SDLK_KP_MEMADD>

=item C<SDLK_KP_MEMSUBTRACT>

=item C<SDLK_KP_MEMMULTIPLY>

=item C<SDLK_KP_MEMDIVIDE>

=item C<SDLK_KP_PLUSMINUS>

=item C<SDLK_KP_CLEAR>

=item C<SDLK_KP_CLEARENTRY>

=item C<SDLK_KP_BINARY>

=item C<SDLK_KP_OCTAL>

=item C<SDLK_KP_DECIMAL>

=item C<SDLK_KP_HEXADECIMAL>

=item C<SDLK_LCTRL>

=item C<SDLK_LSHIFT>

=item C<SDLK_LALT>

=item C<SDLK_LGUI>

=item C<SDLK_RCTRL>

=item C<SDLK_RSHIFT>

=item C<SDLK_RALT>

=item C<SDLK_RGUI>

=item C<SDLK_MODE>

=item C<SDLK_AUDIONEXT>

=item C<SDLK_AUDIOPREV>

=item C<SDLK_AUDIOSTOP>

=item C<SDLK_AUDIOPLAY>

=item C<SDLK_AUDIOMUTE>

=item C<SDLK_MEDIASELECT>

=item C<SDLK_WWW>

=item C<SDLK_MAIL>

=item C<SDLK_CALCULATOR>

=item C<SDLK_COMPUTER>

=item C<SDLK_AC_SEARCH>

=item C<SDLK_AC_HOME>

=item C<SDLK_AC_BACK>

=item C<SDLK_AC_FORWARD>

=item C<SDLK_AC_STOP>

=item C<SDLK_AC_REFRESH>

=item C<SDLK_AC_BOOKMARKS>

=item C<SDLK_BRIGHTNESSDOWN>

=item C<SDLK_BRIGHTNESSUP>

=item C<SDLK_DISPLAYSWITCH>

=item C<SDLK_KBDILLUMTOGGLE>

=item C<SDLK_KBDILLUMDOWN>

=item C<SDLK_KBDILLUMUP>

=item C<SDLK_EJECT>

=item C<SDLK_SLEEP>

=item C<SDLK_APP1>

=item C<SDLK_APP2>

=item C<SDLK_AUDIOREWIND>

=item C<SDLK_AUDIOFASTFORWARD>

=back

=head1 C<:keymod>

Enumeration of valid key mods (possibly OR'd together)

=over

=item C<KMOD_NONE>

=item C<KMOD_LSHIFT>

=item C<KMOD_RSHIFT>

=item C<KMOD_LCTRL>

=item C<KMOD_RCTRL>

=item C<KMOD_LALT>

=item C<KMOD_RALT>

=item C<KMOD_LGUI>

=item C<KMOD_RGUI>

=item C<KMOD_NUM>

=item C<KMOD_CAPS>

=item C<KMOD_MODE>

=item C<KMOD_RESERVED>

=item C<KMOD_CTRL>

=item C<KMOD_SHIFT>

=item C<KMOD_ALT>

=item C<KMOD_GUI>

=back

=head2 C<:logcategory>

The predefined log categories

By default the application category is enabled at the INFO level, the assert
category is enabled at the WARN level, test is enabled at the VERBOSE level and
all other categories are enabled at the CRITICAL level.

=over

=item C<SDL_LOG_CATEGORY_APPLICATION>

=item C<SDL_LOG_CATEGORY_ERROR>

=item C<SDL_LOG_CATEGORY_ASSERT>

=item C<SDL_LOG_CATEGORY_SYSTEM>

=item C<SDL_LOG_CATEGORY_AUDIO>

=item C<SDL_LOG_CATEGORY_VIDEO>

=item C<SDL_LOG_CATEGORY_RENDER>

=item C<SDL_LOG_CATEGORY_INPUT>

=item C<SDL_LOG_CATEGORY_TEST>

=item C<SDL_LOG_CATEGORY_RESERVED1>

=item C<SDL_LOG_CATEGORY_RESERVED2>

=item C<SDL_LOG_CATEGORY_RESERVED3>

=item C<SDL_LOG_CATEGORY_RESERVED4>

=item C<SDL_LOG_CATEGORY_RESERVED5>

=item C<SDL_LOG_CATEGORY_RESERVED6>

=item C<SDL_LOG_CATEGORY_RESERVED7>

=item C<SDL_LOG_CATEGORY_RESERVED8>

=item C<SDL_LOG_CATEGORY_RESERVED9>

=item C<SDL_LOG_CATEGORY_RESERVED10>

=item C<SDL_LOG_CATEGORY_CUSTOM>

=back

=head2 C<:logpriority>

The predefined log priorities.

=over

=item C<SDL_LOG_PRIORITY_VERBOSE>

=item C<SDL_LOG_PRIORITY_DEBUG>

=item C<SDL_LOG_PRIORITY_INFO>

=item C<SDL_LOG_PRIORITY_WARN>

=item C<SDL_LOG_PRIORITY_ERROR>

=item C<SDL_LOG_PRIORITY_CRITICAL>

=item C<SDL_NUM_LOG_PRIORITIES>

=back

=head1 C<:messageBoxFlags>

If supported, display warning icon, etc.

=over

=item C<SDL_MESSAGEBOX_ERROR> - error dialog

=item C<SDL_MESSAGEBOX_WARNING> - warning dialog

=item C<SDL_MESSAGEBOX_INFORMATION> - informational dialog

=item C<SDL_MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT> - buttons placed left to right

=item C<SDL_MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT> - buttons placed right to left

=back

=head1 C<:messageBoxButtonData>

=over

=item C<SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT> - Marks the default button when return is hit

=item C<SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT> - Marks the default button when escape is hit

=back

=head1 C<:messageBoxColorType>

=over

=item C<SDL_MESSAGEBOX_COLOR_BACKGROUND>

=item C<SDL_MESSAGEBOX_COLOR_TEXT>

=item C<SDL_MESSAGEBOX_COLOR_BUTTON_BORDER>

=item C<SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND>

=item C<SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED>

=item C<SDL_MESSAGEBOX_COLOR_MAX>

=back

=head1 C<:systemCursor>

Cursor types for L<< C<SDL_CreateSystemCursor( ...
)>|SDL2::FFI/C<SDL_CreateSystemCursor( ... )> >>.

=over

=item C<SDL_SYSTEM_CURSOR_ARROW> - Arrow

=item C<SDL_SYSTEM_CURSOR_IBEAM> - I-beam

=item C<SDL_SYSTEM_CURSOR_WAIT> - Wait

=item C<SDL_SYSTEM_CURSOR_CROSSHAIR> - Crosshair

=item C<SDL_SYSTEM_CURSOR_WAITARROW> - Small wait cursor (or Wait if not available)

=item C<SDL_SYSTEM_CURSOR_SIZENWSE> - Double arrow pointing northwest and southeast

=item C<SDL_SYSTEM_CURSOR_SIZENESW> - Double arrow pointing northeast and southwest

=item C<SDL_SYSTEM_CURSOR_SIZEWE> - Double arrow pointing west and east

=item C<SDL_SYSTEM_CURSOR_SIZENS> - Double arrow pointing north and south

=item C<SDL_SYSTEM_CURSOR_SIZEALL> - Four pointed arrow pointing north, south, east, and west

=item C<SDL_SYSTEM_CURSOR_NO> - Slashed circle or crossbones

=item C<SDL_SYSTEM_CURSOR_HAND> - Hand

=item C<SDL_NUM_SYSTEM_CURSORS>

=back

=head1 C<:mouseWheelDirection>

Scroll direction types for the Scroll event.

=over

=item C<SDL_MOUSEWHEEL_NORMAL>

=item C<SDL_MOUSEWHEEL_FLIPPED>

=back

=head1 C<:mouseButton>

Used as a mask when testing buttons in buttonstate.

=over

=item Button 1:  Left mouse button

=item Button 2:  Middle mouse button

=item Button 3:  Right mouse button

=back

=over

=item C<SDL_BUTTON>

=item C<SDL_BUTTON_LEFT>

=item C<SDL_BUTTON_MIDDLE>

=item C<SDL_BUTTON_RIGHT>

=item C<SDL_BUTTON_X1>

=item C<SDL_BUTTON_X2>

=item C<SDL_BUTTON_LMASK>

=item C<SDL_BUTTON_MMASK>

=item C<SDL_BUTTON_RMASK>

=item C<SDL_BUTTON_X1MASK>

=item C<SDL_BUTTON_X2MASK>

=back

=head1 C<:alpha>

Transparency definitions. These define alpha as the opacity of a surface.

=over

=item C<SDL_ALPHA_OPAQUE>

=item C<SDL_ALPHA_TRANSPARENT>

=back

=head1 C<:pixelType>

=over

=item C<SDL_PIXELTYPE_UNKNOWN>

=item C<SDL_PIXELTYPE_INDEX1>

=item C<SDL_PIXELTYPE_INDEX4>

=item C<SDL_PIXELTYPE_INDEX8>

=item C<SDL_PIXELTYPE_PACKED8>

=item C<SDL_PIXELTYPE_PACKED16>

=item C<SDL_PIXELTYPE_PACKED32>

=item C<SDL_PIXELTYPE_ARRAYU8>

=item C<SDL_PIXELTYPE_ARRAYU16>

=item C<SDL_PIXELTYPE_ARRAYU32>

=item C<SDL_PIXELTYPE_ARRAYF16>

=item C<SDL_PIXELTYPE_ARRAYF32>

=back

=head1 C<:bitmapOrder>

Bitmap pixel order, high bit -> low bit.

=over

=item C<SDL_BITMAPORDER_NONE>

=item C<SDL_BITMAPORDER_4321>

=item C<SDL_BITMAPORDER_1234>

=back

=head1 C<:packedOrder>

Packed component order, high bit -> low bit.

=over

=item C<SDL_PACKEDORDER_NONE>

=item C<SDL_PACKEDORDER_XRGB>

=item C<SDL_PACKEDORDER_RGBX>

=item C<SDL_PACKEDORDER_ARGB>

=item C<SDL_PACKEDORDER_RGBA>

=item C<SDL_PACKEDORDER_XBGR>

=item C<SDL_PACKEDORDER_BGRX>

=item C<SDL_PACKEDORDER_ABGR>

=item C<SDL_PACKEDORDER_BGRA>

=back

=head1 C<:arrayOrder>

Array component order, low byte -> high byte.

=over

=item C<SDL_ARRAYORDER_NONE>

=item C<SDL_ARRAYORDER_RGB>

=item C<SDL_ARRAYORDER_RGBA>

=item C<SDL_ARRAYORDER_ARGB>

=item C<SDL_ARRAYORDER_BGR>

=item C<SDL_ARRAYORDER_BGRA>

=item C<SDL_ARRAYORDER_ABGR>

=back

=head1 C<:packedLayout>

Packed component layout.

=over

=item C<SDL_PACKEDLAYOUT_NONE>

=item C<SDL_PACKEDLAYOUT_332>

=item C<SDL_PACKEDLAYOUT_4444>

=item C<SDL_PACKEDLAYOUT_1555>

=item C<SDL_PACKEDLAYOUT_5551>

=item C<SDL_PACKEDLAYOUT_565>

=item C<SDL_PACKEDLAYOUT_8888>

=item C<SDL_PACKEDLAYOUT_2101010>

=item C<SDL_PACKEDLAYOUT_1010102>

=back

=head1 C<:pixels>

=over

=item C<SDL_DEFINE_PIXELFOURCC>

=item C<SDL_DEFINE_PIXELFORMAT>

=item C<SDL_PIXELFLAG>

=item C<SDL_PIXELTYPE>

=item C<SDL_PIXELORDER>

=item C<SDL_PIXELLAYOUT>

=item C<SDL_BITSPERPIXEL>

=item C<SDL_BYTESPERPIXEL>

=item C<SDL_ISPIXELFORMAT_INDEXED>

=item C<SDL_ISPIXELFORMAT_PACKED>

=item C<SDL_ISPIXELFORMAT_ARRAY>

=item C<SDL_ISPIXELFORMAT_ALPHA>

=item C<SDL_ISPIXELFORMAT_FOURCC>

=back

=head1 C<:pixelFormatEnum>

=over

=item C<SDL_PIXELFORMAT_UNKNOWN>

=item C<SDL_PIXELFORMAT_INDEX1LSB>

=item C<SDL_PIXELFORMAT_INDEX1MSB>

=item C<SDL_PIXELFORMAT_INDEX4LSB>

=item C<SDL_PIXELFORMAT_INDEX4MSB>

=item C<SDL_PIXELFORMAT_INDEX8>

=item C<SDL_PIXELFORMAT_RGB332>

=item C<SDL_PIXELFORMAT_XRGB4444>

=item C<SDL_PIXELFORMAT_RGB444>

=item C<SDL_PIXELFORMAT_XBGR4444>

=item C<SDL_PIXELFORMAT_BGR444>

=item C<SDL_PIXELFORMAT_XRGB1555>

=item C<SDL_PIXELFORMAT_RGB555>

=item C<SDL_PIXELFORMAT_XBGR1555>

=item C<SDL_PIXELFORMAT_BGR555>

=item C<SDL_PIXELFORMAT_ARGB4444>

=item C<SDL_PIXELFORMAT_RGBA4444>

=item C<SDL_PIXELFORMAT_ABGR4444>

=item C<SDL_PIXELFORMAT_BGRA4444>

=item C<SDL_PIXELFORMAT_ARGB1555>

=item C<SDL_PIXELFORMAT_RGBA5551>

=item C<SDL_PIXELFORMAT_ABGR1555>

=item C<SDL_PIXELFORMAT_BGRA5551>

=item C<SDL_PIXELFORMAT_RGB565>

=item C<SDL_PIXELFORMAT_BGR565>

=item C<SDL_PIXELFORMAT_RGB24>

=item C<SDL_PIXELFORMAT_BGR24>

=item C<SDL_PIXELFORMAT_XRGB8888>

=item C<SDL_PIXELFORMAT_RGB888>

=item C<SDL_PIXELFORMAT_RGBX8888>

=item C<SDL_PIXELFORMAT_XBGR8888>

=item C<SDL_PIXELFORMAT_BGR888>

=item C<SDL_PIXELFORMAT_BGRX8888>

=item C<SDL_PIXELFORMAT_ARGB8888>

=item C<SDL_PIXELFORMAT_RGBA8888>

=item C<SDL_PIXELFORMAT_ABGR8888>

=item C<SDL_PIXELFORMAT_BGRA8888>

=item C<SDL_PIXELFORMAT_ARGB2101010>

=item C<SDL_PIXELFORMAT_RGBA32>

=item C<SDL_PIXELFORMAT_ARGB32>

=item C<SDL_PIXELFORMAT_BGRA32>

=item C<SDL_PIXELFORMAT_ABGR32>

=item C<SDL_PIXELFORMAT_YV12> - Planar mode: Y + V + U  (3 planes)

=item C<SDL_PIXELFORMAT_IYUV> - Planar mode: Y + U + V  (3 planes)

=item C<SDL_PIXELFORMAT_YUY2> - Packed mode: Y0+U0+Y1+V0 (1 plane)

=item C<SDL_PIXELFORMAT_UYVY> - Packed mode: U0+Y0+V0+Y1 (1 plane)

=item C<SDL_PIXELFORMAT_YVYU> - Packed mode: Y0+V0+Y1+U0 (1 plane)

=item C<SDL_PIXELFORMAT_NV12> - Planar mode: Y + U/V interleaved  (2 planes)

=item C<SDL_PIXELFORMAT_NV21> - Planar mode: Y + V/U interleaved  (2 planes)

=item C<SDL_PIXELFORMAT_EXTERNAL_OES> - Android video texture format

=back

=head1 C<:powerState>

The basic state for the system's power supply.

=over

=item C<SDL_POWERSTATE_UNKNOWN> - Cannot determine power status

=item C<SDL_POWERSTATE_ON_BATTERY> - Not plugged in, running on the battery

=item C<SDL_POWERSTATE_NO_BATTERY> - Plugged in, no battery available

=item C<SDL_POWERSTATE_CHARGING> - Plugged in, charging battery

=item C<SDL_POWERSTATE_CHARGED> - Plugged in, battery charged

=back











=head1 C<:assertState>



=over

=item C<SDL_ASSERTION_RETRY> - Retry the assert immediately

=item C<SDL_ASSERTION_BREAK> - Make the debugger trigger a breakpoint

=item C<SDL_ASSERTION_ABORT> - Terminate the program

=item C<SDL_ASSERTION_IGNORE> - Ignore the assert

=item C<SDL_ASSERTION_ALWAYS_IGNORE> - Ignore the assert from now on

=back

=head2 C<:windowflags>

The flags on a window.

=over

=item C<SDL_WINDOW_FULLSCREEN> - Fullscreen window

=item C<SDL_WINDOW_OPENGL> - Window usable with OpenGL context

=item C<SDL_WINDOW_SHOWN> - Window is visible

=item C<SDL_WINDOW_HIDDEN> - Window is not visible

=item C<SDL_WINDOW_BORDERLESS> - No window decoration

=item C<SDL_WINDOW_RESIZABLE> - Window can be resized

=item C<SDL_WINDOW_MINIMIZED> - Window is minimized

=item C<SDL_WINDOW_MAXIMIZED> - Window is maximized

=item C<SDL_WINDOW_MOUSE_GRABBED> - Window has grabbed mouse input

=item C<SDL_WINDOW_INPUT_FOCUS> - Window has input focus

=item C<SDL_WINDOW_MOUSE_FOCUS> - Window has mouse focus

=item C<SDL_WINDOW_FULLSCREEN_DESKTOP> - Fullscreen window without frame

=item C<SDL_WINDOW_FOREIGN> - Window not created by SDL

=item C<SDL_WINDOW_ALLOW_HIGHDPI> - Window should be created in high-DPI mode if supported.

On macOS NSHighResolutionCapable must be set true in the application's
Info.plist for this to have any effect.

=item C<SDL_WINDOW_MOUSE_CAPTURE> - Window has mouse captured (unrelated to C<MOUSE_GRABBED>)

=item C<SDL_WINDOW_ALWAYS_ON_TOP> - Window should always be above others

=item C<SDL_WINDOW_SKIP_TASKBAR> - Window should not be added to the taskbar

=item C<SDL_WINDOW_UTILITY> - Window should be treated as a utility window

=item C<SDL_WINDOW_TOOLTIP> - Window should be treated as a tooltip

=item C<SDL_WINDOW_POPUP_MENU> - Window should be treated as a popup menu

=item C<SDL_WINDOW_KEYBOARD_GRABBED> - Window has grabbed keyboard input

=item C<SDL_WINDOW_VULKAN> - Window usable for Vulkan surface

=item C<SDL_WINDOW_METAL> - Window usable for Metal view

=item C<SDL_WINDOW_INPUT_GRABBED> - Equivalent to C<SDL_WINDOW_MOUSE_GRABBED> for compatibility

=back

=head2 C<:windowEventID>

Event subtype for window events.

=over

=item C<SDL_WINDOWEVENT_NONE> - Never used

=item C<SDL_WINDOWEVENT_SHOWN> - Window has been shown

=item C<SDL_WINDOWEVENT_HIDDEN> - Window has been hidden

=item C<SDL_WINDOWEVENT_EXPOSED> - Window has been exposed and should be redrawn

=item C<SDL_WINDOWEVENT_MOVED> - Window has been moved to C<data1, data2>

=item C<SDL_WINDOWEVENT_RESIZED> - Window has been resized to C<data1 x data2>

=item C<SDL_WINDOWEVENT_SIZE_CHANGED> - The window size has changed, either as a result of an API call or through the system or user changing the window size.

=item C<SDL_WINDOWEVENT_MINIMIZED> - Window has been minimized

=item C<SDL_WINDOWEVENT_MAXIMIZED> - Window has been maximized

=item C<SDL_WINDOWEVENT_RESTORED> - Window has been restored to normal size and position

=item C<SDL_WINDOWEVENT_ENTER> - Window has gained mouse focus

=item C<SDL_WINDOWEVENT_LEAVE> - Window has lost mouse focus

=item C<SDL_WINDOWEVENT_FOCUS_GAINED> - Window has gained keyboard focus

=item C<SDL_WINDOWEVENT_FOCUS_LOST> - Window has lost keyboard focus

=item C<SDL_WINDOWEVENT_CLOSE> - The window manager requests that the window be closed

=item C<SDL_WINDOWEVENT_TAKE_FOCUS> - Window is being offered a focus (should C<SetWindowInputFocus( )> on itself or a subwindow, or ignore)

=item C<SDL_WINDOWEVENT_HIT_TEST> - Window had a hit test that wasn't C<SDL_HITTEST_NORMAL>.

=back

=head2 C<:displayEventID>

Event subtype for display events.

=over

=item C<SDL_DISPLAYEVENT_NONE> - Never used

=item C<SDL_DISPLAYEVENT_ORIENTATION> - Display orientation has changed to data1

=item C<SDL_DISPLAYEVENT_CONNECTED> - Display has been added to the system

=item C<SDL_DISPLAYEVENT_DISCONNECTED> - Display has been removed from the system

=back

=head2 C<:displayOrientation>

=over

=item C<SDL_ORIENTATION_UNKNOWN> - The display orientation can't be determined

=item C<SDL_ORIENTATION_LANDSCAPE> - The display is in landscape mode, with the right side up, relative to portrait mode

=item C<SDL_ORIENTATION_LANDSCAPE_FLIPPED> - The display is in landscape mode, with the left side up, relative to portrait mode

=item C<SDL_ORIENTATION_PORTRAIT> - The display is in portrait mode

=item C<SDL_ORIENTATION_PORTRAIT_FLIPPED> - The display is in portrait mode, upside down

=back

=head2 C<:glAttr>

OpenGL configuration attributes.

=over

=item C<SDL_GL_RED_SIZE>

=item C<SDL_GL_GREEN_SIZE>

=item C<SDL_GL_BLUE_SIZE>

=item C<SDL_GL_ALPHA_SIZE>

=item C<SDL_GL_BUFFER_SIZE>

=item C<SDL_GL_DOUBLEBUFFER>

=item C<SDL_GL_DEPTH_SIZE>

=item C<SDL_GL_STENCIL_SIZE>

=item C<SDL_GL_ACCUM_RED_SIZE>

=item C<SDL_GL_ACCUM_GREEN_SIZE>

=item C<SDL_GL_ACCUM_BLUE_SIZE>

=item C<SDL_GL_ACCUM_ALPHA_SIZE>

=item C<SDL_GL_STEREO>

=item C<SDL_GL_MULTISAMPLEBUFFERS>

=item C<SDL_GL_MULTISAMPLESAMPLES>

=item C<SDL_GL_ACCELERATED_VISUAL>

=item C<SDL_GL_RETAINED_BACKING>

=item C<SDL_GL_CONTEXT_MAJOR_VERSION>

=item C<SDL_GL_CONTEXT_MINOR_VERSION>

=item C<SDL_GL_CONTEXT_EGL>

=item C<SDL_GL_CONTEXT_FLAGS>

=item C<SDL_GL_CONTEXT_PROFILE_MASK>

=item C<SDL_GL_SHARE_WITH_CURRENT_CONTEXT>

=item C<SDL_GL_FRAMEBUFFER_SRGB_CAPABLE>

=item C<SDL_GL_CONTEXT_RELEASE_BEHAVIOR>

=item C<SDL_GL_CONTEXT_RESET_NOTIFICATION>

=item C<SDL_GL_CONTEXT_NO_ERROR>

=back

=head2 C<:glProfile>

=over

=item C<SDL_GL_CONTEXT_PROFILE_CORE>

=item C<SDL_GL_CONTEXT_PROFILE_COMPATIBILITY>

=item C<SDL_GL_CONTEXT_PROFILE_ES>

=back

=head2 C<:glContextFlag>

=over

=item C<SDL_GL_CONTEXT_DEBUG_FLAG>

=item C<SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG>

=item C<SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG>

=item C<SDL_GL_CONTEXT_RESET_ISOLATION_FLAG>

=back

=head2 C<:glContextReleaseFlag>

=over

=item C<SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE>

=item C<SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH>

=back

=head2 C<:glContextResetNotification>

=over

=item C<SDL_GL_CONTEXT_RESET_NO_NOTIFICATION>

=item C<SDL_GL_CONTEXT_RESET_LOSE_CONTEXT>

=back

=head2 C<:rendererFlags>

Flags used when creating a rendering context.

=over

=item C<SDL_RENDERER_SOFTWARE> - The renderer is a software fallback

=item C<SDL_RENDERER_ACCELERATED> - The renderer uses hardware acceleration

=item C<SDL_RENDERER_PRESENTVSYNC> - Present is synchronized with the refresh rate

=item C<SDL_RENDERER_TARGETTEXTURE> - The renderer supports rendering to texture

=back

=head2 C<:scaleMode>

The scaling mode for a texture.

=over

=item C<SDL_SCALEMODENEAREST> - nearest pixel sampling

=item C<SDL_SCALEMODELINEAR> - linear filtering

=item C<SDL_SCALEMODEBEST> - anisotropic filtering

=back

=head2 C<:textureAccess>

The access pattern allowed for a texture.

=over

=item C<SDL_TEXTUREACCESS_STATIC> - Changes rarely, not lockable

=item C<SDL_TEXTUREACCESS_STREAMING> - Changes frequently, lockable

=item C<SDL_TEXTUREACCESS_TARGET> - Texture can be used as a render target

=back

=head2 C<:textureModulate>

The texture channel modulation used in L<< C<SDL_RenderCopy( ...
)>|/C<SDL_RenderCopy( ... )> >>.

=over

=item C<SDL_TEXTUREMODULATE_NONE> - No modulation

=item C<SDL_TEXTUREMODULATE_COLOR> - srcC = srcC * color

=item C<SDL_TEXTUREMODULATE_ALPHA> - srcA = srcA * alpha

=back

=head2 C<:renderFlip>

Flip constants for L<< C<SDL_RenderCopyEx( ... )>|/C<SDL_RenderCopyEx( ... )>
>>.

=over

=item C<SDL_FLIP_NONE> - do not flip

=item C<SDL_FLIP_HORIZONTAL> - flip horizontally

=item C<SDL_FLIP_VERTICAL> - flip vertically

=back

=head2 C<:blendMode>

The blend mode used in L<< C<SDL_RenderCopy( ... )>|/C<SDL_RenderCopy( ... )>
>> and drawing operations.

=over

=item C<SDL_BLENDMODE_NONE> - no blending

	dstRGBA = srcRGBA

=item C<SDL_BLENDMODE_BLEND> - alpha blending

	dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
    dstA = srcA + (dstA * (1-srcA))

=item C<SDL_BLENDMODE_ADD> - additive blending

	dstRGB = (srcRGB * srcA) + dstRGB
	dstA = dstA

=item C<SDL_BLENDMODE_MOD> - color modulate

	dstRGB = srcRGB * dstRGB
	dstA = dstA

=item C<SDL_BLENDMODE_MUL> - color multiply

	dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
	dstA = (srcA * dstA) + (dstA * (1-srcA))

=item C<SDL_BLENDMODE_INVALID> -

=back

Additional custom blend modes can be returned by L<<
C<SDL_ComposeCustomBlendMode( ... )>|/C<SDL_ComposeCustomBlendMode( ... )> >>

=head2 C<:blendOperation>

The blend operation used when combining source and destination pixel
components.

=over

=item C<SDL_BLENDOPERATION_ADD> - C<dst + src>: supported by all renderers

=item C<SDL_BLENDOPERATION_SUBTRACT> - C<dst - src>: supported by D3D9, D3D11, OpenGL, OpenGLES

=item C<SDL_BLENDOPERATION_REV_SUBTRACT> - C<src - dst>: supported by D3D9, D3D11, OpenGL, OpenGLES

=item C<SDL_BLENDOPERATION_MINIMUM> - C<min(dst, src)>: supported by D3D11

=item C<SDL_BLENDOPERATION_MAXIMUM> - C<max(dst, src)>: supported by D3D11

=back

=head2 C<:blendFactor>

The normalized factor used to multiply pixel components.

=over

=item C<SDL_BLENDFACTOR_ZERO> - C<0, 0, 0, 0>

=item C<SDL_BLENDFACTOR_ONE> - C<1, 1, 1, 1>

=item C<SDL_BLENDFACTOR_SRC_COLOR> - C<srcR, srcG, srcB, srcA>

=item C<SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR> - C<1-srcR, 1-srcG, 1-srcB, 1-srcA>

=item C<SDL_BLENDFACTOR_SRC_ALPHA> - C<srcA, srcA, srcA, srcA>

=item C<SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA> - C<1-srcA, 1-srcA, 1-srcA, 1-srcA>

=item C<SDL_BLENDFACTOR_DST_COLOR> - C<dstR, dstG, dstB, dstA>

=item C<SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR> - C<1-dstR, 1-dstG, 1-dstB, 1-dstA>

=item C<SDL_BLENDFACTOR_DST_ALPHA> - C<dstA, dstA, dstA, dstA>

=item C<SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA> - C<1-dstA, 1-dstA, 1-dstA, 1-dstA>

=back

=head2 C<:audio>

Audio format flags.

These are what the 16 bits in SDL_AudioFormat currently mean... (Unspecified
bits are always zero).

    ++-----------------------sample is signed if set
    ||
    ||       ++-----------sample is bigendian if set
    ||       ||
    ||       ||          ++---sample is float if set
    ||       ||          ||
    ||       ||          || +---sample bit size---+
    ||       ||          || |                     |
    15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00

There are macros in SDL 2.0 and later to query these bits.

=head3 Audio flags

=over

=item C<SDL_AUDIO_MASK_BITSIZE>

=item C<SDL_AUDIO_MASK_DATATYPE>

=item C<SDL_AUDIO_MASK_ENDIAN>

=item C<SDL_AUDIO_MASK_SIGNED>

=item C<SDL_AUDIO_BITSIZE>

=item C<SDL_AUDIO_ISFLOAT>

=item C<SDL_AUDIO_ISBIGENDIAN>

=item C<SDL_AUDIO_ISSIGNED>

=item C<SDL_AUDIO_ISINT>

=item C<SDL_AUDIO_ISLITTLEENDIAN>

=item C<SDL_AUDIO_ISUNSIGNED>

=back

=head3 Audio format flags

Defaults to LSB byte order.

=over

=item C<AUDIO_U8> - Unsigned 8-bit samples

=item C<AUDIO_S8> - Signed 8-bit samples

=item C<AUDIO_U16LSB> - Unsigned 16-bit samples

=item C<AUDIO_S16LSB> - Signed 16-bit samples

=item C<AUDIO_U16MSB> - As above, but big-endian byte order

=item C<AUDIO_S16MSB> - As above, but big-endian byte order

=item C<AUDIO_U16> - C<AUDIO_U16LSB>

=item C<AUDIO_S16> - C<AUDIO_S16LSB>

=back

=head3 C<int32> support

=over

=item C<AUDIO_S32LSB> - 32-bit integer samples

=item C<AUDIO_S32MSB> - As above, but big-endian byte order

=item C<AUDIO_S32> - C<AUDIO_S32LSB>

=back

=head3 C<float32> support

=over

=item C<AUDIO_F32LSB> - 32-bit floating point samples

=item C<AUDIO_F32MSB> - As above, but big-endian byte order

=item C<AUDIO_F32> - C<AUDIO_F32LSB>

=back

=head3 Native audio byte ordering

=over

=item C<AUDIO_U16SYS>

=item C<AUDIO_S16SYS>

=item C<AUDIO_S32SYS>

=item C<AUDIO_F32SYS>

=back

=head3 Allow change flags

Which audio format changes are allowed when opening a device.

=over

=item C<SDL_AUDIO_ALLOW_FREQUENCY_CHANGE>

=item C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>

=item C<SDL_AUDIO_ALLOW_CHANNELS_CHANGE>

=item C<SDL_AUDIO_ALLOW_SAMPLES_CHANGE>

=item C<SDL_AUDIO_ALLOW_ANY_CHANGE>

=back

=head1 Development

SDL2 is still in early development: the majority of SDL's functions have yet to
be implemented and the interface may also grow to be less sugary leading up to
an eventual 1.0 release. If you like stable, well tested software that performs
as documented, you should hold off on trying to use SDL2 for a bit.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

libSDL enum iOS iPhone tvOS gamepad gamepads bitmap colorkey asyncify keycode
ctrl+click OpenGL glibc pthread screensaver fullscreen SDL_gamecontroller.h
XBox XInput pthread pthreads realtime rtkit Keycode mutexes resources imple
irectMedia ayer errstr coderef patchlevel distro WinRT raspberrypi psp macOS
NSHighResolutionCapable lowlevel vsync gamecontroller framebuffer XRandR
XVidMode libc musl non letterbox libsamplerate AVAudioSessionCategoryAmbient
AVAudioSessionCategoryPlayback VoIP OpenGLES opengl opengles opengles2 spammy
popup tooltip taskbar subwindow high-dpi subpixel borderless draggable viewport
user-resizable resizable srcA srcC GiB dstrect rect subrectangle pseudocode ms
verystrict resampler eglSwapBuffers backbuffer scancode unhandled lifespan wgl
glX framerate deadzones vice-versa kmsdrm jp CAMetalLayer touchpad autodetect
autocenter encodings artesian buttonstate

=end stopwords

=cut

};
1;
