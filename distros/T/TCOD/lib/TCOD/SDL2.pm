# ABSTRACT: A minimal SDL2 binding, while we wait for a stable one in CPAN
package
    TCOD::SDL2;

use strict;
use warnings;

use Config;
use FFI::C;
use FFI::CheckLib ();
use FFI::Platypus 1.00;
use Ref::Util ();

my $enum;
BEGIN {
    $enum = sub {
        require constant;

        my %enums = @_;
        while ( my ( $name, $values ) = each %enums ) {
            my $const;

            if ( Ref::Util::is_arrayref $values ) {
                my $i = 0;
                for ( @$values ) {
                    my ( $k, $v ) = split '=', $_, 2;
                    $i = eval $v if defined $v;
                    $const->{$k} = $i++;
                }
            }
            elsif ( Ref::Util::is_hashref $values ) {
                $const = $values;
            }
            else  {
                die 'Unrecognised reference: ' . ref $values;
            }

            constant->import($const);

            my $variable = __PACKAGE__ . '::' . $name;
            no strict 'refs';
            %{$variable} = ( %{$variable}, reverse %$const );
        }
    };
}

use constant {
    BYTEORDER            => $Config{byteorder},
    BIG_ENDIAN           => 4321,
    PIXELFORMAT_RGBA8888 => 373694468,
    PIXELFORMAT_ABGR8888 => 376840196,
    K_SCANCODE_MASK      => 1 << 30,
};

use constant PIXELFORMAT_RGBA32 => ( BYTEORDER == BIG_ENDIAN )
    ? PIXELFORMAT_RGBA8888
    : PIXELFORMAT_ABGR8888;

BEGIN {
    $enum->(
        InitFlags => {
            INIT_TIMER          => 0x000001,
            INIT_AUDIO          => 0x000010,
            INIT_VIDEO          => 0x000020,
            INIT_JOYSTICK       => 0x000200,
            INIT_HAPTIC         => 0x001000,
            INIT_GAMECONTROLLER => 0x002000,
            INIT_EVENTS         => 0x004000,
            INIT_SENSOR         => 0x008000,
            INIT_NOPARACHUTE    => 0x100000,
        },
        EventType => [qw(
            FIRSTEVENT=0

            QUIT=0x100

            APP_TERMINATING
            APP_LOWMEMORY
            APP_WILLENTERBACKGROUND
            APP_DIDENTERBACKGROUND
            APP_WILLENTERFOREGROUND
            APP_DIDENTERFOREGROUND

            LOCALECHANGED

            DISPLAYEVENT=0x150

            WINDOWEVENT=0x200
            SYSWMEVENT

            KEYDOWN=0x300
            KEYUP
            TEXTEDITING
            TEXTINPUT
            KEYMAPCHANGED

            MOUSEMOTION=0x400
            MOUSEBUTTONDOWN
            MOUSEBUTTONUP
            MOUSEWHEEL

            JOYAXISMOTION=0x600
            JOYBALLMOTION
            JOYHATMOTION
            JOYBUTTONDOWN
            JOYBUTTONUP
            JOYDEVICEADDED
            JOYDEVICEREMOVED

            CONTROLLERAXISMOTION=0x650
            CONTROLLERBUTTONDOWN
            CONTROLLERBUTTONUP
            CONTROLLERDEVICEADDED
            CONTROLLERDEVICEREMOVED
            CONTROLLERDEVICEREMAPPED
            CONTROLLERTOUCHPADDOWN
            CONTROLLERTOUCHPADMOTION
            CONTROLLERTOUCHPADUP
            CONTROLLERSENSORUPDATE

            FINGERDOWN=0x700
            FINGERUP
            FINGERMOTION

            DOLLARGESTURE=0x800
            DOLLARRECORD
            MULTIGESTURE

            CLIPBOARDUPDATE=0x900

            DROPFILE=0x1000
            DROPTEXT
            DROPBEGIN
            DROPCOMPLETE

            AUDIODEVICEADDED=0x1100
            AUDIODEVICEREMOVED

            SENSORUPDATE=0x1200

            RENDER_TARGETS_RESET=0x2000
            RENDER_DEVICE_RESET

            USEREVENT=0x8000

            LASTEVENT=0xFFFF
        )],
        ScanCode => [qw(
            SCANCODE_UNKNOWN

            SCANCODE_A=4
            SCANCODE_B
            SCANCODE_C
            SCANCODE_D
            SCANCODE_E
            SCANCODE_F
            SCANCODE_G
            SCANCODE_H
            SCANCODE_I
            SCANCODE_J
            SCANCODE_K
            SCANCODE_L
            SCANCODE_M
            SCANCODE_N
            SCANCODE_O
            SCANCODE_P
            SCANCODE_Q
            SCANCODE_R
            SCANCODE_S
            SCANCODE_T
            SCANCODE_U
            SCANCODE_V
            SCANCODE_W
            SCANCODE_X
            SCANCODE_Y
            SCANCODE_Z
            SCANCODE_1
            SCANCODE_2
            SCANCODE_3
            SCANCODE_4
            SCANCODE_5
            SCANCODE_6
            SCANCODE_7
            SCANCODE_8
            SCANCODE_9
            SCANCODE_0
            SCANCODE_RETURN
            SCANCODE_ESCAPE
            SCANCODE_BACKSPACE
            SCANCODE_TAB
            SCANCODE_SPACE
            SCANCODE_MINUS
            SCANCODE_EQUALS
            SCANCODE_LEFTBRACKET
            SCANCODE_RIGHTBRACKET
            SCANCODE_BACKSLASH
            SCANCODE_NONUSHASH
            SCANCODE_SEMICOLON
            SCANCODE_APOSTROPHE
            SCANCODE_GRAVE
            SCANCODE_COMMA
            SCANCODE_PERIOD
            SCANCODE_SLASH
            SCANCODE_CAPSLOCK
            SCANCODE_F1
            SCANCODE_F2
            SCANCODE_F3
            SCANCODE_F4
            SCANCODE_F5
            SCANCODE_F6
            SCANCODE_F7
            SCANCODE_F8
            SCANCODE_F9
            SCANCODE_F10
            SCANCODE_F11
            SCANCODE_F12
            SCANCODE_PRINTSCREEN
            SCANCODE_SCROLLLOCK
            SCANCODE_PAUSE
            SCANCODE_INSERT
            SCANCODE_HOME
            SCANCODE_PAGEUP
            SCANCODE_DELETE
            SCANCODE_END
            SCANCODE_PAGEDOWN
            SCANCODE_RIGHT
            SCANCODE_LEFT
            SCANCODE_DOWN
            SCANCODE_UP
            SCANCODE_NUMLOCKCLEAR
            SCANCODE_KP_DIVIDE
            SCANCODE_KP_MULTIPLY
            SCANCODE_KP_MINUS
            SCANCODE_KP_PLUS
            SCANCODE_KP_ENTER
            SCANCODE_KP_1
            SCANCODE_KP_2
            SCANCODE_KP_3
            SCANCODE_KP_4
            SCANCODE_KP_5
            SCANCODE_KP_6
            SCANCODE_KP_7
            SCANCODE_KP_8
            SCANCODE_KP_9
            SCANCODE_KP_0
            SCANCODE_KP_PERIOD
            SCANCODE_NONUSBACKSLASH
            SCANCODE_APPLICATION
            SCANCODE_POWER
            SCANCODE_KP_EQUALS
            SCANCODE_F13
            SCANCODE_F14
            SCANCODE_F15
            SCANCODE_F16
            SCANCODE_F17
            SCANCODE_F18
            SCANCODE_F19
            SCANCODE_F20
            SCANCODE_F21
            SCANCODE_F22
            SCANCODE_F23
            SCANCODE_F24
            SCANCODE_EXECUTE
            SCANCODE_HELP
            SCANCODE_MENU
            SCANCODE_SELECT
            SCANCODE_STOP
            SCANCODE_AGAIN
            SCANCODE_UNDO
            SCANCODE_CUT
            SCANCODE_COPY
            SCANCODE_PASTE
            SCANCODE_FIND
            SCANCODE_MUTE
            SCANCODE_VOLUMEUP
            SCANCODE_VOLUMEDOWN
            SCANCODE_KP_COMMA
            SCANCODE_KP_EQUALSAS400
            SCANCODE_INTERNATIONAL1
            SCANCODE_INTERNATIONAL2
            SCANCODE_INTERNATIONAL3
            SCANCODE_INTERNATIONAL4
            SCANCODE_INTERNATIONAL5
            SCANCODE_INTERNATIONAL6
            SCANCODE_INTERNATIONAL7
            SCANCODE_INTERNATIONAL8
            SCANCODE_INTERNATIONAL9
            SCANCODE_LANG1
            SCANCODE_LANG2
            SCANCODE_LANG3
            SCANCODE_LANG4
            SCANCODE_LANG5
            SCANCODE_LANG6
            SCANCODE_LANG7
            SCANCODE_LANG8
            SCANCODE_LANG9
            SCANCODE_ALTERASE
            SCANCODE_SYSREQ
            SCANCODE_CANCEL
            SCANCODE_CLEAR
            SCANCODE_PRIOR
            SCANCODE_RETURN2
            SCANCODE_SEPARATOR
            SCANCODE_OUT
            SCANCODE_OPER
            SCANCODE_CLEARAGAIN
            SCANCODE_CRSEL
            SCANCODE_EXSEL

            SCANCODE_KP_00=176
            SCANCODE_KP_000
            SCANCODE_THOUSANDSSEPARATOR
            SCANCODE_DECIMALSEPARATOR
            SCANCODE_CURRENCYUNIT
            SCANCODE_CURRENCYSUBUNIT
            SCANCODE_KP_LEFTPAREN
            SCANCODE_KP_RIGHTPAREN
            SCANCODE_KP_LEFTBRACE
            SCANCODE_KP_RIGHTBRACE
            SCANCODE_KP_TAB
            SCANCODE_KP_BACKSPACE
            SCANCODE_KP_A
            SCANCODE_KP_B
            SCANCODE_KP_C
            SCANCODE_KP_D
            SCANCODE_KP_E
            SCANCODE_KP_F
            SCANCODE_KP_XOR
            SCANCODE_KP_POWER
            SCANCODE_KP_PERCENT
            SCANCODE_KP_LESS
            SCANCODE_KP_GREATER
            SCANCODE_KP_AMPERSAND
            SCANCODE_KP_DBLAMPERSAND
            SCANCODE_KP_VERTICALBAR
            SCANCODE_KP_DBLVERTICALBAR
            SCANCODE_KP_COLON
            SCANCODE_KP_HASH
            SCANCODE_KP_SPACE
            SCANCODE_KP_AT
            SCANCODE_KP_EXCLAM
            SCANCODE_KP_MEMSTORE
            SCANCODE_KP_MEMRECALL
            SCANCODE_KP_MEMCLEAR
            SCANCODE_KP_MEMADD
            SCANCODE_KP_MEMSUBTRACT
            SCANCODE_KP_MEMMULTIPLY
            SCANCODE_KP_MEMDIVIDE
            SCANCODE_KP_PLUSMINUS
            SCANCODE_KP_CLEAR
            SCANCODE_KP_CLEARENTRY
            SCANCODE_KP_BINARY
            SCANCODE_KP_OCTAL
            SCANCODE_KP_DECIMAL
            SCANCODE_KP_HEXADECIMAL

            SCANCODE_LCTRL=224
            SCANCODE_LSHIFT
            SCANCODE_LALT
            SCANCODE_LGUI
            SCANCODE_RCTRL
            SCANCODE_RSHIFT
            SCANCODE_RALT
            SCANCODE_RGUI

            SCANCODE_MODE=257
            SCANCODE_AUDIONEXT
            SCANCODE_AUDIOPREV
            SCANCODE_AUDIOSTOP
            SCANCODE_AUDIOPLAY
            SCANCODE_AUDIOMUTE
            SCANCODE_MEDIASELECT
            SCANCODE_WWW
            SCANCODE_MAIL
            SCANCODE_CALCULATOR
            SCANCODE_COMPUTER
            SCANCODE_AC_SEARCH
            SCANCODE_AC_HOME
            SCANCODE_AC_BACK
            SCANCODE_AC_FORWARD
            SCANCODE_AC_STOP
            SCANCODE_AC_REFRESH
            SCANCODE_AC_BOOKMARKS
            SCANCODE_BRIGHTNESSDOWN
            SCANCODE_BRIGHTNESSUP
            SCANCODE_DISPLAYSWITCH
            SCANCODE_KBDILLUMTOGGLE
            SCANCODE_KBDILLUMDOWN
            SCANCODE_KBDILLUMUP
            SCANCODE_EJECT
            SCANCODE_SLEEP
            SCANCODE_APP1
            SCANCODE_APP2
            SCANCODE_AUDIOREWIND
            SCANCODE_AUDIOFASTFORWARD

            NUM_SCANCODES=512
        )],
        Keymod => {
            KMOD_NONE     => 0x0000,
            KMOD_LSHIFT   => 0x0001,
            KMOD_RSHIFT   => 0x0002,
            KMOD_LCTRL    => 0x0040,
            KMOD_RCTRL    => 0x0080,
            KMOD_LALT     => 0x0100,
            KMOD_RALT     => 0x0200,
            KMOD_LGUI     => 0x0400,
            KMOD_RGUI     => 0x0800,
            KMOD_NUM      => 0x1000,
            KMOD_CAPS     => 0x2000,
            KMOD_MODE     => 0x4000,
            KMOD_RESERVED => 0x8000,
        },
        WindowEventID => [qw(
            WINDOWEVENT_NONE
            WINDOWEVENT_SHOWN
            WINDOWEVENT_HIDDEN
            WINDOWEVENT_EXPOSED
            WINDOWEVENT_MOVED
            WINDOWEVENT_RESIZED
            WINDOWEVENT_SIZE_CHANGED
            WINDOWEVENT_MINIMIZED
            WINDOWEVENT_MAXIMIZED
            WINDOWEVENT_RESTORED
            WINDOWEVENT_ENTER
            WINDOWEVENT_LEAVE
            WINDOWEVENT_FOCUS_GAINED
            WINDOWEVENT_FOCUS_LOST
            WINDOWEVENT_CLOSE
            WINDOWEVENT_TAKE_FOCUS
            WINDOWEVENT_HIT_TEST
        )],
        WindowFlags => {
            WINDOW_FULLSCREEN         => 0x00000001,
            WINDOW_OPENGL             => 0x00000002,
            WINDOW_SHOWN              => 0x00000004,
            WINDOW_HIDDEN             => 0x00000008,
            WINDOW_BORDERLESS         => 0x00000010,
            WINDOW_RESIZABLE          => 0x00000020,
            WINDOW_MINIMIZED          => 0x00000040,
            WINDOW_MAXIMIZED          => 0x00000080,
            WINDOW_MOUSE_GRABBED      => 0x00000100,
            WINDOW_INPUT_FOCUS        => 0x00000200,
            WINDOW_MOUSE_FOCUS        => 0x00000400,
            WINDOW_FULLSCREEN_DESKTOP => 0x00001001,
            WINDOW_FOREIGN            => 0x00000800,
            WINDOW_ALLOW_HIGHDPI      => 0x00002000,
            WINDOW_MOUSE_CAPTURE      => 0x00004000,
            WINDOW_ALWAYS_ON_TOP      => 0x00008000,
            WINDOW_SKIP_TASKBAR       => 0x00010000,
            WINDOW_UTILITY            => 0x00020000,
            WINDOW_TOOLTIP            => 0x00040000,
            WINDOW_POPUP_MENU         => 0x00080000,
            WINDOW_KEYBOARD_GRABBED   => 0x00100000,
            WINDOW_VULKAN             => 0x10000000,
            WINDOW_METAL              => 0x20000000,
            WINDOW_INPUT_GRABBED      => 0x00000100,
        },
    );
}

BEGIN {
    $enum->(
        Keymod => {
            KMOD_CTRL  => KMOD_LCTRL  | KMOD_RCTRL,
            KMOD_SHIFT => KMOD_LSHIFT | KMOD_RSHIFT,
            KMOD_ALT   => KMOD_LALT   | KMOD_RALT,
            KMOD_GUI   => KMOD_LGUI   | KMOD_RGUI,
        },
        Keycode => {
            K_UNKNOWN            => 0,
            K_RETURN             => ord "\r",
            K_ESCAPE             => 27, # 033
            K_BACKSPACE          => ord "\b",
            K_TAB                => ord "\t",
            K_SPACE              => ord ' ',
            K_EXCLAIM            => ord '!',
            K_QUOTEDBL           => ord '"',
            K_HASH               => ord '#',
            K_PERCENT            => ord '%',
            K_DOLLAR             => ord '$',
            K_AMPERSAND          => ord '&',
            K_QUOTE              => ord "'",
            K_LEFTPAREN          => ord '(',
            K_RIGHTPAREN         => ord ')',
            K_ASTERISK           => ord '*',
            K_PLUS               => ord '+',
            K_COMMA              => ord ',',
            K_MINUS              => ord '-',
            K_PERIOD             => ord '.',
            K_SLASH              => ord '/',
            K_0                  => ord '0',
            K_1                  => ord '1',
            K_2                  => ord '2',
            K_3                  => ord '3',
            K_4                  => ord '4',
            K_5                  => ord '5',
            K_6                  => ord '6',
            K_7                  => ord '7',
            K_8                  => ord '8',
            K_9                  => ord '9',
            K_COLON              => ord ':',
            K_SEMICOLON          => ord ';',
            K_LESS               => ord '<',
            K_EQUALS             => ord '=',
            K_GREATER            => ord '>',
            K_QUESTION           => ord '?',
            K_AT                 => ord '@',
            K_LEFTBRACKET        => ord '[',
            K_BACKSLASH          => ord '\\',
            K_RIGHTBRACKET       => ord ']',
            K_CARET              => ord '^',
            K_UNDERSCORE         => ord '_',
            K_BACKQUOTE          => ord '`',
            K_a                  => ord 'a',
            K_b                  => ord 'b',
            K_c                  => ord 'c',
            K_d                  => ord 'd',
            K_e                  => ord 'e',
            K_f                  => ord 'f',
            K_g                  => ord 'g',
            K_h                  => ord 'h',
            K_i                  => ord 'i',
            K_j                  => ord 'j',
            K_k                  => ord 'k',
            K_l                  => ord 'l',
            K_m                  => ord 'm',
            K_n                  => ord 'n',
            K_o                  => ord 'o',
            K_p                  => ord 'p',
            K_q                  => ord 'q',
            K_r                  => ord 'r',
            K_s                  => ord 's',
            K_t                  => ord 't',
            K_u                  => ord 'u',
            K_v                  => ord 'v',
            K_w                  => ord 'w',
            K_x                  => ord 'x',
            K_y                  => ord 'y',
            K_z                  => ord 'z',

            K_CAPSLOCK           => SCANCODE_CAPSLOCK           | K_SCANCODE_MASK,

            K_F1                 => SCANCODE_F1                 | K_SCANCODE_MASK,
            K_F2                 => SCANCODE_F2                 | K_SCANCODE_MASK,
            K_F3                 => SCANCODE_F3                 | K_SCANCODE_MASK,
            K_F4                 => SCANCODE_F4                 | K_SCANCODE_MASK,
            K_F5                 => SCANCODE_F5                 | K_SCANCODE_MASK,
            K_F6                 => SCANCODE_F6                 | K_SCANCODE_MASK,
            K_F7                 => SCANCODE_F7                 | K_SCANCODE_MASK,
            K_F8                 => SCANCODE_F8                 | K_SCANCODE_MASK,
            K_F9                 => SCANCODE_F9                 | K_SCANCODE_MASK,
            K_F10                => SCANCODE_F10                | K_SCANCODE_MASK,
            K_F11                => SCANCODE_F11                | K_SCANCODE_MASK,
            K_F12                => SCANCODE_F12                | K_SCANCODE_MASK,

            K_PRINTSCREEN        => SCANCODE_PRINTSCREEN        | K_SCANCODE_MASK,
            K_SCROLLLOCK         => SCANCODE_SCROLLLOCK         | K_SCANCODE_MASK,
            K_PAUSE              => SCANCODE_PAUSE              | K_SCANCODE_MASK,
            K_INSERT             => SCANCODE_INSERT             | K_SCANCODE_MASK,
            K_HOME               => SCANCODE_HOME               | K_SCANCODE_MASK,
            K_PAGEUP             => SCANCODE_PAGEUP             | K_SCANCODE_MASK,
            K_DELETE             => 127, # 0177
            K_END                => SCANCODE_END                | K_SCANCODE_MASK,
            K_PAGEDOWN           => SCANCODE_PAGEDOWN           | K_SCANCODE_MASK,
            K_RIGHT              => SCANCODE_RIGHT              | K_SCANCODE_MASK,
            K_LEFT               => SCANCODE_LEFT               | K_SCANCODE_MASK,
            K_DOWN               => SCANCODE_DOWN               | K_SCANCODE_MASK,
            K_UP                 => SCANCODE_UP                 | K_SCANCODE_MASK,

            K_NUMLOCKCLEAR       => SCANCODE_NUMLOCKCLEAR       | K_SCANCODE_MASK,
            K_KP_DIVIDE          => SCANCODE_KP_DIVIDE          | K_SCANCODE_MASK,
            K_KP_MULTIPLY        => SCANCODE_KP_MULTIPLY        | K_SCANCODE_MASK,
            K_KP_MINUS           => SCANCODE_KP_MINUS           | K_SCANCODE_MASK,
            K_KP_PLUS            => SCANCODE_KP_PLUS            | K_SCANCODE_MASK,
            K_KP_ENTER           => SCANCODE_KP_ENTER           | K_SCANCODE_MASK,
            K_KP_1               => SCANCODE_KP_1               | K_SCANCODE_MASK,
            K_KP_2               => SCANCODE_KP_2               | K_SCANCODE_MASK,
            K_KP_3               => SCANCODE_KP_3               | K_SCANCODE_MASK,
            K_KP_4               => SCANCODE_KP_4               | K_SCANCODE_MASK,
            K_KP_5               => SCANCODE_KP_5               | K_SCANCODE_MASK,
            K_KP_6               => SCANCODE_KP_6               | K_SCANCODE_MASK,
            K_KP_7               => SCANCODE_KP_7               | K_SCANCODE_MASK,
            K_KP_8               => SCANCODE_KP_8               | K_SCANCODE_MASK,
            K_KP_9               => SCANCODE_KP_9               | K_SCANCODE_MASK,
            K_KP_0               => SCANCODE_KP_0               | K_SCANCODE_MASK,
            K_KP_PERIOD          => SCANCODE_KP_PERIOD          | K_SCANCODE_MASK,

            K_APPLICATION        => SCANCODE_APPLICATION        | K_SCANCODE_MASK,
            K_POWER              => SCANCODE_POWER              | K_SCANCODE_MASK,
            K_KP_EQUALS          => SCANCODE_KP_EQUALS          | K_SCANCODE_MASK,
            K_F13                => SCANCODE_F13                | K_SCANCODE_MASK,
            K_F14                => SCANCODE_F14                | K_SCANCODE_MASK,
            K_F15                => SCANCODE_F15                | K_SCANCODE_MASK,
            K_F16                => SCANCODE_F16                | K_SCANCODE_MASK,
            K_F17                => SCANCODE_F17                | K_SCANCODE_MASK,
            K_F18                => SCANCODE_F18                | K_SCANCODE_MASK,
            K_F19                => SCANCODE_F19                | K_SCANCODE_MASK,
            K_F20                => SCANCODE_F20                | K_SCANCODE_MASK,
            K_F21                => SCANCODE_F21                | K_SCANCODE_MASK,
            K_F22                => SCANCODE_F22                | K_SCANCODE_MASK,
            K_F23                => SCANCODE_F23                | K_SCANCODE_MASK,
            K_F24                => SCANCODE_F24                | K_SCANCODE_MASK,
            K_EXECUTE            => SCANCODE_EXECUTE            | K_SCANCODE_MASK,
            K_HELP               => SCANCODE_HELP               | K_SCANCODE_MASK,
            K_MENU               => SCANCODE_MENU               | K_SCANCODE_MASK,
            K_SELECT             => SCANCODE_SELECT             | K_SCANCODE_MASK,
            K_STOP               => SCANCODE_STOP               | K_SCANCODE_MASK,
            K_AGAIN              => SCANCODE_AGAIN              | K_SCANCODE_MASK,
            K_UNDO               => SCANCODE_UNDO               | K_SCANCODE_MASK,
            K_CUT                => SCANCODE_CUT                | K_SCANCODE_MASK,
            K_COPY               => SCANCODE_COPY               | K_SCANCODE_MASK,
            K_PASTE              => SCANCODE_PASTE              | K_SCANCODE_MASK,
            K_FIND               => SCANCODE_FIND               | K_SCANCODE_MASK,
            K_MUTE               => SCANCODE_MUTE               | K_SCANCODE_MASK,
            K_VOLUMEUP           => SCANCODE_VOLUMEUP           | K_SCANCODE_MASK,
            K_VOLUMEDOWN         => SCANCODE_VOLUMEDOWN         | K_SCANCODE_MASK,
            K_KP_COMMA           => SCANCODE_KP_COMMA           | K_SCANCODE_MASK,
            K_KP_EQUALSAS400     => SCANCODE_KP_EQUALSAS400     | K_SCANCODE_MASK,

            K_ALTERASE           => SCANCODE_ALTERASE           | K_SCANCODE_MASK,
            K_SYSREQ             => SCANCODE_SYSREQ             | K_SCANCODE_MASK,
            K_CANCEL             => SCANCODE_CANCEL             | K_SCANCODE_MASK,
            K_CLEAR              => SCANCODE_CLEAR              | K_SCANCODE_MASK,
            K_PRIOR              => SCANCODE_PRIOR              | K_SCANCODE_MASK,
            K_RETURN2            => SCANCODE_RETURN2            | K_SCANCODE_MASK,
            K_SEPARATOR          => SCANCODE_SEPARATOR          | K_SCANCODE_MASK,
            K_OUT                => SCANCODE_OUT                | K_SCANCODE_MASK,
            K_OPER               => SCANCODE_OPER               | K_SCANCODE_MASK,
            K_CLEARAGAIN         => SCANCODE_CLEARAGAIN         | K_SCANCODE_MASK,
            K_CRSEL              => SCANCODE_CRSEL              | K_SCANCODE_MASK,
            K_EXSEL              => SCANCODE_EXSEL              | K_SCANCODE_MASK,

            K_KP_00              => SCANCODE_KP_00              | K_SCANCODE_MASK,
            K_KP_000             => SCANCODE_KP_000             | K_SCANCODE_MASK,
            K_THOUSANDSSEPARATOR => SCANCODE_THOUSANDSSEPARATOR | K_SCANCODE_MASK,
            K_DECIMALSEPARATOR   => SCANCODE_DECIMALSEPARATOR   | K_SCANCODE_MASK,
            K_CURRENCYUNIT       => SCANCODE_CURRENCYUNIT       | K_SCANCODE_MASK,
            K_CURRENCYSUBUNIT    => SCANCODE_CURRENCYSUBUNIT    | K_SCANCODE_MASK,
            K_KP_LEFTPAREN       => SCANCODE_KP_LEFTPAREN       | K_SCANCODE_MASK,
            K_KP_RIGHTPAREN      => SCANCODE_KP_RIGHTPAREN      | K_SCANCODE_MASK,
            K_KP_LEFTBRACE       => SCANCODE_KP_LEFTBRACE       | K_SCANCODE_MASK,
            K_KP_RIGHTBRACE      => SCANCODE_KP_RIGHTBRACE      | K_SCANCODE_MASK,
            K_KP_TAB             => SCANCODE_KP_TAB             | K_SCANCODE_MASK,
            K_KP_BACKSPACE       => SCANCODE_KP_BACKSPACE       | K_SCANCODE_MASK,
            K_KP_A               => SCANCODE_KP_A               | K_SCANCODE_MASK,
            K_KP_B               => SCANCODE_KP_B               | K_SCANCODE_MASK,
            K_KP_C               => SCANCODE_KP_C               | K_SCANCODE_MASK,
            K_KP_D               => SCANCODE_KP_D               | K_SCANCODE_MASK,
            K_KP_E               => SCANCODE_KP_E               | K_SCANCODE_MASK,
            K_KP_F               => SCANCODE_KP_F               | K_SCANCODE_MASK,
            K_KP_XOR             => SCANCODE_KP_XOR             | K_SCANCODE_MASK,
            K_KP_POWER           => SCANCODE_KP_POWER           | K_SCANCODE_MASK,
            K_KP_PERCENT         => SCANCODE_KP_PERCENT         | K_SCANCODE_MASK,
            K_KP_LESS            => SCANCODE_KP_LESS            | K_SCANCODE_MASK,
            K_KP_GREATER         => SCANCODE_KP_GREATER         | K_SCANCODE_MASK,
            K_KP_AMPERSAND       => SCANCODE_KP_AMPERSAND       | K_SCANCODE_MASK,
            K_KP_DBLAMPERSAND    => SCANCODE_KP_DBLAMPERSAND    | K_SCANCODE_MASK,
            K_KP_VERTICALBAR     => SCANCODE_KP_VERTICALBAR     | K_SCANCODE_MASK,
            K_KP_DBLVERTICALBAR  => SCANCODE_KP_DBLVERTICALBAR  | K_SCANCODE_MASK,
            K_KP_COLON           => SCANCODE_KP_COLON           | K_SCANCODE_MASK,
            K_KP_HASH            => SCANCODE_KP_HASH            | K_SCANCODE_MASK,
            K_KP_SPACE           => SCANCODE_KP_SPACE           | K_SCANCODE_MASK,
            K_KP_AT              => SCANCODE_KP_AT              | K_SCANCODE_MASK,
            K_KP_EXCLAM          => SCANCODE_KP_EXCLAM          | K_SCANCODE_MASK,
            K_KP_MEMSTORE        => SCANCODE_KP_MEMSTORE        | K_SCANCODE_MASK,
            K_KP_MEMRECALL       => SCANCODE_KP_MEMRECALL       | K_SCANCODE_MASK,
            K_KP_MEMCLEAR        => SCANCODE_KP_MEMCLEAR        | K_SCANCODE_MASK,
            K_KP_MEMADD          => SCANCODE_KP_MEMADD          | K_SCANCODE_MASK,
            K_KP_MEMSUBTRACT     => SCANCODE_KP_MEMSUBTRACT     | K_SCANCODE_MASK,
            K_KP_MEMMULTIPLY     => SCANCODE_KP_MEMMULTIPLY     | K_SCANCODE_MASK,
            K_KP_MEMDIVIDE       => SCANCODE_KP_MEMDIVIDE       | K_SCANCODE_MASK,
            K_KP_PLUSMINUS       => SCANCODE_KP_PLUSMINUS       | K_SCANCODE_MASK,
            K_KP_CLEAR           => SCANCODE_KP_CLEAR           | K_SCANCODE_MASK,
            K_KP_CLEARENTRY      => SCANCODE_KP_CLEARENTRY      | K_SCANCODE_MASK,
            K_KP_BINARY          => SCANCODE_KP_BINARY          | K_SCANCODE_MASK,
            K_KP_OCTAL           => SCANCODE_KP_OCTAL           | K_SCANCODE_MASK,
            K_KP_DECIMAL         => SCANCODE_KP_DECIMAL         | K_SCANCODE_MASK,
            K_KP_HEXADECIMAL     => SCANCODE_KP_HEXADECIMAL     | K_SCANCODE_MASK,

            K_LCTRL              => SCANCODE_LCTRL              | K_SCANCODE_MASK,
            K_LSHIFT             => SCANCODE_LSHIFT             | K_SCANCODE_MASK,
            K_LALT               => SCANCODE_LALT               | K_SCANCODE_MASK,
            K_LGUI               => SCANCODE_LGUI               | K_SCANCODE_MASK,
            K_RCTRL              => SCANCODE_RCTRL              | K_SCANCODE_MASK,
            K_RSHIFT             => SCANCODE_RSHIFT             | K_SCANCODE_MASK,
            K_RALT               => SCANCODE_RALT               | K_SCANCODE_MASK,
            K_RGUI               => SCANCODE_RGUI               | K_SCANCODE_MASK,

            K_MODE               => SCANCODE_MODE               | K_SCANCODE_MASK,

            K_AUDIONEXT          => SCANCODE_AUDIONEXT          | K_SCANCODE_MASK,
            K_AUDIOPREV          => SCANCODE_AUDIOPREV          | K_SCANCODE_MASK,
            K_AUDIOSTOP          => SCANCODE_AUDIOSTOP          | K_SCANCODE_MASK,
            K_AUDIOPLAY          => SCANCODE_AUDIOPLAY          | K_SCANCODE_MASK,
            K_AUDIOMUTE          => SCANCODE_AUDIOMUTE          | K_SCANCODE_MASK,
            K_MEDIASELECT        => SCANCODE_MEDIASELECT        | K_SCANCODE_MASK,
            K_WWW                => SCANCODE_WWW                | K_SCANCODE_MASK,
            K_MAIL               => SCANCODE_MAIL               | K_SCANCODE_MASK,
            K_CALCULATOR         => SCANCODE_CALCULATOR         | K_SCANCODE_MASK,
            K_COMPUTER           => SCANCODE_COMPUTER           | K_SCANCODE_MASK,
            K_AC_SEARCH          => SCANCODE_AC_SEARCH          | K_SCANCODE_MASK,
            K_AC_HOME            => SCANCODE_AC_HOME            | K_SCANCODE_MASK,
            K_AC_BACK            => SCANCODE_AC_BACK            | K_SCANCODE_MASK,
            K_AC_FORWARD         => SCANCODE_AC_FORWARD         | K_SCANCODE_MASK,
            K_AC_STOP            => SCANCODE_AC_STOP            | K_SCANCODE_MASK,
            K_AC_REFRESH         => SCANCODE_AC_REFRESH         | K_SCANCODE_MASK,
            K_AC_BOOKMARKS       => SCANCODE_AC_BOOKMARKS       | K_SCANCODE_MASK,

            K_BRIGHTNESSDOWN     => SCANCODE_BRIGHTNESSDOWN     | K_SCANCODE_MASK,
            K_BRIGHTNESSUP       => SCANCODE_BRIGHTNESSUP       | K_SCANCODE_MASK,
            K_DISPLAYSWITCH      => SCANCODE_DISPLAYSWITCH      | K_SCANCODE_MASK,
            K_KBDILLUMTOGGLE     => SCANCODE_KBDILLUMTOGGLE     | K_SCANCODE_MASK,
            K_KBDILLUMDOWN       => SCANCODE_KBDILLUMDOWN       | K_SCANCODE_MASK,
            K_KBDILLUMUP         => SCANCODE_KBDILLUMUP         | K_SCANCODE_MASK,
            K_EJECT              => SCANCODE_EJECT              | K_SCANCODE_MASK,
            K_SLEEP              => SCANCODE_SLEEP              | K_SCANCODE_MASK,
            K_APP1               => SCANCODE_APP1               | K_SCANCODE_MASK,
            K_APP2               => SCANCODE_APP2               | K_SCANCODE_MASK,

            K_AUDIOREWIND        => SCANCODE_AUDIOREWIND        | K_SCANCODE_MASK,
            K_AUDIOFASTFORWARD   => SCANCODE_AUDIOFASTFORWARD   | K_SCANCODE_MASK,
        },
    );
}

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib( FFI::CheckLib::find_lib_or_exit lib => 'SDL2' );
FFI::C->ffi($ffi);

$ffi->type( sint32 => 'SDL_BlendMode'      );
$ffi->type( sint32 => 'SDL_JoystickID'     );
$ffi->type( sint64 => 'SDL_TouchID'        );
$ffi->type( sint64 => 'SDL_FingerID'       );
$ffi->type( sint64 => 'SDL_GestureID'      );
$ffi->type( opaque => 'SDL_GLContext'      );
$ffi->type( opaque => 'SDL_GameController' );
$ffi->type( opaque => 'SDL_Joystick'       );
$ffi->type( opaque => 'SDL_RWops'          );
$ffi->type( opaque => 'SDL_Renderer'       );
$ffi->type( opaque => 'SDL_Texture'        );
$ffi->type( opaque => 'SDL_Window'         );
$ffi->type( uint8  => 'SDL_bool'           );

$ffi->mangler( sub { 'SDL_' . shift } );

# Event structs

package
    TCOD::SDL2::AudioDeviceEvent {
    FFI::C->struct( SDL_AudioDeviceEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'uint32',
        iscapture => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
    ]);
}

package
    TCOD::SDL2::ControllerAxisEvent {
    FFI::C->struct( SDL_ControllerAxisEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        axis      => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        value     => 'sint16',
        padding4  => 'uint16',
    ]);
}

package
    TCOD::SDL2::ControllerButtonEvent {
    FFI::C->struct( SDL_ControllerButtonEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        button    => 'uint8',
        state     => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
    ]);
}

package
    TCOD::SDL2::ControllerDeviceEvent {
    FFI::C->struct( SDL_ControllerDeviceEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
    ]);
}

package
    TCOD::SDL2::ControllerTouchpadEvent {
    FFI::C->struct( SDL_ControllerTouchpadEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        touchpad  => 'sint32',
        finger    => 'sint32',
        x         => 'float',
        y         => 'float',
        pressure  => 'float',
    ]);
}

package
    TCOD::SDL2::ControllerSensorEvent {
    FFI::C->struct( SDL_ControllerSensorEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        data      => 'float[3]',
    ]);
}

package
    TCOD::SDL2::DisplayEvent {
    FFI::C->struct( SDL_DisplayEvent => [
        type       => 'uint32',
        timestamp  => 'uint32',
        display    => 'uint32',
        event      => 'uint8',
        padding1   => 'uint8',
        padding2   => 'uint8',
        padding3   => 'uint8',
        data1      => 'sint32',
    ]);
}

package
    TCOD::SDL2::DollarGestureEvent {
    FFI::C->struct( SDL_DollarGestureEvent => [
        type       => 'uint32',
        timestamp  => 'uint32',
        touchId    => 'SDL_TouchID',
        gestureId  => 'SDL_GestureID',
        numFingers => 'uint32',
        error      => 'float',
        x          => 'float',
        y          => 'float',
    ]);
}

package
    TCOD::SDL2::DropEvent {
    FFI::C->struct( SDL_DropEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        _file     => 'opaque',
        windowID  => 'uint32',
    ]);

    sub file { $ffi->cast( opaque => string => shift->_file ) }
}

package
    TCOD::SDL2::JoyAxisEvent {
    FFI::C->struct( SDL_JoyAxisEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        axis      => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        value     => 'sint16',
        padding4  => 'uint16',
    ]);
}

package
    TCOD::SDL2::JoyBallEvent {
    FFI::C->struct( SDL_JoyBallEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        ball      => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        xrel      => 'sint16',
        yrel      => 'sint16',
    ]);
}

package
    TCOD::SDL2::JoyButtonEvent {
    FFI::C->struct( SDL_JoyButtonEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        button    => 'uint8',
        state     => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
    ]);
}

package
    TCOD::SDL2::JoyDeviceEvent {
    FFI::C->struct( SDL_JoyDeviceEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
    ]);
}

package
    TCOD::SDL2::JoyHatEvent {
    FFI::C->struct( SDL_JoyHatEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        hat       => 'uint8',
        value     => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
    ]);
}

package
    TCOD::SDL2::KeyboardEvent {
    FFI::C->struct( SDL_KeyboardEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        state     => 'uint8',
        repeat    => 'uint8',
        scancode  => 'sint32',
        sym       => 'sint32',
        mod       => 'uint16',
    ]);
}

package
    TCOD::SDL2::MouseButtonEvent {
    FFI::C->struct( SDL_MouseButtonEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        which     => 'uint32',
        button    => 'uint8',
        state     => 'uint8',
        clicks    => 'uint8',
        padding1  => 'uint8',
        x         => 'sint32',
        y         => 'sint32',
    ]);
}

package
    TCOD::SDL2::MouseMotionEvent {
    FFI::C->struct( SDL_MouseMotionEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        which     => 'uint32',
        state     => 'uint32',
        x         => 'sint32',
        y         => 'sint32',
        xrel      => 'sint32',
        yrel      => 'sint32',
    ]);
}

package
    TCOD::SDL2::MouseWheelEvent {
    FFI::C->struct( SDL_MouseWheelEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        which     => 'uint32',
        x         => 'sint32',
        y         => 'sint32',
        direction => 'uint32',
    ]);
}

package
    TCOD::SDL2::MultiGestureEvent {
    FFI::C->struct( SDL_MultiGestureEvent => [
        type       => 'uint32',
        timestamp  => 'uint32',
        touchId    => 'SDL_TouchID',
        dThetha    => 'float',
        dHist      => 'float',
        x          => 'float',
        y          => 'float',
        numFingers => 'uint16',
        padding    => 'uint16',
    ]);
}

package
    TCOD::SDL2::OSEvent {
    FFI::C->struct( SDL_OSEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
    ]);
}

package
    TCOD::SDL2::QuitEvent {
    FFI::C->struct( SDL_QuitEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
    ]);
}

package
    TCOD::SDL2::SensorEvent {
    FFI::C->struct( SDL_SensorEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'sint32',
        data      => 'float[6]',
    ]);
}

package
    TCOD::SDL2::SysWMEvent {
    FFI::C->struct( SDL_SysWMEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        msg       => 'opaque', # TODO: driver dependent data
    ]);
}

package
    TCOD::SDL2::TextEditingEvent {
    FFI::C->struct( SDL_TextEditingEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        _text     => 'string(32)',
        start     => 'sint32',
        length    => 'sint32',
    ]);

    sub text { my $data = shift->_text; substr $data, 0, index $data, "\0" }
}

package
    TCOD::SDL2::TextInputEvent {
    FFI::C->struct( SDL_TextInputEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        _text     => 'string(32)',
    ]);

    sub text { my $data = shift->_text; substr $data, 0, index $data, "\0" }
}

package
    TCOD::SDL2::TouchFingerEvent {
    FFI::C->struct( SDL_TouchFingerEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        touchId   => 'SDL_TouchID',
        fingerID  => 'SDL_FingerID',
        x         => 'float',
        y         => 'float',
        dx        => 'float',
        dy        => 'float',
        pressure  => 'float',
    ]);
}

package
    TCOD::SDL2::UserEvent {
    FFI::C->struct( SDL_UserEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        code      => 'sint32',
        data1     => 'opaque',
        data2     => 'opaque',
    ]);

    sub file { $ffi->cast( opaque => string => shift->_file ) }
}

package
    TCOD::SDL2::WindowEvent {
    FFI::C->struct( SDL_WindowEvent => [
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        event     => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        data1     => 'sint32',
        data2     => 'sint32',
    ]);
}

package
    TCOD::SDL2::Event {
    FFI::C->union( SDL_Event => [
        type      => 'uint32',
        timestamp => 'uint32',

        adevice   => 'SDL_AudioDeviceEvent',
        button    => 'SDL_MouseButtonEvent',
        caxis     => 'SDL_ControllerAxisEvent',
        cbutton   => 'SDL_ControllerButtonEvent',
        cdevice   => 'SDL_ControllerDeviceEvent',
        csensor   => 'SDL_ControllerSensorEvent',
        ctouchpad => 'SDL_ControllerTouchpadEvent',
        dgesture  => 'SDL_DollarGestureEvent',
        display   => 'SDL_DisplayEvent',
        drop      => 'SDL_DropEvent',
        edit      => 'SDL_TextEditingEvent',
        jaxis     => 'SDL_JoyAxisEvent',
        jball     => 'SDL_JoyBallEvent',
        jbutton   => 'SDL_JoyButtonEvent',
        jdevide   => 'SDL_JoyDeviceEvent',
        jhat      => 'SDL_JoyHatEvent',
        key       => 'SDL_KeyboardEvent',
        mgesture  => 'SDL_MultiGestureEvent',
        motion    => 'SDL_MouseMotionEvent',
        quit      => 'SDL_QuitEvent',
        sensor    => 'SDL_SensorEvent',
        syswm     => 'SDL_SysWMEvent',
        text      => 'SDL_TextInputEvent',
        tfinger   => 'SDL_TouchFingerEvent',
        user      => 'SDL_UserEvent',
        wheel     => 'SDL_MouseWheelEvent',
        window    => 'SDL_WindowEvent',

        padding   => 'uint8[56]',
    ]);
}

$ffi->attach( GetError => [] => 'string' );

$ffi->attach( CreateRGBSurfaceWithFormatFrom => [qw( opaque int int int int uint32 )] => 'opaque' );

## Events

$ffi->attach( PollEvent              => [qw( SDL_Event                       )] => 'int'         );
$ffi->attach( WaitEvent              => [qw( opaque                       )] => 'int'         );
$ffi->attach( WaitEventTimeout       => [qw( opaque int                   )] => 'int'         );

## Init

$ffi->attach( Init          => ['uint32'] => 'int'  );
$ffi->attach( InitSubSystem => ['uint32'] => 'int'  );
$ffi->attach( Quit          => [        ] => 'void' );
$ffi->attach( QuitSubSystem => ['uint32'] => 'void' );
$ffi->attach( WasInit       => ['uint32'] => 'int'  );

1;
