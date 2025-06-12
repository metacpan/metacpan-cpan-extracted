package Term::Choose::Constants;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';

use Exporter qw( import );

our @EXPORT_OK = qw(
    NEXT_get_key
    CONTROL_SPACE LINE_FEED CARRIAGE_RETURN
    CONTROL_A CONTROL_B CONTROL_C CONTROL_D CONTROL_E CONTROL_F CONTROL_H CONTROL_I
    CONTROL_K CONTROL_N CONTROL_P CONTROL_Q CONTROL_R CONTROL_S CONTROL_T CONTROL_U CONTROL_X
    KEY_BTAB KEY_TAB KEY_ESC KEY_SPACE KEY_h KEY_j KEY_k KEY_l KEY_q KEY_Tilde KEY_BSPACE
    VK_LEFT VK_RIGHT VK_UP VK_DOWN
    VK_INSERT VK_DELETE VK_HOME VK_END VK_PAGE_UP VK_PAGE_DOWN
    VK_F1 VK_F2 VK_F3 VK_F4
    ROW COL
    WIDTH_CURSOR EXTRA_W TERM_READKEY
    PH SGR_ES
);

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ]
);


use constant TERM_READKEY => eval { require Term::ReadKey; 1 };

use constant WIDTH_CURSOR => 1;

use constant EXTRA_W => $^O eq 'MSWin32' || $^O eq 'cygwin' ? 0 : WIDTH_CURSOR;

use constant {
    PH     => "\x{feff}",       # zero width placeholder character
    SGR_ES => '\e\[[\d;]*m',
};

use constant {
    ROW => 0,
    COL => 1,
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
#   CONTROL_G       => 0x07,
    CONTROL_H       => 0x08,
    KEY_BTAB        => 0x08,
    CONTROL_I       => 0x09,
    KEY_TAB         => 0x09,
#   CONTROL_J       => 0x0a,
    LINE_FEED       => 0x0a,
    CONTROL_K       => 0x0b,
#   CONTROL_L       => 0x0c,
#   CONTROL_M       => 0x0d,
    CARRIAGE_RETURN => 0x0d,
    CONTROL_N       => 0x0e,
#   CONTROL_O       => 0x0f,
    CONTROL_P       => 0x10,
    CONTROL_Q       => 0x11,
    CONTROL_R       => 0x12, # unused
    CONTROL_S       => 0x13,
    CONTROL_T       => 0x14,
    CONTROL_U       => 0x15,
#   CONTROL_V       => 0x16,
#   CONTROL_W       => 0x17,
    CONTROL_X       => 0x18,
#   CONTROL_Y       => 0x19,
#   CONTROL_Z       => 0x1a,
    KEY_ESC         => 0x1b,
    KEY_SPACE       => 0x20,
    KEY_h           => 0x68,
    KEY_j           => 0x6a,
    KEY_k           => 0x6b,
    KEY_l           => 0x6c,
    KEY_q           => 0x71,
    KEY_Tilde       => 0x7e,
    KEY_BSPACE      => 0x7f,

    VK_PAGE_UP    => 333, # VK_CODE_KEY + 300
    VK_PAGE_DOWN  => 334,
    VK_END        => 335,
    VK_HOME       => 336,
    VK_LEFT       => 337,
    VK_UP         => 338,
    VK_RIGHT      => 339,
    VK_DOWN       => 340,
    VK_INSERT     => 345,
    VK_DELETE     => 346,
    VK_F1         => 412,
    VK_F2         => 413,
    VK_F3         => 414,
    VK_F4         => 415,
};



1;

__END__
