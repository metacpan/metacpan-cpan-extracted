# ABSTRACT: FFI bindings for libtcod
package TCOD;

use strict;
use warnings;

use Encode ();
use FFI::C;
use FFI::CheckLib ();
use FFI::Platypus 1.00;
use FFI::Platypus::Buffer ();
use Ref::Util;
use TCOD::SDL2;
use TCOD::Event;

sub import {
    use Import::Into;
    TCOD::Event->import::into( scalar caller );
}

our $VERSION = '0.009';

my $bundle = FFI::Platypus->new( api => 1 );
$bundle->bundle('TCOD');

my $ffi;
BEGIN {
    $ffi = FFI::Platypus->new( api => 1 );
    $ffi->lib( FFI::CheckLib::find_lib_or_exit lib => 'tcod' );
    FFI::C->ffi($ffi);
}

$ffi->load_custom_type( '::WideString' => 'wstring', access => 'read' );

$ffi->attach( [ TCOD_set_error => 'set_error' ] => ['string'] => 'int'    );
$ffi->attach( [ TCOD_get_error => 'get_error' ] => [        ] => 'string' );

sub enum {
    my %enums = @_;
    while ( my ( $name, $values ) = each %enums ) {
        require constant;
        constant->import($values);

        my $variable = __PACKAGE__ . '::' . $name;
        no strict 'refs';
        %{$variable} = ( %{$variable}, reverse %$values );
    }
}

use constant {
    NOISE_MAX_OCTAVES        => 128,
    NOISE_MAX_DIMENSIONS     => 4,
    NOISE_DEFAULT_HURST      => 0.5,
    NOISE_DEFAULT_LACUNARITY => 2,

};

BEGIN {
    enum Distribution => {
        DISTRIBUTION_LINEAR                 => 0,
        DISTRIBUTION_GAUSSIAN               => 1,
        DISTRIBUTION_GAUSSIAN_RANGE         => 2,
        DISTRIBUTION_GAUSSIAN_INVERSE       => 3,
        DISTRIBUTION_GAUSSIAN_RANGE_INVERSE => 4,
    },
    Charmap => {
        CHARMAP_CP437 => [
            0x0000, 0x263A, 0x263B, 0x2665, 0x2666, 0x2663, 0x2660, 0x2022,
            0x25D8, 0x25CB, 0x25D9, 0x2642, 0x2640, 0x266A, 0x266B, 0x263C,
            0x25BA, 0x25C4, 0x2195, 0x203C, 0x00B6, 0x00A7, 0x25AC, 0x21A8,
            0x2191, 0x2193, 0x2192, 0x2190, 0x221F, 0x2194, 0x25B2, 0x25BC,
            0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
            0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
            0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
            0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
            0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047,
            0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
            0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057,
            0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
            0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
            0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
            0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
            0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x007F,
            0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7,
            0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
            0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9,
            0x00FF, 0x00D6, 0x00DC, 0x00A2, 0x00A3, 0x00A5, 0x20A7, 0x0192,
            0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA,
            0x00BF, 0x2310, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
            0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556,
            0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
            0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F,
            0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
            0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B,
            0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
            0x03B1, 0x00DF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0x00B5, 0x03C4,
            0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x03B5, 0x2229,
            0x2261, 0x00B1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00F7, 0x2248,
            0x00B0, 0x2219, 0x00B7, 0x221A, 0x207F, 0x00B2, 0x25A0, 0x00A0,
        ],
        CHARMAP_TCOD => [
            0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
            0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
            0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
            0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
            0x0040, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F, 0x0060, 0x007B,
            0x007C, 0x007D, 0x007E, 0x2591, 0x2592, 0x2593, 0x2502, 0x2500,
            0x253C, 0x2524, 0x2534, 0x251C, 0x252C, 0x2514, 0x250C, 0x2510,
            0x2518, 0x2598, 0x259D, 0x2580, 0x2596, 0x259A, 0x2590, 0x2597,
            0x2191, 0x2193, 0x2190, 0x2192, 0x25B2, 0x25BC, 0x25C4, 0x25BA,
            0x2195, 0x2194, 0x2610, 0x2611, 0x25CB, 0x25C9, 0x2551, 0x2550,
            0x256C, 0x2563, 0x2569, 0x2560, 0x2566, 0x255A, 0x2554, 0x2557,
            0x255D, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047, 0x0048,
            0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F, 0x0050,
            0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057, 0x0058,
            0x0059, 0x005A, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067, 0x0068,
            0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F, 0x0070,
            0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077, 0x0078,
            0x0079, 0x007A, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        ],
    },
    Alignment => {
        LEFT                     =>   0,
        RIGHT                    =>   1,
        CENTER                   =>   2,
    },
    Error => {
        E_OK                     =>   0,
        E_ERROR                  =>  -1,
        E_INVALID_ARGUMENT       =>  -2,
        E_OUT_OF_MEMORY          =>  -3,
        E_REQUIRES_ATTENTION     =>  -4,
        E_WARN                   =>   1,
    },
    Renderer => {
        RENDERER_GLSL            =>   0,
        RENDERER_OPENGL          =>   1,
        RENDERER_SDL             =>   2,
        RENDERER_SDL2            =>   3,
        RENDERER_OPENGL2         =>   4,
        NB_RENDERERS             =>   5,
    },
    BackgroundFlag => {
        BKGND_NONE               =>   0,
        BKGND_SET                =>   1,
        BKGND_MULTIPLY           =>   2,
        BKGND_LIGHTEN            =>   3,
        BKGND_DARKEN             =>   4,
        BKGND_SCREEN             =>   5,
        BKGND_COLOR_DODGE        =>   6,
        BKGND_COLOR_BURN         =>   7,
        BKGND_ADD                =>   8,
        BKGND_ADDA               =>   9,
        BKGND_BURN               =>  10,
        BKGND_OVERLAY            =>  11,
        BKGND_ALPH               =>  12,
        BKGND_DEFAULT            =>  13,
    },
    ColorControl => {
        COLCTRL_1                =>   1,
        COLCTRL_2                =>   2,
        COLCTRL_3                =>   3,
        COLCTRL_4                =>   4,
        COLCTRL_5                =>   5,
        COLCTRL_NUMBER           =>   5, # Repeated!
        COLCTRL_FORE_RGB         =>   6,
        COLCTRL_BACK_RGB         =>   7,
        COLCTRL_STOP             =>   8,
    },
    Keycode => {
        K_NONE                   =>   0,
        K_ESCAPE                 =>   1,
        K_BACKSPACE              =>   2,
        K_TAB                    =>   3,
        K_ENTER                  =>   4,
        K_SHIFT                  =>   5,
        K_CONTROL                =>   6,
        K_ALT                    =>   7,
        K_PAUSE                  =>   8,
        K_CAPSLOCK               =>   9,
        K_PAGEUP                 =>  10,
        K_PAGEDOWN               =>  11,
        K_END                    =>  12,
        K_HOME                   =>  13,
        K_UP                     =>  14,
        K_LEFT                   =>  15,
        K_RIGHT                  =>  16,
        K_DOWN                   =>  17,
        K_PRINTSCREEN            =>  18,
        K_INSERT                 =>  19,
        K_DELETE                 =>  20,
        K_LWIN                   =>  21,
        K_RWIN                   =>  22,
        K_APPS                   =>  23,
        K_0                      =>  24,
        K_1                      =>  25,
        K_2                      =>  26,
        K_3                      =>  27,
        K_4                      =>  28,
        K_5                      =>  29,
        K_6                      =>  30,
        K_7                      =>  31,
        K_8                      =>  32,
        K_9                      =>  33,
        K_KP0                    =>  34,
        K_KP1                    =>  35,
        K_KP2                    =>  36,
        K_KP3                    =>  37,
        K_KP4                    =>  38,
        K_KP5                    =>  39,
        K_KP6                    =>  40,
        K_KP7                    =>  41,
        K_KP8                    =>  42,
        K_KP9                    =>  43,
        K_KPADD                  =>  44,
        K_KPSUB                  =>  45,
        K_KPDIV                  =>  46,
        K_KPMUL                  =>  47,
        K_KPDEC                  =>  48,
        K_KPENTER                =>  49,
        K_F1                     =>  50,
        K_F2                     =>  51,
        K_F3                     =>  52,
        K_F4                     =>  53,
        K_F5                     =>  54,
        K_F6                     =>  55,
        K_F7                     =>  56,
        K_F8                     =>  57,
        K_F9                     =>  58,
        K_F10                    =>  59,
        K_F11                    =>  60,
        K_F12                    =>  61,
        K_NUMLOCK                =>  62,
        K_SCROLLLOCK             =>  63,
        K_SPACE                  =>  64,
        K_CHAR                   =>  65,
        K_TEXT                   =>  66,
    },
    Char => {
        CHAR_HLINE               => 196,
        CHAR_VLINE               => 179,
        CHAR_NE                  => 191,
        CHAR_NW                  => 218,
        CHAR_SE                  => 217,
        CHAR_SW                  => 192,
        CHAR_TEEW                => 180,
        CHAR_TEEE                => 195,
        CHAR_TEEN                => 193,
        CHAR_TEES                => 194,
        CHAR_CROSS               => 197,
        # double walls
        CHAR_DHLINE              => 205,
        CHAR_DVLINE              => 186,
        CHAR_DNE                 => 187,
        CHAR_DNW                 => 201,
        CHAR_DSE                 => 188,
        CHAR_DSW                 => 200,
        CHAR_DTEEW               => 185,
        CHAR_DTEEE               => 204,
        CHAR_DTEEN               => 202,
        CHAR_DTEES               => 203,
        CHAR_DCROSS              => 206,
        # blocks
        CHAR_BLOCK1              => 176,
        CHAR_BLOCK2              => 177,
        CHAR_BLOCK3              => 178,
        # arrows
        CHAR_ARROW_N             =>  24,
        CHAR_ARROW_S             =>  25,
        CHAR_ARROW_E             =>  26,
        CHAR_ARROW_W             =>  27,
        # arrows without tail
        CHAR_ARROW2_N            =>  30,
        CHAR_ARROW2_S            =>  31,
        CHAR_ARROW2_E            =>  16,
        CHAR_ARROW2_W            =>  17,
        # double arrows
        CHAR_DARROW_H            =>  29,
        CHAR_DARROW_V            =>  18,
        # GUI stuff
        CHAR_CHECKBOX_UNSET      => 224,
        CHAR_CHECKBOX_SET        => 225,
        CHAR_RADIO_UNSET         =>   9,
        CHAR_RADIO_SET           =>  10,
        # sub-pixel resoluti     on kit
        CHAR_SUBP_NW             => 226,
        CHAR_SUBP_NE             => 227,
        CHAR_SUBP_N              => 228,
        CHAR_SUBP_SE             => 229,
        CHAR_SUBP_DIAG           => 230,
        CHAR_SUBP_E              => 231,
        CHAR_SUBP_SW             => 232,
        # miscellaneous
        CHAR_SMILIE              =>   1,
        CHAR_SMILIE_INV          =>   2,
        CHAR_HEART               =>   3,
        CHAR_DIAMOND             =>   4,
        CHAR_CLUB                =>   5,
        CHAR_SPADE               =>   6,
        CHAR_BULLET              =>   7,
        CHAR_BULLET_INV          =>   8,
        CHAR_MALE                =>  11,
        CHAR_FEMALE              =>  12,
        CHAR_NOTE                =>  13,
        CHAR_NOTE_DOUBLE         =>  14,
        CHAR_LIGHT               =>  15,
        CHAR_EXCLAM_DOUBLE       =>  19,
        CHAR_PILCROW             =>  20,
        CHAR_SECTION             =>  21,
        CHAR_POUND               => 156,
        CHAR_MULTIPLICATION      => 158,
        CHAR_FUNCTION            => 159,
        CHAR_RESERVED            => 169,
        CHAR_HALF                => 171,
        CHAR_ONE_QUARTER         => 172,
        CHAR_COPYRIGHT           => 184,
        CHAR_CENT                => 189,
        CHAR_YEN                 => 190,
        CHAR_CURRENCY            => 207,
        CHAR_THREE_QUARTERS      => 243,
        CHAR_DIVISION            => 246,
        CHAR_GRADE               => 248,
        CHAR_UMLAUT              => 249,
        CHAR_POW1                => 251,
        CHAR_POW3                => 252,
        CHAR_POW2                => 253,
        CHAR_BULLET_SQUARE       => 254,
    },
    FontFlag => {
        FONT_LAYOUT_ASCII_INCOL  =>   1,
        FONT_LAYOUT_ASCII_INROW  =>   2,
        FONT_TYPE_GREYSCALE      =>   4,
        FONT_TYPE_GRAYSCALE      =>   4,
        FONT_LAYOUT_TCOD         =>   8,
        FONT_LAYOUT_CP437        =>  16,
    },
    FOV => {
        FOV_BASIC                =>   0,
        FOV_DIAMOND              =>   1,
        FOV_SHADOW               =>   2,
        FOV_PERMISSIVE_0         =>   3,
        FOV_PERMISSIVE_1         =>   4,
        FOV_PERMISSIVE_2         =>   5,
        FOV_PERMISSIVE_3         =>   6,
        FOV_PERMISSIVE_4         =>   7,
        FOV_PERMISSIVE_5         =>   8,
        FOV_PERMISSIVE_6         =>   9,
        FOV_PERMISSIVE_7         =>  10,
        FOV_PERMISSIVE_8         =>  11,
        FOV_RESTRICTIVE          =>  12,
        FOV_SYMMETRIC_SHADOWCAST =>  13,
        NB_FOV_ALGORITHMS        =>  14,
    },
    RandomAlgo => {
        RNG_MT                   =>   0,
        RNG_CMWC                 =>   1,
    },
    NoiseType => {
        NOISE_PERLIN             =>   1,
        NOISE_SIMPLEX            =>   2,
        NOISE_WAVELET            =>   4,
        NOISE_DEFAULT            =>   0,
    },
    Event => {
        EVENT_NONE               =>   0,
        EVENT_KEY_PRESS          =>   1,
        EVENT_KEY_RELEASE        =>   2,
        EVENT_MOUSE_MOVE         =>   4,
        EVENT_MOUSE_PRESS        =>   8,
        EVENT_MOUSE_RELEASE      =>  16,
        # Continued below
    },
}

BEGIN {
    enum Event => {
        # Continued above and below
        EVENT_KEY     => EVENT_KEY_PRESS  | EVENT_KEY_RELEASE,
        EVENT_MOUSE   => EVENT_MOUSE_MOVE | EVENT_MOUSE_PRESS | EVENT_MOUSE_RELEASE,
    },
}

BEGIN {
    enum Event => {
        EVENT_ANY     => EVENT_KEY | EVENT_MOUSE,
    },
}

$ffi->type( int    => 'TCOD_renderer' );
$ffi->type( int    => 'TCOD_keycode'  );
$ffi->type( int    => 'TCOD_error'    );
$ffi->type( opaque => 'TCOD_event'    );
$ffi->type( '(int, int, int, int, opaque )->float' => 'TCOD_path_func'     );
$ffi->type( '(int,int)->bool'                      => 'TCOD_line_listener' );

# Custom blessed opaque types
for my $name (qw( image console map path dijkstra random noise context )) {
    my $type = {
        native_type    => 'opaque',
        perl_to_native => sub { $_[0] ? ${ $_[0] } : undef },
        native_to_perl => sub {
            return unless $_[0];
            bless \$_[0], 'TCOD::' . ucfirst $name;
        },
    };

    $ffi->custom_type( "TCOD_$name" => $type );
    $bundle->custom_type( "TCOD_$name" => $type );
}

package TCOD::Key {
    use FFI::Platypus::Record;
    record_layout_1(
        int          => 'vk',
        'string(1)'  => 'c',
        'string(32)' => 'text',
        bool         => 'pressed',
        bool         => 'lalt',
        bool         => 'lctrl',
        bool         => 'lmeta',
        bool         => 'ralt',
        bool         => 'rctrl',
        bool         => 'rmeta',
        bool         => 'shift',
    );
    $ffi->type( 'record(TCOD::Key)'  => 'TCOD_key'  );
}

package TCOD::Mouse {
    use FFI::Platypus::Record;
    record_layout_1(
        int  => 'x',
        int  => 'y',
        int  => 'dx',
        int  => 'dy',
        int  => 'cx',
        int  => 'cy',
        int  => 'dcx',
        int  => 'dcy',
        bool => 'lbutton',
        bool => 'rbutton',
        bool => 'mbutton',
        bool => 'lbutton_pressed',
        bool => 'rbutton_pressed',
        bool => 'mbutton_pressed',
        bool => 'wheel_up',
        bool => 'wheel_down',
    );
    $ffi->type( 'record(TCOD::Mouse)'  => 'TCOD_mouse'  );

    $ffi->mangler( sub { 'TCOD_mouse_' . shift } );

    $ffi->attach( is_cursor_visible => [             ] => 'bool' );
    $ffi->attach( move              => [qw( int int )] => 'void' );
    $ffi->attach( show_cursor       => [qw( bool    )] => 'void' );
}

package TCOD::Color {
    use Carp ();
    use Scalar::Util ();

    use overload fallback => 1,
        '+' => sub {
            my ( $self, $other, $swap ) = @_;
            Carp::croak 'TCOD::Color addition only supports colors'
                unless Scalar::Util::blessed $other && $other->isa('TCOD::Color');
            $self->add($other);
        },
        '-' => sub {
            my ( $self, $other, $swap ) = @_;
            Carp::croak 'TCOD::Color subtraction only supports colors'
                unless Scalar::Util::blessed $other && $other->isa('TCOD::Color');
            $self->subtract($other);
        },
        '*' => sub {
            my ( $self, $other, $swap ) = @_;
            return $self->multiply_scalar($other) unless ref $other;
            Carp::croak 'TCOD::Color multiplication supports colors or scalars'
                unless Scalar::Util::blessed $other && $other->isa('TCOD::Color');
            $self->multiply($other);
        },
        '""' => sub {
            my $self = shift;
            sprintf '#%02x%02x%02x', $self->r, $self->g, $self->b;
        },
        '!=' => sub { !shift->equals(shift) },
        '==' => sub {
            my ( $self, $other, $swap ) = @_;
            Carp::croak 'TCOD::Color equality only supports colors'
                unless Scalar::Util::blessed $other && $other->isa('TCOD::Color');
            $self->equals($other);
        };

    $ffi->mangler( sub { 'TCOD_color_' . shift } );

    use FFI::Platypus::Record;
    record_layout_1( uint8 => 'r', uint8 => 'g', uint8 => 'b' );
    $ffi->type(    'record(TCOD::Color)'  => 'TCOD_color'  );
    $bundle->type( 'record(TCOD::Color)'  => 'TCOD_color'  );

    {
        # Give color a positional constructor
        no strict 'refs';
        no warnings 'redefine';

        my $old  = __PACKAGE__->can('new') or die;
        my $name = __PACKAGE__ . '::new';

        require Sub::Util;
        *{$name} = Sub::Util::set_subname $name => sub {
            my $class = shift;
            $class->$old({ r => shift, g => shift, b => shift });
        };
    }

    $ffi->attach( equals          => [qw( TCOD_color TCOD_color            )] => 'bool'       );
    $ffi->attach( add             => [qw( TCOD_color TCOD_color            )] => 'TCOD_color' );
    $ffi->attach( subtract        => [qw( TCOD_color TCOD_color            )] => 'TCOD_color' );
    $ffi->attach( multiply        => [qw( TCOD_color TCOD_color            )] => 'TCOD_color' );
    $ffi->attach( multiply_scalar => [qw( TCOD_color float                 )] => 'TCOD_color' );

    $ffi->attach( lerp            => [qw( TCOD_color TCOD_color float      )] => 'TCOD_color' );

    $ffi->attach( get_hue         => [qw( TCOD_color                       )] => 'float'      );
    $ffi->attach( set_hue         => [qw( TCOD_color* float                )] => 'void'       );

    $ffi->attach( get_saturation  => [qw( TCOD_color                       )] => 'float'      );
    $ffi->attach( set_saturation  => [qw( TCOD_color* float                )] => 'void'       );

    $ffi->attach( get_value       => [qw( TCOD_color                       )] => 'float'      );
    $ffi->attach( set_value       => [qw( TCOD_color* float                )] => 'void'       );

    $ffi->attach( shift_hue       => [qw( TCOD_color* float                )] => 'void'       );
    $ffi->attach( scale_HSV       => [qw( TCOD_color* float float          )] => 'void'       );

    $ffi->attach( set_HSV         => [qw( TCOD_color* float  float  float  )] => 'void'       );
    $ffi->attach( get_HSV         => [qw( TCOD_color  float* float* float* )] => 'void' => sub {
        $_[0]->( $_[1], \my $h, \my $s, \my $v );
        return ( $h, $s, $v );
    });

    sub gen_map {
        shift if @_ % 2; # Discard first arg if called like $color->gen_map( %map )
        my ( $this, @rest ) = List::Util::pairs @_;

        my @map;
        for my $next (@rest) {
            my ( $start, $end ) = ( $this->[1], $next->[1] );

            for my $i ( $start .. $end ) {
                $map[$i] = $this->[0]->lerp( $next->[0], ( $i - $start ) / ( $end - $start ) );
            }

            $this = $next;
        }

        @map;
    }
}

package TCOD::ColorRGBA {
    use FFI::Platypus::Record;
    record_layout_1( uint8 => 'r', uint8 => 'g', uint8 => 'b', uint8 => 'a' );
       $ffi->type( 'record(TCOD::ColorRGBA)' => 'TCOD_colorRGBA' );
    $bundle->type( 'record(TCOD::ColorRGBA)' => 'TCOD_colorRGBA' );

    {
        # Give color a positional constructor
        no strict 'refs';
        no warnings 'redefine';

        my $old  = __PACKAGE__->can('new') or die;
        my $name = __PACKAGE__ . '::new';

        require Sub::Util;
        *{$name} = Sub::Util::set_subname $name => sub {
            my $class = shift;
            $class->$old({ r => shift, g => shift, b => shift, a => shift });
        };
    }
}

package TCOD::Map {
    $ffi->mangler( sub { 'TCOD_map_' . shift } );

    $ffi->attach( new            => [qw(          int int              )] => 'TCOD_map' => sub { $_[0]->( @_[ 2 .. $#_ ] ) } );
    $ffi->attach( set_properties => [qw( TCOD_map int int bool bool    )] => 'void' );
    $ffi->attach( clear          => [qw( TCOD_map         bool bool    )] => 'void' );
    $ffi->attach( copy           => [qw( TCOD_map TCOD_map             )] => 'void' );

    $ffi->attach( compute_fov    => [qw( TCOD_map int int int bool int )] => 'void' );
    $ffi->attach( is_in_fov      => [qw( TCOD_map int int              )] => 'bool' );
    $ffi->attach( is_transparent => [qw( TCOD_map int int              )] => 'bool' );
    $ffi->attach( is_walkable    => [qw( TCOD_map int int              )] => 'bool' );

    $ffi->attach( get_width      => [qw( TCOD_map                      )] => 'int'  );
    $ffi->attach( get_height     => [qw( TCOD_map                      )] => 'int'  );
}

package TCOD::Console {
    $ffi->mangler(    sub { 'TCOD_console_' . shift } );
    $bundle->mangler( sub { 'PERL_console_' . shift } );

    $ffi->attach( [ delete => 'DESTROY' ] => [qw( TCOD_console )] => 'void' );

    # Constructors
    $ffi->attach( new       => [qw( int int )] => 'TCOD_console' => sub { $_[0]->( @_[ 2 .. $#_ ] ) } );
    $ffi->attach( from_file => [qw( string  )] => 'TCOD_console' => sub { $_[0]->( $_[ 2 ] ) } );
    $ffi->attach( load_asc  => [qw( string  )] => 'TCOD_console' => sub { $_[0]->( $_[ 2 ] ) } );
    $ffi->attach( load_apf  => [qw( string  )] => 'TCOD_console' => sub { $_[0]->( $_[ 2 ] ) } );

    # Printing methods

    my $blit_with_key_color = $ffi->function( blit_key_color => [qw(
        TCOD_console int int int int
        TCOD_console int int
        float float
        TCOD_color
    )]);

    $ffi->attach( blit => [qw(
        TCOD_console int int int int
        TCOD_console int int
        float float
    )] => void => sub {
        my ( $xsub, $console, %args ) = @_;

        my @args = (
            $console,
            $args{src_x}    // 0,
            $args{src_y}    // 0,
            $args{width}    // 0,
            $args{height}   // 0,
            $args{dest},
            $args{dest_x}   // 0,
            $args{dest_y}   // 0,
            $args{fg_alpha} // $args{alpha} // 1,
            $args{bg_alpha} // $args{alpha} // 1,
        );

        return $blit_with_key_color->( @args, $args{key_color} ) if $args{key_color};

        $xsub->(@args);
    });

    $ffi->attach( [ printn => 'print' ] => [qw(
        TCOD_console
        int
        int
        size_t
        string
        TCOD_color*
        TCOD_color*
        int
        int
    )] => TCOD_error => sub {
        my ( $xsub, $console, %args ) = ( shift, shift );

        # Accommodate $con->print( $x, $y, $string, %rest );
        %args = ( x => shift, y => shift, string => shift ) if @_ % 2;
        %args = ( %args, @_ );

        my $string = Encode::encode( 'UTF-8', $args{string}, Encode::FB_CROAK );

        $xsub->(
            $console,  @args{qw( x y )},
            length($string), $string,
            @args{qw( fg bg )},
            $args{bg_blend}  // TCOD::BKGND_SET,
            $args{alignment} // TCOD::LEFT,
        );
    });

    $ffi->attach( [ printn_rect => 'print_box' ] => [qw(
        TCOD_console
        int
        int
        int
        int
        size_t
        string
        TCOD_color*
        TCOD_color*
        int
        int
    )] => TCOD_error => sub {
        my ( $xsub, $console, %args ) = @_;
        my $string = Encode::encode( 'UTF-8', $args{string}, Encode::FB_CROAK );

        $xsub->(
            $console, @args{qw( x y width height )},
            length($string), $string,
            @args{qw( fg bg )},
            $args{bg_blend}  // TCOD::BKGND_SET,
            $args{alignment} // TCOD::LEFT,
        );
    });

    $ffi->attach( [ draw_frame_rgb => 'draw_frame' ] => [qw(
        TCOD_console
        int
        int
        int
        int
        int[]
        TCOD_color*
        TCOD_color*
        int
        bool
    )] => TCOD_error => sub {
        my ( $xsub, $console, %args ) = @_;

        Carp::croak 'The title parameter is not supported' if exists $args{title};

        my $decoration = $args{decoration} // [ '┌', '─', '┐', '│', ' ', '│', '└', '─', '┘' ];

        $decoration = [ map ord, split //, $decoration ]
            unless Ref::Util::is_arrayref $decoration;

        Carp::croak 'Frame decoration must have a length of 9. It has a length of ' . @$decoration
            if @$decoration != 9;

        $xsub->(
            $console, @args{qw( x y width height )},
            $decoration,
            @args{qw( fg bg )},
            $args{bg_blend}  // TCOD::BKGND_SET,
            $args{clear}     // 1,
        );
    });

    $ffi->attach( [ draw_rect_rgb => 'draw_rect' ] => [qw(
        TCOD_console
        int
        int
        int
        int
        int
        TCOD_color*
        TCOD_color*
        int
        bool
    )] => TCOD_error => sub {
        my ( $xsub, $console, %args ) = @_;

        $xsub->(
            $console,
            @args{qw( x y width height ch fg bg )},
            $args{bg_blend}  // TCOD::BKGND_SET,
        );
    });

    # Methods

    my $clear = $bundle->function( clear => [qw( TCOD_console TCOD_color* TCOD_color* int )] );
    $ffi->attach( clear => [qw( TCOD_console )] => 'void' => sub {
        my ( $xsub, $console, %args ) = @_;

        return $xsub->($console) unless %args;

        $clear->( $console, $args{fg}, $args{bg}, $args{ch} // TCOD::Event::K_SPACE );
    });

    $ffi->attach( save_asc                => [qw( TCOD_console string                            )] => 'bool'       );
    $ffi->attach( save_apf                => [qw( TCOD_console string                            )] => 'bool'       );

    $ffi->attach( set_char                => [qw( TCOD_console int int int                       )] => 'void'       );
    $ffi->attach( get_char                => [qw( TCOD_console int int                           )] => 'int'        );
    $ffi->attach( put_char                => [qw( TCOD_console int int int int                   )] => 'void'       );
    $ffi->attach( put_char_ex             => [qw( TCOD_console int int int TCOD_color TCOD_color )] => 'void'       );

    $ffi->attach( get_width               => [qw( TCOD_console                                   )] => 'int'        );
    $ffi->attach( get_height              => [qw( TCOD_console                                   )] => 'int'        );

    $ffi->attach( set_background_flag     => [qw( TCOD_console int                               )] => 'void'       );
    $ffi->attach( get_background_flag     => [qw( TCOD_console                                   )] => 'int'        );

    $ffi->attach( set_alignment           => [qw( TCOD_console int                               )] => 'void'       );
    $ffi->attach( get_alignment           => [qw( TCOD_console                                   )] => 'int'        );

    $ffi->attach( set_char_background     => [qw( TCOD_console int int TCOD_color int            )] => 'void'       );
    $ffi->attach( get_char_background     => [qw( TCOD_console int int                           )] => 'TCOD_color' );

    $ffi->attach( set_char_foreground     => [qw( TCOD_console int int TCOD_color                )] => 'void'       );
    $ffi->attach( get_char_foreground     => [qw( TCOD_console int int                           )] => 'TCOD_color' );

    $ffi->attach( set_default_background  => [qw( TCOD_console TCOD_color                        )] => 'void'       );
    $ffi->attach( get_default_background  => [qw( TCOD_console                                   )] => 'TCOD_color' );

    $ffi->attach( set_default_foreground  => [qw( TCOD_console TCOD_color                        )] => 'void'       );
    $ffi->attach( get_default_foreground  => [qw( TCOD_console                                   )] => 'TCOD_color' );

    # Root console functions
    $ffi->attach( init_root               => [qw( int int string int bool )] => 'void' );
    $ffi->attach( set_custom_font         => [qw( string int int int      )] => 'void' );
    $ffi->attach( map_ascii_code_to_font  => [qw( int int int             )] => 'void' );
    $ffi->attach( map_ascii_codes_to_font => [qw( int int int int         )] => 'void' );
    $ffi->attach( map_string_to_font      => [qw( string int int          )] => 'void' );
    $ffi->attach( is_fullscreen           => [                             ] => 'bool' );
    $ffi->attach( set_fullscreen          => [qw( bool                    )] => 'void' );
    $ffi->attach( set_window_title        => [qw( string                  )] => 'void' );
    $ffi->attach( is_window_closed        => [                             ] => 'bool' );
    $ffi->attach( has_mouse_focus         => [                             ] => 'bool' );
    $ffi->attach( is_active               => [                             ] => 'bool' );
    $ffi->attach( credits                 => [                             ] => 'void' );
    $ffi->attach( credits_render          => [qw( int int bool            )] => 'bool' );
    $ffi->attach( credits_reset           => [                             ] => 'void' );
    $ffi->attach( flush                   => [                             ] => 'void' );
    $ffi->attach( set_fade                => [qw( uint8 TCOD_color        )] => 'void' );
    $ffi->attach( get_fade                => [                             ] => 'uint8' );
    $ffi->attach( get_fading_color        => [                             ] => 'TCOD_color' );

    $ffi->attach( set_color_control => [qw( int TCOD_color TCOD_color )] => 'void' );

    $ffi->attach( wait_for_keypress  => ['bool'] => 'TCOD_key' );
    $ffi->attach( check_for_keypress => ['int' ] => 'TCOD_key' );
    $ffi->attach( is_key_pressed     => ['int' ] => 'bool'     );
}

package TCOD::Sys {
    $ffi->mangler( sub { 'TCOD_sys_' . shift } );

    $ffi->attach( wait_for_event         => [qw( int TCOD_key* TCOD_mouse* bool )] => 'TCOD_event'    );
    $ffi->attach( check_for_event        => [qw( int TCOD_key* TCOD_mouse*      )] => 'TCOD_event'    );

    $ffi->attach( save_screenshot        => [qw( string                         )] => 'void'          );
    $ffi->attach( set_fps                => [qw( int                            )] => 'void'          );
    $ffi->attach( get_fps                => [                                    ] => 'int'           );
    $ffi->attach( sleep_milli            => [qw( uint32                         )] => 'void'          );
    $ffi->attach( elapsed_milli          => [                                    ] => 'uint32'        );
    $ffi->attach( elapsed_seconds        => [                                    ] => 'float'         );
    $ffi->attach( get_last_frame_length  => [                                    ] => 'float'         );
    $ffi->attach( update_char            => [qw( int int int TCOD_image int int )] => 'void'          );
    $ffi->attach( set_renderer           => [qw( TCOD_renderer                  )] => 'void'          );
    $ffi->attach( get_renderer           => [                                    ] => 'TCOD_renderer' );

    # Deprecated
  # $ffi->attach( create_directory       => [qw( string                         )] => 'bool'          );
  # $ffi->attach( delete_directory       => [qw( string                         )] => 'bool'          );
  # $ffi->attach( delete_file            => [qw( string                         )] => 'bool'          );
  # $ffi->attach( is_directory           => [qw( string                         )] => 'bool'          );
  # $ffi->attach( file_exists            => [qw( string                         )] => 'bool'          );
  # $ffi->attach( clipboard_set          => [qw( string                         )] => 'bool'          );
  # $ffi->attach( clipboard_get          => [                                    ] => 'string'        );

    $ffi->attach( get_char_size          => [qw( int* int* )] => 'void' => sub { $_[0]->( \my $w, \my $h ); ( $w, $h ) });
    $ffi->attach( get_current_resolution => [qw( int* int* )] => 'void' => sub { $_[0]->( \my $w, \my $h ); ( $w, $h ) });
  # $ffi->attach( get_fullscreen_offset  => [qw( int* int* )] => 'void' => sub { $_[0]->( \my $x, \my $y ); ( $x, $y ) });

    $ffi->attach( register_SDL_renderer  => [qw( (opaque)->void                 )] => 'void'          );
  # $ffi->attach( set_dirty              => [qw( int int int int                )] => 'void'          );

    $ffi->attach( force_fullscreen_resolution => [qw( int int )] => 'void' );
}

package TCOD::Path {
    $ffi->mangler( sub { 'TCOD_path_' . shift } );

    my $new = sub {
        my $sub = shift;
        my $class = ref $_[0] || $_[0];
        shift if $class eq __PACKAGE__;
        $sub->(@_);
    };

    # Constructors
    $ffi->attach( new_using_map      => [qw(         TCOD_map              float )] => 'TCOD_path' => $new );
    $ffi->attach( new_using_function => [qw( int int TCOD_path_func opaque float )] => 'TCOD_path' => $new );

    $ffi->attach( compute  => [qw( TCOD_path int int int int )] => 'bool' );
    $ffi->attach( reverse  => [qw( TCOD_path                 )] => 'void' );
    $ffi->attach( is_empty => [qw( TCOD_path                 )] => 'bool' );
    $ffi->attach( size     => [qw( TCOD_path                 )] => 'int'  );

    $ffi->attach( get_origin => [qw( TCOD_path int* int* )] => 'void' => sub {
        $_[0]->( $_[1], \my $x, \my $y );
        return ( $x, $y );
    });

    $ffi->attach( get_destination => [qw( TCOD_path int* int* )] => 'void' => sub {
        $_[0]->( $_[1], \my $x, \my $y );
        return ( $x, $y );
    });

    $ffi->attach( get => [qw( TCOD_path int int* int* )] => 'void' => sub {
        $_[0]->( @_[ 1, 2 ], \my $x, \my $y );
        return ( $x, $y );
    });

    $ffi->attach( walk => [qw( TCOD_path int* int* bool )] => 'bool' => sub {
        $_[0]->( $_[1], \my $x, \my $y, $_[2] ) or return;
        return ( $x, $y );
    });

    $ffi->mangler( sub { shift } );
    $ffi->attach( [ TCOD_path_delete => 'DESTROY' ] => ['TCOD_path'] => 'void' );
}

package TCOD::Dijkstra {
    $ffi->mangler( sub { 'TCOD_dijkstra_' . shift } );

    my $new = sub {
        my $sub = shift;
        my $class = ref $_[0] || $_[0];
        shift if $class eq __PACKAGE__;
        $sub->(@_);
    };

    # Constructors
    $ffi->attach( new                => [qw(         TCOD_map              float )] => 'TCOD_dijkstra' => $new );
    $ffi->attach( new_using_function => [qw( int int TCOD_path_func opaque float )] => 'TCOD_dijkstra' => $new );

    $ffi->attach( compute      => [qw( TCOD_dijkstra int int )] => 'void'  );
    $ffi->attach( path_set     => [qw( TCOD_dijkstra int int )] => 'bool'  );
    $ffi->attach( reverse      => [qw( TCOD_dijkstra         )] => 'void'  );
    $ffi->attach( is_empty     => [qw( TCOD_dijkstra         )] => 'bool'  );
    $ffi->attach( size         => [qw( TCOD_dijkstra         )] => 'int'   );
    $ffi->attach( get_distance => [qw( TCOD_dijkstra int int )] => 'float' );

    $ffi->attach( get => [qw( TCOD_dijkstra int int* int* )] => 'void' => sub {
        $_[0]->( @_[ 1, 2 ], \my $x, \my $y );
        return ( $x, $y );
    });

    $ffi->attach( [ path_walk => 'walk' ] => [qw( TCOD_dijkstra int* int* )] => 'bool' => sub {
        $_[0]->( $_[1], \my $x, \my $y, $_[2] ) or return;
        return ( $x, $y );
    });

    $ffi->mangler( sub { shift } );
    $ffi->attach( [ TCOD_dijkstra_delete => 'DESTROY' ] => ['TCOD_dijkstra'] => 'void' );
}

package TCOD::Image {
    $ffi->mangler( sub { 'TCOD_image_' . shift } );

    $ffi->attach( new          => [qw( int int      )] => 'TCOD_image' => sub { $_[0]->( @_[ 2 .. $#_ ] ) } );
    $ffi->attach( load         => [qw( string       )] => 'TCOD_image' );
    $ffi->attach( from_console => [qw( TCOD_console )] => 'TCOD_image' );

    $ffi->attach( save                 => [qw( TCOD_image string                   )] => 'void'       );
    $ffi->attach( refresh_console      => [qw( TCOD_image TCOD_console             )] => 'void'       );
    $ffi->attach( put_pixel            => [qw( TCOD_image int int TCOD_color       )] => 'void'       );
    $ffi->attach( scale                => [qw( TCOD_image int int                  )] => 'void'       );
    $ffi->attach( get_pixel            => [qw( TCOD_image int int                  )] => 'TCOD_color' );
    $ffi->attach( get_alpha            => [qw( TCOD_image int int                  )] => 'int'        );
  # $ffi->attach( pixel_is_transparent => [qw( TCOD_image int int                  )] => 'bool'       );
    $ffi->attach( get_mipmap_pixel     => [qw( TCOD_image float float float float  )] => 'TCOD_color' );
    $ffi->attach( rotate90             => [qw( TCOD_image int                      )] => 'void'       );
    $ffi->attach( invert               => [qw( TCOD_image                          )] => 'void'       );
    $ffi->attach( vflip                => [qw( TCOD_image                          )] => 'void'       );
    $ffi->attach( hflip                => [qw( TCOD_image                          )] => 'void'       );
    $ffi->attach( clear                => [qw( TCOD_image TCOD_color               )] => 'void'       );
    $ffi->attach( set_key_color        => [qw( TCOD_image TCOD_color               )] => 'void'       );

    $ffi->attach( blit      => [qw( TCOD_image TCOD_console int int int float float float )] => 'void' );
    $ffi->attach( blit_2x   => [qw( TCOD_image TCOD_console int int int int   int   int   )] => 'void' );
    $ffi->attach( blit_rect => [qw( TCOD_image TCOD_console int int int int   int         )] => 'void' );

    $ffi->attach( get_size => [qw( TCOD_image int* int* )] => 'void' => sub {
        $_[0]->( @_[ 1, 2 ], \my $w, \my $h );
        return ( $w, $h );
    });
}

package TCOD::Random {
    my $instance;

    $ffi->mangler( sub { 'TCOD_random_' . shift } );

    $ffi->attach( new           => [qw( int     )] => 'TCOD_random' => sub { $_[0]->( @_[ 2 .. $#$_ ]  ) } );
    $ffi->attach( new_from_seed => [qw( int int )] => 'TCOD_random' => sub { $_[0]->( @_[ 2 .. $#$_ ]  ) } );
    $ffi->attach( get_instance  => [             ] => 'TCOD_random' => sub {
        $instance //= $_[0]->(); # Prevent the global RNG from being destroyed
    });

    $ffi->attach( save             => [qw( TCOD_random                      )] => 'TCOD_random' );
    $ffi->attach( restore          => [qw( TCOD_random TCOD_random          )] => 'void'        );
    $ffi->attach( set_distribution => [qw( TCOD_random int                  )] => 'void'        );
    $ffi->attach( get_int          => [qw( TCOD_random int    int           )] => 'int'         );
    $ffi->attach( get_int_mean     => [qw( TCOD_random int    int    int    )] => 'int'         );
    $ffi->attach( get_float        => [qw( TCOD_random float  float         )] => 'float'       );
    $ffi->attach( get_float_mean   => [qw( TCOD_random float  float  float  )] => 'float'       );
    $ffi->attach( get_double       => [qw( TCOD_random double double        )] => 'double'      );
    $ffi->attach( get_double_mean  => [qw( TCOD_random double double double )] => 'double'      );

    $ffi->mangler( sub { shift } );
    $ffi->attach( [ TCOD_random_delete => 'DESTROY' ] => ['TCOD_random'] => 'void' );
}

package TCOD::Noise {
    $ffi->mangler( sub { 'TCOD_noise_' . shift } );

    $ffi->attach( new          => [qw( int float float TCOD_random )] => 'TCOD_noise' => sub { $_[0]->( @_[ 2 .. $#_ ] ) } );

    $ffi->attach( set_type          => [qw( TCOD_noise int               )] => 'void' );
    $ffi->attach( get               => [qw( TCOD_noise float[]           )] => 'float' );
    $ffi->attach( get_ex            => [qw( TCOD_noise float[]       int )] => 'float' );
    $ffi->attach( get_fbm           => [qw( TCOD_noise float[] float     )] => 'float' );
    $ffi->attach( get_fbm_ex        => [qw( TCOD_noise float[] float int )] => 'float' );
    $ffi->attach( get_turbulence    => [qw( TCOD_noise float[] float     )] => 'float' );
    $ffi->attach( get_turbulence_ex => [qw( TCOD_noise float[] float int )] => 'float' );

    $ffi->mangler( sub { shift } );
    $ffi->attach( [ TCOD_noise_delete => 'DESTROY' ] => ['TCOD_noise'] => 'void' );
}

package TCOD::Tileset {
    $ffi->mangler( sub { shift } );

    FFI::C->struct( TCOD_tileset => [
        tile_width           => 'int',
        tile_height          => 'int',
        tile_length          => 'int',
        tiles_capacity       => 'int',
        tiles_count          => 'int',
        pixels               => 'opaque', # TCOD_ColorRGBA*
        character_map_length => 'int',
        character_map        => 'opaque',
        observer_list        => 'opaque', # TCOD_TilesetObserver
        virtual_columns      => 'int',
        ref_count            => 'int',
    ]);

    sub tile_shape {
        my $self = shift;
        ( $self->tile_width, $self->tile_height );
    }

    $ffi->attach( [ TCOD_load_bdf => 'load_bdf' ] => [qw( string )] => 'TCOD_tileset' => sub {
        my ( $xsub, $self, $path ) = @_;

        Carp::croak "Cannot load tilesheet from $path: no such file"
            unless -f $path;

        $xsub->( $self, $path );
    });

    $ffi->attach( [ TCOD_tileset_load => 'load_tilesheet' ] => [qw( string int int int int[] )] => 'TCOD_tileset' => sub {
        my ( $xsub, undef, %args ) = ( shift, shift );

        %args = @_ != 4 ? @_ : (
            path    => shift,
            columns => shift,
            rows    => shift,
            charmap => shift,
        );

        Carp::croak "Cannot load tilesheet from $args{path}: no such file"
            unless -f $args{path};

        $xsub->(
            @args{qw( path columns rows )},
            scalar @{ $args{charmap} }, $args{charmap},
        );
    });

    $ffi->attach( [ TCOD_tileset_get_tile_ => 'get_tile' ] => [qw( TCOD_tileset int )] => 'int' => sub {
        $_[0]->( $_[1], $_[2], my $color = TCOD::ColorRGBA->new );
        $color;
    });

    $ffi->attach( [ TCOD_tileset_set_tile_ => 'set_tile' ] => [qw( TCOD_tileset int TCOD_colorRGBA* )] => 'int' );

    $ffi->attach( [ TCOD_tileset_assign_tile => 'remap' ] => [qw( TCOD_tileset int int int )] => 'int' => sub {
        my ( $xsub, $self, $x, $y, $codepoint ) = @_;
        my $i = $x + $y * $self->tileset->virtual_columns;

        Carp::croak "Tile $i is non-existent and can't be assigned"
            if $i < 0 || $i >= $self->tileset->tiles_count;

        $xsub->( $self, $i, $codepoint );
    });

     $ffi->attach( [ TCOD_tileset_render_to_surface => 'render' ] => [qw( TCOD_console TCOD_console opaque )] => 'int' => sub {
        my ( $xsub, $self, $console ) = @_;

        my $width  = $console->width  * $self->tile_width;
        my $height = $console->height * $self->tile_height;
        my ($pixels) = FFI::Platypus::Buffer::scalar_to_buffer( pack 'S*', (0) x ( $height * $width ) );

        my $surface = TCOD::SDL2::CreateRGBSurfaceWithFormatFrom(
            $pixels,
            $height, $width, 32, 4,
            TCOD::SDL2::PIXELFORMAT_RGBA32,
        ) or die TCOD::SDL2::GetError();

        my $pointer = $ffi->cast( opaque => 'opaque*' => $surface );

        $xsub->( $self, $console, undef, $pointer );
    });

    # $ffi->attach( [ TCOD_tileset_delete => 'DESTROY' ] => ['TCOD_tileset'] => 'void' );
}

package
    TCOD::ContextParams {
    FFI::C->struct( TCOD_context_params => [
        tcod_version      => 'int',
        window_x          => 'int',
        window_y          => 'int',
        pixel_width       => 'int',
        pixel_height      => 'int',
        columns           => 'int',
        rows              => 'int',
        renderer_type     => 'int',
        _tileset          => 'opaque',
        vsync             => 'int',
        sdl_window_flags  => 'int',
        window_title      => 'opaque',
        argc              => 'int',
        argv              => 'opaque',
        cli_output        => 'opaque',
        cli_userdata      => 'opaque',
        window_xy_defined => 'bool',
    ]);

    sub tileset { $ffi->cast( opaque => TCOD_tileset => shift->_tileset ) }
}

package
    TCOD::ViewportOptions {
    FFI::C->struct( TCOD_viewport_options => [
        tcod_version      => 'int',
        keep_aspect       => 'bool',
        integer_scaling   => 'bool',
        _clear_color_r    => 'uint8',
        _clear_color_g    => 'uint8',
        _clear_color_b    => 'uint8',
        _clear_color_a    => 'uint8',
        align_x           => 'float',
        align_y           => 'float',
    ]);
}

package TCOD::Context {
    $ffi->mangler( sub { 'TCOD_context_' . shift } );

    $ffi->attach( new => [qw( TCOD_context_params opaque* )] => 'TCOD_error' => sub {
        my ( $xsub, undef, %args ) = @_;

        for (
            [ x        => 'window_x'                        ],
            [ y        => 'window_y'                        ],
            [ width    => 'pixel_width'                     ],
            [ height   => 'pixel_height'                    ],
            [ renderer => 'renderer_type'                   ],
            [ title    => 'window_title'  => 'string'       ],
            [ tileset  => '_tileset'      => 'TCOD_tileset' ],
        ) {
            my ( $in, $out, $cast ) = @$_;
            next unless exists $args{$in};

            $args{$out} = delete $args{$in};
            $args{$out} = $ffi->cast( $cast => opaque => $args{$out} ) if $cast;
        }

        $args{vsync}            //= 1;
        $args{sdl_window_flags} //= TCOD::SDL2::WINDOW_RESIZABLE();

        if ( TCOD::SDL2::InitSubSystem( TCOD::SDL2::INIT_VIDEO ) ) {
            TCOD::set_error( TCOD::SDL2::GetError() );
            return;
        }

        my $err = $xsub->( TCOD::ContextParams->new(\%args), \my $ctx );
        return if $err < 0;

        bless \$ctx, 'TCOD::Context';
    });

    {
        my $sub = $ffi->function( recommended_console_size => [qw( TCOD_context float int* int* )] => 'TCOD_error' => sub {
            my ( $xsub, $self, $magnification, $min_cols, $min_rows ) = @_;

            my $err = $xsub->( $self, $magnification, \my $w, \my $h );
            Carp::croak TCOD::get_error() if $err < 0;

            $w = $min_cols if $min_cols > $w;
            $h = $min_rows if $min_rows > $h;

            ( $w, $h );
        });

        sub recommended_console_size {
            my ( $self, $min_cols, $min_rows ) = @_;
            $sub->( $self, 1, $min_cols // 1, $min_rows // 1 );
        }

        sub new_console {
            my ( $self, %args ) = ( shift );

            # Accommodate $ctx->new_console( $cols, $rows, $magnification );
            %args = ( min_columns => shift, min_rows => shift, magnification => shift ) if @_ % 2;
            %args = ( %args, @_ );

            $args{min_columns}   //= 1;
            $args{min_rows}      //= 1;
            $args{magnification} //= 1;

            Carp::croak "Magnification must be greater than zero (got $args{magnification}"
                if $args{magnification} < 0;

            my ( $cols, $rows )
                = $sub->( $self, $args{magnification}, @args{qw( min_columns min_rows )} );

            my ( $width, $height ) = @args{qw( min_columns min_rows )};
            $width  = $cols if $cols > $width;
            $height = $rows if $rows > $height;

            TCOD::Console->new( $width, $height );
        }
    }

    $ffi->attach( present => [qw( TCOD_context TCOD_console TCOD_viewport_options )] => 'TCOD_error' => sub {
        my ( $xsub, $self, %args ) = ( shift, shift );

        # Accommodate $ctx->present( $console, %rest );
        %args = ( console => shift ) if @_ % 2;
        %args = ( %args, @_ );

        @args{qw( align_x align_y )} = @{ delete $args{align} // [ 0.5, 0.5 ] };

        my $c = delete $args{clear_color} // TCOD::BLACK();

        $args{_clear_color_r} = $c->r;
        $args{_clear_color_g} = $c->g;
        $args{_clear_color_b} = $c->b;
        $args{_clear_color_a} = 0xFF;

        my $err = $xsub->( $self, delete $args{console}, TCOD::ViewportOptions->new(\%args) );
        Carp::croak TCOD::get_error() if $err < 0;

        return;
    });

    sub convert_event {
        my ( $self, $event ) = @_;

        if ( $event->isa('TCOD::Event::Mouse') && !$event->isa('TCOD::Event::MouseWheel') ) {
            $event->{tilexy} = [ $self->pixel_to_tile( @{ $event->{xy} } ) ];
        }

        if ( $event->isa('TCOD::Event::MouseMotion') ) {
            my ( $xx, $yy ) = $self->pixel_to_tile(
                $event->{xy}[0] - $event->{dxy}[0],
                $event->{xy}[1] - $event->{dxy}[1],
            );

            $event->{tiledxy} = [
                $event->{tilexy}[0] - $xx,
                $event->{tilexy}[1] - $yy,
            ];
        }
    }

    $ffi->attach( [ screen_pixel_to_tile_i => 'pixel_to_tile' ] => [qw( TCOD_context int* int* )] => 'TCOD_error' => sub {
        my ( $xsub, $self, $x, $y ) = @_;
        my ( $xx, $yy ) = ( $x, $y );
        my $err = $xsub->( $self, \$xx, \$yy );
        Carp::croak TCOD::get_error() if $err < 0;
        ( $xx, $yy );
    });

    $ffi->attach( [ screen_pixel_to_tile_d => 'pixel_to_subtile' ] => [qw( TCOD_context double* double* )] => 'TCOD_error' => sub {
        my ( $xsub, $self, $x, $y ) = @_;
        my ( $xx, $yy ) = ( $x, $y );
        my $err = $xsub->( $self, \$xx, \$yy );
        Carp::croak TCOD::get_error() if $err < 0;
        ( $xx, $yy );
    });

    $ffi->mangler( sub { shift } );
    $ffi->attach( [ TCOD_context_delete => 'DESTROY' ] => ['TCOD_context'] => 'void' );
}

package TCOD::Line {
    $ffi->mangler( sub { shift } );

    $ffi->attach( [ TCOD_line => 'bresenham' ] => [qw( int int int int TCOD_line_listener )] => bool => sub {
        my ( $xsub, $x1, $y1, $x2, $y2, $cb ) = @_;

        my @out;
        $cb //= sub { push @out, [ @_ ]; 1 };

        my $closure = $ffi->closure( $cb );
        $xsub->( $x1, $y1, $x2, $y2, $closure );

        @out;
    });
}

for (
    # color values
    [ BLACK                  => [   0,   0,   0 ] ],
    [ DARKEST_GREY           => [  31,  31,  31 ] ],
    [ DARKER_GREY            => [  63,  63,  63 ] ],
    [ DARK_GREY              => [  95,  95,  95 ] ],
    [ GREY                   => [ 127, 127, 127 ] ],
    [ LIGHT_GREY             => [ 159, 159, 159 ] ],
    [ LIGHTER_GREY           => [ 191, 191, 191 ] ],
    [ LIGHTEST_GREY          => [ 223, 223, 223 ] ],
    [ WHITE                  => [ 255, 255, 255 ] ],

    [ DARKEST_SEPIA          => [  31,  24,  15 ] ],
    [ DARKER_SEPIA           => [  63,  50,  31 ] ],
    [ DARK_SEPIA             => [  94,  75,  47 ] ],
    [ SEPIA                  => [ 127, 101,  63 ] ],
    [ LIGHT_SEPIA            => [ 158, 134, 100 ] ],
    [ LIGHTER_SEPIA          => [ 191, 171, 143 ] ],
    [ LIGHTEST_SEPIA         => [ 222, 211, 195 ] ],

    # desaturated
    [ DESATURATED_RED        => [ 127,  63,  63 ] ],
    [ DESATURATED_FLAME      => [ 127,  79,  63 ] ],
    [ DESATURATED_ORANGE     => [ 127,  95,  63 ] ],
    [ DESATURATED_AMBER      => [ 127, 111,  63 ] ],
    [ DESATURATED_YELLOW     => [ 127, 127,  63 ] ],
    [ DESATURATED_LIME       => [ 111, 127,  63 ] ],
    [ DESATURATED_CHARTREUSE => [  95, 127,  63 ] ],
    [ DESATURATED_GREEN      => [  63, 127,  63 ] ],
    [ DESATURATED_SEA        => [  63, 127,  95 ] ],
    [ DESATURATED_TURQUOISE  => [  63, 127, 111 ] ],
    [ DESATURATED_CYAN       => [  63, 127, 127 ] ],
    [ DESATURATED_SKY        => [  63, 111, 127 ] ],
    [ DESATURATED_AZURE      => [  63,  95, 127 ] ],
    [ DESATURATED_BLUE       => [  63,  63, 127 ] ],
    [ DESATURATED_HAN        => [  79,  63, 127 ] ],
    [ DESATURATED_VIOLET     => [  95,  63, 127 ] ],
    [ DESATURATED_PURPLE     => [ 111,  63, 127 ] ],
    [ DESATURATED_FUCHSIA    => [ 127,  63, 127 ] ],
    [ DESATURATED_MAGENTA    => [ 127,  63, 111 ] ],
    [ DESATURATED_PINK       => [ 127,  63,  95 ] ],
    [ DESATURATED_CRIMSON    => [ 127,  63,  79 ] ],

    # lightest
    [ LIGHTEST_RED           => [ 255, 191, 191 ] ],
    [ LIGHTEST_FLAME         => [ 255, 207, 191 ] ],
    [ LIGHTEST_ORANGE        => [ 255, 223, 191 ] ],
    [ LIGHTEST_AMBER         => [ 255, 239, 191 ] ],
    [ LIGHTEST_YELLOW        => [ 255, 255, 191 ] ],
    [ LIGHTEST_LIME          => [ 239, 255, 191 ] ],
    [ LIGHTEST_CHARTREUSE    => [ 223, 255, 191 ] ],
    [ LIGHTEST_GREEN         => [ 191, 255, 191 ] ],
    [ LIGHTEST_SEA           => [ 191, 255, 223 ] ],
    [ LIGHTEST_TURQUOISE     => [ 191, 255, 239 ] ],
    [ LIGHTEST_CYAN          => [ 191, 255, 255 ] ],
    [ LIGHTEST_SKY           => [ 191, 239, 255 ] ],
    [ LIGHTEST_AZURE         => [ 191, 223, 255 ] ],
    [ LIGHTEST_BLUE          => [ 191, 191, 255 ] ],
    [ LIGHTEST_HAN           => [ 207, 191, 255 ] ],
    [ LIGHTEST_VIOLET        => [ 223, 191, 255 ] ],
    [ LIGHTEST_PURPLE        => [ 239, 191, 255 ] ],
    [ LIGHTEST_FUCHSIA       => [ 255, 191, 255 ] ],
    [ LIGHTEST_MAGENTA       => [ 255, 191, 239 ] ],
    [ LIGHTEST_PINK          => [ 255, 191, 223 ] ],
    [ LIGHTEST_CRIMSON       => [ 255, 191, 207 ] ],

    # lighter
    [ LIGHTER_RED            => [ 255, 127, 127 ] ],
    [ LIGHTER_FLAME          => [ 255, 159, 127 ] ],
    [ LIGHTER_ORANGE         => [ 255, 191, 127 ] ],
    [ LIGHTER_AMBER          => [ 255, 223, 127 ] ],
    [ LIGHTER_YELLOW         => [ 255, 255, 127 ] ],
    [ LIGHTER_LIME           => [ 223, 255, 127 ] ],
    [ LIGHTER_CHARTREUSE     => [ 191, 255, 127 ] ],
    [ LIGHTER_GREEN          => [ 127, 255, 127 ] ],
    [ LIGHTER_SEA            => [ 127, 255, 191 ] ],
    [ LIGHTER_TURQUOISE      => [ 127, 255, 223 ] ],
    [ LIGHTER_CYAN           => [ 127, 255, 255 ] ],
    [ LIGHTER_SKY            => [ 127, 223, 255 ] ],
    [ LIGHTER_AZURE          => [ 127, 191, 255 ] ],
    [ LIGHTER_BLUE           => [ 127, 127, 255 ] ],
    [ LIGHTER_HAN            => [ 159, 127, 255 ] ],
    [ LIGHTER_VIOLET         => [ 191, 127, 255 ] ],
    [ LIGHTER_PURPLE         => [ 223, 127, 255 ] ],
    [ LIGHTER_FUCHSIA        => [ 255, 127, 255 ] ],
    [ LIGHTER_MAGENTA        => [ 255, 127, 223 ] ],
    [ LIGHTER_PINK           => [ 255, 127, 191 ] ],
    [ LIGHTER_CRIMSON        => [ 255, 127, 159 ] ],

    # light
    [ LIGHT_RED              => [ 255,  63,  63 ] ],
    [ LIGHT_FLAME            => [ 255, 111,  63 ] ],
    [ LIGHT_ORANGE           => [ 255, 159,  63 ] ],
    [ LIGHT_AMBER            => [ 255, 207,  63 ] ],
    [ LIGHT_YELLOW           => [ 255, 255,  63 ] ],
    [ LIGHT_LIME             => [ 207, 255,  63 ] ],
    [ LIGHT_CHARTREUSE       => [ 159, 255,  63 ] ],
    [ LIGHT_GREEN            => [  63, 255,  63 ] ],
    [ LIGHT_SEA              => [  63, 255, 159 ] ],
    [ LIGHT_TURQUOISE        => [  63, 255, 207 ] ],
    [ LIGHT_CYAN             => [  63, 255, 255 ] ],
    [ LIGHT_SKY              => [  63, 207, 255 ] ],
    [ LIGHT_AZURE            => [  63, 159, 255 ] ],
    [ LIGHT_BLUE             => [  63,  63, 255 ] ],
    [ LIGHT_HAN              => [ 111,  63, 255 ] ],
    [ LIGHT_VIOLET           => [ 159,  63, 255 ] ],
    [ LIGHT_PURPLE           => [ 207,  63, 255 ] ],
    [ LIGHT_FUCHSIA          => [ 255,  63, 255 ] ],
    [ LIGHT_MAGENTA          => [ 255,  63, 207 ] ],
    [ LIGHT_PINK             => [ 255,  63, 159 ] ],
    [ LIGHT_CRIMSON          => [ 255,  63, 111 ] ],

    # normal
    [ RED                    => [ 255,   0,   0 ] ],
    [ FLAME                  => [ 255,  63,   0 ] ],
    [ ORANGE                 => [ 255, 127,   0 ] ],
    [ AMBER                  => [ 255, 191,   0 ] ],
    [ YELLOW                 => [ 255, 255,   0 ] ],
    [ LIME                   => [ 191, 255,   0 ] ],
    [ CHARTREUSE             => [ 127, 255,   0 ] ],
    [ GREEN                  => [   0, 255,   0 ] ],
    [ SEA                    => [   0, 255, 127 ] ],
    [ TURQUOISE              => [   0, 255, 191 ] ],
    [ CYAN                   => [   0, 255, 255 ] ],
    [ SKY                    => [   0, 191, 255 ] ],
    [ AZURE                  => [   0, 127, 255 ] ],
    [ BLUE                   => [   0,   0, 255 ] ],
    [ HAN                    => [  63,   0, 255 ] ],
    [ VIOLET                 => [ 127,   0, 255 ] ],
    [ PURPLE                 => [ 191,   0, 255 ] ],
    [ FUCHSIA                => [ 255,   0, 255 ] ],
    [ MAGENTA                => [ 255,   0, 191 ] ],
    [ PINK                   => [ 255,   0, 127 ] ],
    [ CRIMSON                => [ 255,   0,  63 ] ],

    # dark
    [ DARK_RED               => [ 191,   0,   0 ] ],
    [ DARK_FLAME             => [ 191,  47,   0 ] ],
    [ DARK_ORANGE            => [ 191,  95,   0 ] ],
    [ DARK_AMBER             => [ 191, 143,   0 ] ],
    [ DARK_YELLOW            => [ 191, 191,   0 ] ],
    [ DARK_LIME              => [ 143, 191,   0 ] ],
    [ DARK_CHARTREUSE        => [  95, 191,   0 ] ],
    [ DARK_GREEN             => [   0, 191,   0 ] ],
    [ DARK_SEA               => [   0, 191,  95 ] ],
    [ DARK_TURQUOISE         => [   0, 191, 143 ] ],
    [ DARK_CYAN              => [   0, 191, 191 ] ],
    [ DARK_SKY               => [   0, 143, 191 ] ],
    [ DARK_AZURE             => [   0,  95, 191 ] ],
    [ DARK_BLUE              => [   0,   0, 191 ] ],
    [ DARK_HAN               => [  47,   0, 191 ] ],
    [ DARK_VIOLET            => [  95,   0, 191 ] ],
    [ DARK_PURPLE            => [ 143,   0, 191 ] ],
    [ DARK_FUCHSIA           => [ 191,   0, 191 ] ],
    [ DARK_MAGENTA           => [ 191,   0, 143 ] ],
    [ DARK_PINK              => [ 191,   0,  95 ] ],
    [ DARK_CRIMSON           => [ 191,   0,  47 ] ],

    # darker
    [ DARKER_RED             => [ 127,   0,   0 ] ],
    [ DARKER_FLAME           => [ 127,  31,   0 ] ],
    [ DARKER_ORANGE          => [ 127,  63,   0 ] ],
    [ DARKER_AMBER           => [ 127,  95,   0 ] ],
    [ DARKER_YELLOW          => [ 127, 127,   0 ] ],
    [ DARKER_LIME            => [  95, 127,   0 ] ],
    [ DARKER_CHARTREUSE      => [  63, 127,   0 ] ],
    [ DARKER_GREEN           => [   0, 127,   0 ] ],
    [ DARKER_SEA             => [   0, 127,  63 ] ],
    [ DARKER_TURQUOISE       => [   0, 127,  95 ] ],
    [ DARKER_CYAN            => [   0, 127, 127 ] ],
    [ DARKER_SKY             => [   0,  95, 127 ] ],
    [ DARKER_AZURE           => [   0,  63, 127 ] ],
    [ DARKER_BLUE            => [   0,   0, 127 ] ],
    [ DARKER_HAN             => [  31,   0, 127 ] ],
    [ DARKER_VIOLET          => [  63,   0, 127 ] ],
    [ DARKER_PURPLE          => [  95,   0, 127 ] ],
    [ DARKER_FUCHSIA         => [ 127,   0, 127 ] ],
    [ DARKER_MAGENTA         => [ 127,   0,  95 ] ],
    [ DARKER_PINK            => [ 127,   0,  63 ] ],
    [ DARKER_CRIMSON         => [ 127,   0,  31 ] ],

    # darkest
    [ DARKEST_RED            => [  63,   0,   0 ] ],
    [ DARKEST_FLAME          => [  63,  15,   0 ] ],
    [ DARKEST_ORANGE         => [  63,  31,   0 ] ],
    [ DARKEST_AMBER          => [  63,  47,   0 ] ],
    [ DARKEST_YELLOW         => [  63,  63,   0 ] ],
    [ DARKEST_LIME           => [  47,  63,   0 ] ],
    [ DARKEST_CHARTREUSE     => [  31,  63,   0 ] ],
    [ DARKEST_GREEN          => [   0,  63,   0 ] ],
    [ DARKEST_SEA            => [   0,  63,  31 ] ],
    [ DARKEST_TURQUOISE      => [   0,  63,  47 ] ],
    [ DARKEST_CYAN           => [   0,  63,  63 ] ],
    [ DARKEST_SKY            => [   0,  47,  63 ] ],
    [ DARKEST_AZURE          => [   0,  31,  63 ] ],
    [ DARKEST_BLUE           => [   0,   0,  63 ] ],
    [ DARKEST_HAN            => [  15,   0,  63 ] ],
    [ DARKEST_VIOLET         => [  31,   0,  63 ] ],
    [ DARKEST_PURPLE         => [  47,   0,  63 ] ],
    [ DARKEST_FUCHSIA        => [  63,   0,  63 ] ],
    [ DARKEST_MAGENTA        => [  63,   0,  47 ] ],
    [ DARKEST_PINK           => [  63,   0,  31 ] ],
    [ DARKEST_CRIMSON        => [  63,   0,  15 ] ],

    # metallic
    [ BRASS                  => [ 191, 151,  96 ] ],
    [ COPPER                 => [ 197, 136, 124 ] ],
    [ GOLD                   => [ 229, 191,   0 ] ],
    [ SILVER                 => [ 203, 203, 203 ] ],

    # miscellaneous
    [ CELADON                => [ 172, 255, 175 ] ],
    [ PINKEACH               => [ 255, 159, 127 ] ],
) {
    no strict 'refs';
    my ( $name, @args ) = ( $_->[0], @{ $_->[1] } );
    *{ __PACKAGE__ . '::' . $name } = sub () { TCOD::Color->new( @args ) };
}

# Macros

sub BKGND_ALPHA    { BKGND_ALPH | int( $_[0] * 255 ) << 8 }
sub BKGND_ADDALPHA { BKGND_ADDA | int( $_[0] * 255 ) << 8 }

# Delete helper functions
delete $TCOD::{$_} for qw( enum );

1;
