package Term::Choose::Constants;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.712';

use Exporter qw( import );

our @EXPORT_OK = qw(
        SET_ANY_EVENT_MOUSE_1003 SET_SGR_EXT_MODE_MOUSE_1006
        UNSET_ANY_EVENT_MOUSE_1003 UNSET_SGR_EXT_MODE_MOUSE_1006

        MOUSE_WHEELED LEFTMOST_BUTTON_PRESSED RIGHTMOST_BUTTON_PRESSED FROM_LEFT_2ND_BUTTON_PRESSED
        VK_CODE_PAGE_UP VK_CODE_PAGE_DOWN VK_CODE_END VK_CODE_HOME VK_CODE_LEFT
        VK_CODE_UP VK_CODE_RIGHT VK_CODE_DOWN VK_CODE_INSERT VK_CODE_DELETE

        NEXT_get_key
        CONTROL_SPACE LINE_FEED CARRIAGE_RETURN CONTROL_A CONTROL_B CONTROL_C CONTROL_D CONTROL_E CONTROL_F CONTROL_H
        CONTROL_I CONTROL_K CONTROL_Q CONTROL_U CONTROL_X
        KEY_BTAB KEY_TAB KEY_ESC KEY_SPACE KEY_h KEY_j KEY_k KEY_l KEY_q KEY_Tilde KEY_BSPACE
        VK_PAGE_UP VK_PAGE_DOWN VK_END VK_HOME VK_LEFT VK_UP VK_RIGHT VK_DOWN VK_INSERT VK_DELETE

        WIDTH_CURSOR

        TERM_READKEY
);

our %EXPORT_TAGS = (
    linux => [ qw(
        SET_ANY_EVENT_MOUSE_1003 SET_SGR_EXT_MODE_MOUSE_1006
        UNSET_ANY_EVENT_MOUSE_1003 UNSET_SGR_EXT_MODE_MOUSE_1006
    ) ],
    win32 => [ qw(
        MOUSE_WHEELED LEFTMOST_BUTTON_PRESSED RIGHTMOST_BUTTON_PRESSED FROM_LEFT_2ND_BUTTON_PRESSED
        VK_CODE_PAGE_UP VK_CODE_PAGE_DOWN VK_CODE_END VK_CODE_HOME VK_CODE_LEFT
        VK_CODE_UP VK_CODE_RIGHT VK_CODE_DOWN VK_CODE_INSERT VK_CODE_DELETE
    ) ],
    keys => [ qw(
        NEXT_get_key
        CONTROL_SPACE LINE_FEED CARRIAGE_RETURN CONTROL_A CONTROL_B CONTROL_C CONTROL_D CONTROL_E CONTROL_F CONTROL_H
        CONTROL_I CONTROL_K CONTROL_Q CONTROL_U CONTROL_X
        KEY_BTAB KEY_TAB KEY_ESC KEY_SPACE KEY_h KEY_j KEY_k KEY_l KEY_q KEY_Tilde KEY_BSPACE
        VK_PAGE_UP VK_PAGE_DOWN VK_END VK_HOME VK_LEFT VK_UP VK_RIGHT VK_DOWN VK_INSERT VK_DELETE
    ) ]
);

use constant TERM_READKEY => eval { require Term::ReadKey; 1 };

use constant WIDTH_CURSOR => 1;

use constant {
    SET_ANY_EVENT_MOUSE_1003      => "\e[?1003h",
    SET_SGR_EXT_MODE_MOUSE_1006   => "\e[?1006h",
    UNSET_ANY_EVENT_MOUSE_1003    => "\e[?1003l",
    UNSET_SGR_EXT_MODE_MOUSE_1006 => "\e[?1006l",
};

use constant {
    MOUSE_WHEELED                => 0x0004,
    LEFTMOST_BUTTON_PRESSED      => 0x0001,
    RIGHTMOST_BUTTON_PRESSED     => 0x0002,
    FROM_LEFT_2ND_BUTTON_PRESSED => 0x0004,

    VK_CODE_PAGE_UP   => 33,
    VK_CODE_PAGE_DOWN => 34,
    VK_CODE_END       => 35,
    VK_CODE_HOME      => 36,
    VK_CODE_LEFT      => 37,
    VK_CODE_UP        => 38,
    VK_CODE_RIGHT     => 39,
    VK_CODE_DOWN      => 40,
    VK_CODE_INSERT    => 45,
    VK_CODE_DELETE    => 46,
};

use constant {
    NEXT_get_key  => -1,

    CONTROL_SPACE   => 0x00,
    CONTROL_A       => 0x01,
    CONTROL_B       => 0x02,
    CONTROL_C       => 0x03,
    CONTROL_D       => 0x04,
    CONTROL_E       => 0x05,
    CONTROL_F       => 0x06,
    CONTROL_H       => 0x08,
    KEY_BTAB        => 0x08,
    CONTROL_I       => 0x09,
    KEY_TAB         => 0x09,
    LINE_FEED       => 0x0a,
    CONTROL_K       => 0x0b,
    CARRIAGE_RETURN => 0x0d,
    CONTROL_Q       => 0x11,
    CONTROL_U       => 0x15,
    CONTROL_X       => 0x18,
    KEY_ESC         => 0x1b,
    KEY_SPACE       => 0x20,
    KEY_h           => 0x68,
    KEY_j           => 0x6a,
    KEY_k           => 0x6b,
    KEY_l           => 0x6c,
    KEY_q           => 0x71,
    KEY_Tilde       => 0x7e,
    KEY_BSPACE      => 0x7f,

    VK_PAGE_UP    => 333,
    VK_PAGE_DOWN  => 334,
    VK_END        => 335,
    VK_HOME       => 336,
    VK_LEFT       => 337,
    VK_UP         => 338,
    VK_RIGHT      => 339,
    VK_DOWN       => 340,
    VK_INSERT     => 345,
    VK_DELETE     => 346,
};



1;

__END__
