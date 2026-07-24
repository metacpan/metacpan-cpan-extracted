# ------------------------------------------------------------------------
#
#   Termbox (Perl port)
#
#   Implementation based on termbox2 v2.7.0-dev, 8. Feb 2026
#
#   Copyright (C) 2015-2026 Adam Saponara <as@php.net>
#                 2010-2020 nsf <no.smile.face@gmail.com>
#
# ------------------------------------------------------------------------
#   Author: 2024-2026 J. Schneider
# ------------------------------------------------------------------------

package Termbox::PP;
use strict; 
use warnings;
package    # hide from PAUSE
  Termbox; ## no_index

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

# version '...'
use version;
our $version = version->declare('v2.7.0_0');
our $VERSION = version->declare('v0.5.3');

# authority '...'
our $authority = 'github:adsr';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Imports ----------------------------------------------------------------
# ------------------------------------------------------------------------

require bytes;
use Carp ();
use Config;
use Errno ();
use Fcntl;
use IO::File ();
use Params::Check ();
use POSIX qw( :termios_h );
use Scalar::Util qw( blessed );
use Unicode::UCD ();
use utf8;

# ------------------------------------------------------------------------
# Compile-time options ---------------------------------------------------
# ------------------------------------------------------------------------

# Check whether the module is running on a 32-bit or 64-bit version of Windows
use constant _WIN32 => $^O eq 'MSWin32';

# use constant TB_VERSION_STR => $version->normal;
BEGIN { sub TB_VERSION_STR () { state $qv = $version->normal } }

# STRICT is a global flag that enables strict argument checking.
use constant STRICT => !!grep { exists $ENV{$_} && $ENV{$_} } qw(
  PERL_STRICT
  EXTENDED_TESTING
  AUTHOR_TESTING
  RELEASE_TESTING
);

# The following compile-time options are available for conditional code.
# Their defaults are derived from the original C implementation and the
# current Perl configuration, but may be overridden through environment
# variables before loading this module.

# Ensure consistent compile-time options
use constant TB_LIB_OPTS => $ENV{TB_LIB_OPTS} ? 1 : 0;

# Deprecated. Sets TB_OPT_ATTR_W to 32 if not already set.
use constant TB_OPT_TRUECOLOR => $ENV{TB_OPT_TRUECOLOR} ? 1 : 0;

# Integer width of fg and bg attributes. Valid values (assuming system support) 
# are 16, 32, and 64. 32 or 64 enables output mode TB_OUTPUT_TRUECOLOR. 
# 64 enables additional style attributes. (See tb_set_output_mode.) Larger 
# values consume more memory in exchange for more features. Defaults to 16.
use constant TB_OPT_ATTR_W => 
  ( TB_LIB_OPTS                              ) ? $Config{ivsize} * 8 :
  ( exists $ENV{TB_OPT_ATTR_W} 
    && $ENV{TB_OPT_ATTR_W} =~ /^(16|32|64)$/ ) ? $ENV{TB_OPT_ATTR_W} :
  ( TB_OPT_TRUECOLOR                         ) ? 32                  : 
                                                 16                  ;

# If set, enable extended grapheme cluster support (tb_extend_cell, 
# tb_set_cell_ex). Consumes more memory. Defaults off.
use constant TB_OPT_EGC => TB_LIB_OPTS || ($ENV{TB_OPT_EGC} ? 1 : 0);

# Write buffer size for printf operations. Represents the largest string that 
# can be sent in one call to tb_print and tb_send functions. Defaults to 4096.
use constant TB_OPT_PRINTF_BUF => !TB_LIB_OPTS 
  && exists $ENV{TB_OPT_PRINTF_BUF} ? 0+$ENV{TB_OPT_PRINTF_BUF} : 4096;

# Read buffer size for tty reads. Defaults to 64.
use constant TB_OPT_READ_BUF => !TB_LIB_OPTS 
  && exists $ENV{TB_OPT_READ_BUF} ? 0+$ENV{TB_OPT_READ_BUF} : 64;

# If set, use Perl's core Unicode::UCD module instead of the built-in 
# Unicode-aware versions. Note, Unicode::UCD are version-dependent and must 
# support prop_invmap and search_invlist. Defaults to built-in.
use constant TB_OPT_LIBC_WCHAR => !TB_LIB_OPTS 
  && $ENV{TB_OPT_LIBC_WCHAR} 
  && Unicode::UCD->can('prop_invmap') 
  && Unicode::UCD->can('search_invlist') ? 1 : 0;

use constant TB_PATH_MAX => exists $ENV{PATH_MAX} ? 0+$ENV{PATH_MAX} : 4096;
use constant TB_TERMINFO_DIR => exists $ENV{TB_TERMINFO_DIR} 
  ? ''.$ENV{TB_TERMINFO_DIR}
  : undef;

use constant TB_RESIZE_FALLBACK_MS => exists $ENV{TB_RESIZE_FALLBACK_MS} 
  ? 0+$ENV{TB_RESIZE_FALLBACK_MS}
  : 1000;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Exporter qw( import );

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  api => [qw(
    tb_init
    tb_init_file
    tb_init_fd
    tb_init_rwfd
    tb_shutdown

    tb_width
    tb_height

    tb_clear
    tb_set_clear_attrs

    tb_present
    tb_invalidate

    tb_set_cursor
    tb_hide_cursor

    tb_set_cell
    tb_set_cell_ex
    tb_extend_cell

    tb_get_cell

    tb_set_input_mode
    tb_set_output_mode

    tb_peek_event
    tb_poll_event

    tb_get_fds

    tb_print
    tb_printf
    tb_print_ex
    tb_printf_ex

    tb_send
    tb_sendf

    tb_set_func

    tb_utf8_char_length
    tb_utf8_char_to_unicode
    tb_utf8_unicode_to_char

    tb_last_errno
    tb_strerror
    tb_cell_buffer
    tb_has_truecolor
    tb_has_egc
    tb_attr_width
    tb_version
  )],

  keys => [qw(
    TB_KEY_CTRL_TILDE
    TB_KEY_CTRL_2
    TB_KEY_CTRL_A
    TB_KEY_CTRL_B
    TB_KEY_CTRL_C
    TB_KEY_CTRL_D
    TB_KEY_CTRL_E
    TB_KEY_CTRL_F
    TB_KEY_CTRL_G
    TB_KEY_BACKSPACE
    TB_KEY_CTRL_H
    TB_KEY_TAB
    TB_KEY_CTRL_I
    TB_KEY_CTRL_J
    TB_KEY_CTRL_K
    TB_KEY_CTRL_L
    TB_KEY_ENTER
    TB_KEY_CTRL_M
    TB_KEY_CTRL_N
    TB_KEY_CTRL_O
    TB_KEY_CTRL_P
    TB_KEY_CTRL_Q
    TB_KEY_CTRL_R
    TB_KEY_CTRL_S
    TB_KEY_CTRL_T
    TB_KEY_CTRL_U
    TB_KEY_CTRL_V
    TB_KEY_CTRL_W
    TB_KEY_CTRL_X
    TB_KEY_CTRL_Y
    TB_KEY_CTRL_Z
    TB_KEY_ESC
    TB_KEY_CTRL_LSQ_BRACKET
    TB_KEY_CTRL_3
    TB_KEY_CTRL_4
    TB_KEY_CTRL_BACKSLASH
    TB_KEY_CTRL_5
    TB_KEY_CTRL_RSQ_BRACKET
    TB_KEY_CTRL_6
    TB_KEY_CTRL_7
    TB_KEY_CTRL_SLASH
    TB_KEY_CTRL_UNDERSCORE
    TB_KEY_SPACE
    TB_KEY_BACKSPACE2
    TB_KEY_CTRL_8

    TB_KEY_F1
    TB_KEY_F2
    TB_KEY_F3
    TB_KEY_F4
    TB_KEY_F5
    TB_KEY_F6
    TB_KEY_F7
    TB_KEY_F8
    TB_KEY_F9
    TB_KEY_F10
    TB_KEY_F11
    TB_KEY_F12
    TB_KEY_INSERT
    TB_KEY_DELETE
    TB_KEY_HOME
    TB_KEY_END
    TB_KEY_PGUP
    TB_KEY_PGDN
    TB_KEY_ARROW_UP
    TB_KEY_ARROW_DOWN
    TB_KEY_ARROW_LEFT
    TB_KEY_ARROW_RIGHT
    TB_KEY_BACK_TAB
    TB_KEY_MOUSE_LEFT
    TB_KEY_MOUSE_RIGHT
    TB_KEY_MOUSE_MIDDLE
    TB_KEY_MOUSE_RELEASE
    TB_KEY_MOUSE_WHEEL_UP
    TB_KEY_MOUSE_WHEEL_DOWN

    TB_CAP_F1
    TB_CAP_F2
    TB_CAP_F3
    TB_CAP_F4
    TB_CAP_F5
    TB_CAP_F6
    TB_CAP_F7
    TB_CAP_F8
    TB_CAP_F9
    TB_CAP_F10
    TB_CAP_F11
    TB_CAP_F12
    TB_CAP_INSERT
    TB_CAP_DELETE
    TB_CAP_HOME
    TB_CAP_END
    TB_CAP_PGUP
    TB_CAP_PGDN
    TB_CAP_ARROW_UP
    TB_CAP_ARROW_DOWN
    TB_CAP_ARROW_LEFT
    TB_CAP_ARROW_RIGHT
    TB_CAP_BACK_TAB
    TB_CAP__COUNT_KEYS
    TB_CAP_ENTER_CA
    TB_CAP_EXIT_CA
    TB_CAP_SHOW_CURSOR
    TB_CAP_HIDE_CURSOR
    TB_CAP_CLEAR_SCREEN
    TB_CAP_SGR0
    TB_CAP_UNDERLINE
    TB_CAP_BOLD
    TB_CAP_BLINK
    TB_CAP_ITALIC
    TB_CAP_REVERSE
    TB_CAP_ENTER_KEYPAD
    TB_CAP_EXIT_KEYPAD
    TB_CAP_DIM
    TB_CAP_INVISIBLE
    TB_CAP__COUNT
  )],

  colors => [qw(
    TB_DEFAULT
    TB_BLACK
    TB_RED
    TB_GREEN
    TB_YELLOW
    TB_BLUE
    TB_MAGENTA
    TB_CYAN
    TB_WHITE

    TB_BOLD
    TB_UNDERLINE
    TB_REVERSE
    TB_ITALIC
    TB_BLINK
    TB_HI_BLACK
    TB_BRIGHT
    TB_DIM
    ),
    TB_OPT_ATTR_W == 16
    ? qw( TB_256_BLACK )
    : qw( TB_TRUECOLOR_BOLD
          TB_TRUECOLOR_UNDERLINE
          TB_TRUECOLOR_REVERSE
          TB_TRUECOLOR_ITALIC
          TB_TRUECOLOR_BLINK
          TB_TRUECOLOR_BLACK ),
    TB_OPT_ATTR_W == 64
    ? qw( TB_STRIKEOUT
          TB_UNDERLINE_2
          TB_OVERLINE
          TB_INVISIBLE )
    : ()
  ],

  event => [qw(
    TB_EVENT_KEY
    TB_EVENT_RESIZE
    TB_EVENT_MOUSE

    TB_MOD_ALT
    TB_MOD_CTRL
    TB_MOD_SHIFT
    TB_MOD_MOTION

    TB_INPUT_CURRENT
    TB_INPUT_ESC
    TB_INPUT_ALT
    TB_INPUT_MOUSE

    TB_OUTPUT_CURRENT
    TB_OUTPUT_NORMAL
    TB_OUTPUT_256
    TB_OUTPUT_216
    TB_OUTPUT_GRAYSCALE
    ), 
    TB_OPT_ATTR_W >= 32 
    ? qw( TB_OUTPUT_TRUECOLOR ) 
    : ()
  ],

  return => [qw(
    TB_OK
    TB_ERR
    TB_ERR_NEED_MORE
    TB_ERR_INIT_ALREADY
    TB_ERR_INIT_OPEN
    TB_ERR_MEM
    TB_ERR_NO_EVENT
    TB_ERR_NO_TERM
    TB_ERR_NOT_INIT
    TB_ERR_OUT_OF_BOUNDS
    TB_ERR_READ
    TB_ERR_RESIZE_IOCTL
    TB_ERR_RESIZE_PIPE
    TB_ERR_RESIZE_SIGACTION
    TB_ERR_POLL
    TB_ERR_TCGETATTR
    TB_ERR_TCSETATTR
    TB_ERR_UNSUPPORTED_TERM
    TB_ERR_RESIZE_WRITE
    TB_ERR_RESIZE_POLL
    TB_ERR_RESIZE_READ
    TB_ERR_RESIZE_SSCANF
    TB_ERR_CAP_COLLISION

    TB_ERR_SELECT
    TB_ERR_RESIZE_SELECT
    ),
    _WIN32 
    ? qw( TB_ERR_WIN_RESIZE
          TB_ERR_WIN_GET_CONMODE
          TB_ERR_WIN_SET_CONMODE
          TB_ERR_WIN_NO_STDIO
          TB_ERR_WIN_UNSUPPORTED )
    : ()
  ],

  func => [qw(
    TB_FUNC_EXTRACT_PRE
    TB_FUNC_EXTRACT_POST
  )],

);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

use constant INT16_SIZE => $Config{shortsize};

# ASCII key constants ($tb_event->key)
use constant {
  TB_KEY_CTRL_TILDE       => 0x00,
  TB_KEY_CTRL_2           => 0x00, # clash with 'CTRL_TILDE'
  TB_KEY_CTRL_A           => 0x01,
  TB_KEY_CTRL_B           => 0x02,
  TB_KEY_CTRL_C           => 0x03,
  TB_KEY_CTRL_D           => 0x04,
  TB_KEY_CTRL_E           => 0x05,
  TB_KEY_CTRL_F           => 0x06,
  TB_KEY_CTRL_G           => 0x07,
  TB_KEY_BACKSPACE        => 0x08,
  TB_KEY_CTRL_H           => 0x08, # clash with 'BACKSPACE'
  TB_KEY_TAB              => 0x09,
  TB_KEY_CTRL_I           => 0x09, # clash with 'TAB'
  TB_KEY_CTRL_J           => 0x0a,
  TB_KEY_CTRL_K           => 0x0b,
  TB_KEY_CTRL_L           => 0x0c,
  TB_KEY_ENTER            => 0x0d,
  TB_KEY_CTRL_M           => 0x0d, # clash with 'ENTER'
  TB_KEY_CTRL_N           => 0x0e,
  TB_KEY_CTRL_O           => 0x0f,
  TB_KEY_CTRL_P           => 0x10,
  TB_KEY_CTRL_Q           => 0x11,
  TB_KEY_CTRL_R           => 0x12,
  TB_KEY_CTRL_S           => 0x13,
  TB_KEY_CTRL_T           => 0x14,
  TB_KEY_CTRL_U           => 0x15,
  TB_KEY_CTRL_V           => 0x16,
  TB_KEY_CTRL_W           => 0x17,
  TB_KEY_CTRL_X           => 0x18,
  TB_KEY_CTRL_Y           => 0x19,
  TB_KEY_CTRL_Z           => 0x1a,
  TB_KEY_ESC              => 0x1b,
  TB_KEY_CTRL_LSQ_BRACKET => 0x1b, # clash with 'ESC'
  TB_KEY_CTRL_3           => 0x1b, # clash with 'ESC'
  TB_KEY_CTRL_4           => 0x1c,
  TB_KEY_CTRL_BACKSLASH   => 0x1c, # clash with 'CTRL_4'
  TB_KEY_CTRL_5           => 0x1d,
  TB_KEY_CTRL_RSQ_BRACKET => 0x1d, # clash with 'CTRL_5'
  TB_KEY_CTRL_6           => 0x1e,
  TB_KEY_CTRL_7           => 0x1f,
  TB_KEY_CTRL_SLASH       => 0x1f, # clash with 'CTRL_7'
  TB_KEY_CTRL_UNDERSCORE  => 0x1f, # clash with 'CTRL_7'
  TB_KEY_SPACE            => 0x20,
  TB_KEY_BACKSPACE2       => 0x7f,
  TB_KEY_CTRL_8           => 0x7f, # clash with 'BACKSPACE2'
};

sub tb_key_i($) { 0xFFFF - $_[0] }

# Terminal-dependent key constants ($tb_event->key) and terminfo caps
use constant {
  TB_KEY_F1               => 0xFFFF - 0,
  TB_KEY_F2               => 0xFFFF - 1,
  TB_KEY_F3               => 0xFFFF - 2,
  TB_KEY_F4               => 0xFFFF - 3,
  TB_KEY_F5               => 0xFFFF - 4,
  TB_KEY_F6               => 0xFFFF - 5,
  TB_KEY_F7               => 0xFFFF - 6,
  TB_KEY_F8               => 0xFFFF - 7,
  TB_KEY_F9               => 0xFFFF - 8,
  TB_KEY_F10              => 0xFFFF - 9,
  TB_KEY_F11              => 0xFFFF - 10,
  TB_KEY_F12              => 0xFFFF - 11,
  TB_KEY_INSERT           => 0xFFFF - 12,
  TB_KEY_DELETE           => 0xFFFF - 13,
  TB_KEY_HOME             => 0xFFFF - 14,
  TB_KEY_END              => 0xFFFF - 15,
  TB_KEY_PGUP             => 0xFFFF - 16,
  TB_KEY_PGDN             => 0xFFFF - 17,
  TB_KEY_ARROW_UP         => 0xFFFF - 18,
  TB_KEY_ARROW_DOWN       => 0xFFFF - 19,
  TB_KEY_ARROW_LEFT       => 0xFFFF - 20,
  TB_KEY_ARROW_RIGHT      => 0xFFFF - 21,
  TB_KEY_BACK_TAB         => 0xFFFF - 22,
  TB_KEY_MOUSE_LEFT       => 0xFFFF - 23,
  TB_KEY_MOUSE_RIGHT      => 0xFFFF - 24,
  TB_KEY_MOUSE_MIDDLE     => 0xFFFF - 25,
  TB_KEY_MOUSE_RELEASE    => 0xFFFF - 26,
  TB_KEY_MOUSE_WHEEL_UP   => 0xFFFF - 27,
  TB_KEY_MOUSE_WHEEL_DOWN => 0xFFFF - 28,
};

use constant {
  TB_CAP_F1               => 0,
  TB_CAP_F2               => 1,
  TB_CAP_F3               => 2,
  TB_CAP_F4               => 3,
  TB_CAP_F5               => 4,
  TB_CAP_F6               => 5,
  TB_CAP_F7               => 6,
  TB_CAP_F8               => 7,
  TB_CAP_F9               => 8,
  TB_CAP_F10              => 9,
  TB_CAP_F11              => 10,
  TB_CAP_F12              => 11,
  TB_CAP_INSERT           => 12,
  TB_CAP_DELETE           => 13,
  TB_CAP_HOME             => 14,
  TB_CAP_END              => 15,
  TB_CAP_PGUP             => 16,
  TB_CAP_PGDN             => 17,
  TB_CAP_ARROW_UP         => 18,
  TB_CAP_ARROW_DOWN       => 19,
  TB_CAP_ARROW_LEFT       => 20,
  TB_CAP_ARROW_RIGHT      => 21,
  TB_CAP_BACK_TAB         => 22,
  TB_CAP__COUNT_KEYS      => 23,
  TB_CAP_ENTER_CA         => 23,
  TB_CAP_EXIT_CA          => 24,
  TB_CAP_SHOW_CURSOR      => 25,
  TB_CAP_HIDE_CURSOR      => 26,
  TB_CAP_CLEAR_SCREEN     => 27,
  TB_CAP_SGR0             => 28,
  TB_CAP_UNDERLINE        => 29,
  TB_CAP_BOLD             => 30,
  TB_CAP_BLINK            => 31,
  TB_CAP_ITALIC           => 32,
  TB_CAP_REVERSE          => 33,
  TB_CAP_ENTER_KEYPAD     => 34,
  TB_CAP_EXIT_KEYPAD      => 35,
  TB_CAP_DIM              => 36,
  TB_CAP_INVISIBLE        => 37,
  TB_CAP__COUNT           => 38,
};

# Some hard-coded caps
use constant {
  TB_HARDCAP_ENTER_MOUSE  => "\x1b[?1000h\x1b[?1002h\x1b[?1015h\x1b[?1006h",
  TB_HARDCAP_EXIT_MOUSE   => "\x1b[?1006l\x1b[?1015l\x1b[?1002l\x1b[?1000l",
  TB_HARDCAP_STRIKEOUT    => "\x1b[9m",
  TB_HARDCAP_UNDERLINE_2  => "\x1b[21m",
  TB_HARDCAP_OVERLINE     => "\x1b[53m",
};

# Colors (numeric) and attributes (bitwise) ($tb_cell->fg, $tb_cell->bg)
use constant {
  TB_DEFAULT        => 0x0000,
  TB_BLACK          => 0x0001,
  TB_RED            => 0x0002,
  TB_GREEN          => 0x0003,
  TB_YELLOW         => 0x0004,
  TB_BLUE           => 0x0005,
  TB_MAGENTA        => 0x0006,
  TB_CYAN           => 0x0007,
  TB_WHITE          => 0x0008,
};

BEGIN { if (TB_OPT_ATTR_W == 16) {
  no warnings 'once';
  *TB_BOLD        = sub () { 0x0100 };
  *TB_UNDERLINE   = sub () { 0x0200 };
  *TB_REVERSE     = sub () { 0x0400 };
  *TB_ITALIC      = sub () { 0x0800 };
  *TB_BLINK       = sub () { 0x1000 };
  *TB_HI_BLACK    = sub () { 0x2000 };
  *TB_BRIGHT      = sub () { 0x4000 };
  *TB_DIM         = sub () { 0x8000 };
  *TB_256_BLACK   = &TB_HI_BLACK;    # TB_256_BLACK is deprecated
}
else { # TB_OPT_ATTR_W is 32 or 64
  no warnings 'once';
  *TB_BOLD                = sub () { 0x01000000 };
  *TB_UNDERLINE           = sub () { 0x02000000 };
  *TB_REVERSE             = sub () { 0x04000000 };
  *TB_ITALIC              = sub () { 0x08000000 };
  *TB_BLINK               = sub () { 0x10000000 };
  *TB_HI_BLACK            = sub () { 0x20000000 };
  *TB_BRIGHT              = sub () { 0x40000000 };
  *TB_DIM                 = sub () { 0x80000000 };
  *TB_TRUECOLOR_BOLD      = &TB_BOLD;    # TB_TRUECOLOR_BOLD is deprecated
  *TB_TRUECOLOR_UNDERLINE = &TB_UNDERLINE;
  *TB_TRUECOLOR_REVERSE   = &TB_REVERSE;
  *TB_TRUECOLOR_ITALIC    = &TB_ITALIC;
  *TB_TRUECOLOR_BLINK     = &TB_BLINK;
  *TB_TRUECOLOR_BLACK     = &TB_HI_BLACK;
}}

BEGIN { if (TB_OPT_ATTR_W == 64) {
  no warnings;
  *TB_STRIKEOUT    = sub () { 0x010000000000 };
  *TB_UNDERLINE_2  = sub () { 0x020000000000 };
  *TB_OVERLINE     = sub () { 0x040000000000 };
  *TB_INVISIBLE    = sub () { 0x080000000000 };
}}

# Event types ($tb_event->type)
use constant {
  TB_EVENT_KEY    => 1,
  TB_EVENT_RESIZE => 2,
  TB_EVENT_MOUSE  => 3,
};

# Key modifiers (bitwise) ($tb_event->mod)
use constant {
  TB_MOD_ALT    => 1,
  TB_MOD_CTRL   => 2,
  TB_MOD_SHIFT  => 4,
  TB_MOD_MOTION => 8,
};

# Input modes (bitwise) (tb_set_input_mode)
use constant {
  TB_INPUT_CURRENT => 0,
  TB_INPUT_ESC     => 1,
  TB_INPUT_ALT     => 2,
  TB_INPUT_MOUSE   => 4,
};

# Output modes (bitwise) (tb_set_output_mode)
use constant {
  TB_OUTPUT_CURRENT   => 0,
  TB_OUTPUT_NORMAL    => 1,
  TB_OUTPUT_256       => 2,
  TB_OUTPUT_216       => 4,
  TB_OUTPUT_GRAYSCALE => 8,
};
BEGIN { if (TB_OPT_ATTR_W >= 32) {
  no warnings 'once';
  *TB_OUTPUT_TRUECOLOR = sub () { 5 };
}}

# Common function return values unless otherwise noted.
use constant {
  TB_OK                   => 0,
  TB_ERR                  => -1,
  TB_ERR_NEED_MORE        => -2,
  TB_ERR_INIT_ALREADY     => -3,
  TB_ERR_INIT_OPEN        => -4,
  TB_ERR_MEM              => -5,
  TB_ERR_NO_EVENT         => -6,
  TB_ERR_NO_TERM          => -7,
  TB_ERR_NOT_INIT         => -8,
  TB_ERR_OUT_OF_BOUNDS    => -9,
  TB_ERR_READ             => -10,
  TB_ERR_RESIZE_IOCTL     => -11,
  TB_ERR_RESIZE_PIPE      => -12,
  TB_ERR_RESIZE_SIGACTION => -13,
  TB_ERR_POLL             => -14,
  TB_ERR_TCGETATTR        => -15,
  TB_ERR_TCSETATTR        => -16,
  TB_ERR_UNSUPPORTED_TERM => -17,
  TB_ERR_RESIZE_WRITE     => -18,
  TB_ERR_RESIZE_POLL      => -19,
  TB_ERR_RESIZE_READ      => -20,
  TB_ERR_RESIZE_SSCANF    => -21,
  TB_ERR_CAP_COLLISION    => -22,
};
BEGIN { if (_WIN32) {
  no warnings 'once';
  *TB_ERR_WIN_RESIZE      = sub () { -23 };
  *TB_ERR_WIN_GET_CONMODE = sub () { -24 };
  *TB_ERR_WIN_SET_CONMODE = sub () { -25 };
  *TB_ERR_WIN_NO_STDIO    = sub () { -26 };
  *TB_ERR_WIN_UNSUPPORTED = sub () { -27 };
}}
use constant TB_ERR_SELECT        => TB_ERR_POLL;
use constant TB_ERR_RESIZE_SELECT => TB_ERR_RESIZE_POLL;

# Deprecated. Function types to be used with 'tb_set_func'.
use constant {
  TB_FUNC_EXTRACT_PRE  => 0,
  TB_FUNC_EXTRACT_POST => 1,
};

# Mouse escape parser type tags (enum equivalent)
use constant {
  TYPE_VT200 => 0,
  TYPE_1006  => 1,
  TYPE_1015  => 2,
  TYPE_MAX   => 3,
};

# ------------------------------------------------------------------------
# Globals ----------------------------------------------------------------
# ------------------------------------------------------------------------

# Holds the current state of the terminal
use vars qw( $global );

# ------------------------------------------------------------------------
# Utility functions ------------------------------------------------------
# ------------------------------------------------------------------------

BEGIN { require Terminal::WCWidth unless TB_OPT_LIBC_WCHAR }

# Determine if the current locale is CJK, which affects the width of 
# 'A' (Ambiguous) characters.
our $is_cjk = eval {
  require Unicode::EastAsianWidth::Detect;
  Unicode::EastAsianWidth::Detect::is_cjk_lang() ? 1 : 0;
} || 0;

sub wcwidth {
  my ($cp) = @_;

  return -1 if $cp < 0 || $cp > 0x10FFFF;
  return -1 if $cp >= 0xD800 && $cp <= 0xDFFF;
  return  0 if $cp == 0;
  return -1 if $cp <  0x20 || ($cp >= 0x7F && $cp <  0xA0);
  return  1 if $cp <= 0x7E || ($cp >= 0xA0 && $cp <= 0xFF);

  state $unicode_version = Unicode::UCD::UnicodeVersion();
  state $cat = [ Unicode::UCD::prop_invmap('General_Category') ];
  state $eaw = [ Unicode::UCD::prop_invmap('East_Asian_Width') ];
  state $dig = [ Unicode::UCD::prop_invmap('Default_Ignorable_Code_Point') ];

  my $i = Unicode::UCD::search_invlist($cat->[0], $cp);
  if (defined $i) {
    my $v = $cat->[1]->[$i] // '';
    return -1
      if $v eq 'Cc' || $v eq 'Cs' || $v eq 'Cn'
      || $v eq 'Control' || $v eq 'Surrogate' || $v eq 'Unassigned';
    return 0
      if $v eq 'Mn' || $v eq 'Me' || $v eq 'Cf' || $v eq 'Zl' || $v eq 'Zp'
      || $v eq 'Nonspacing_Mark' || $v eq 'Enclosing_Mark'
      || $v eq 'Format' || $v eq 'Line_Separator' 
      || $v eq 'Paragraph_Separator';
  }

  $i = Unicode::UCD::search_invlist($dig->[0], $cp);
  if (defined $i) {
    my $v = $dig->[1]->[$i] // '';
    return 0
      if $v eq 'Y' || $v eq 'Yes' || $v eq 'T' || $v eq 'True' || $v eq '1';
  }

  $i = Unicode::UCD::search_invlist($eaw->[0], $cp);
  if (defined $i) {
    my $v = $eaw->[1]->[$i] // '';
    return 2 if $v eq 'W' || $v eq 'F' || $v eq 'Wide' || $v eq 'Fullwidth';
    return $is_cjk ? 2 : 1 if $v eq 'A' || $v eq 'Ambiguous';
  }

  # Emoji fallback for old runtime Unicode databases
  return 2 
    if $unicode_version lt '9.0.0' && $cp >= 0x1F300 && $cp <= 0x1FAFF;

  return 1;
}

# Use NCCS (if supported); otherwise, read at least 32 fields.
BEGIN { if (eval { &POSIX::NCCS }) {
  *NCCS = \&POSIX::NCCS;
} else {
  *NCCS = sub () { 32 };
}}

sub cfmakeraw {    # void (\$tios)
  my ($tios) = @_;
  return unless blessed($tios) && $tios->isa('POSIX::Termios');
  $tios->setiflag(
    $tios->getiflag() 
    & ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON)
  );
  $tios->setoflag(
    $tios->getoflag() 
    & ~OPOST
  );
  $tios->setlflag(
    $tios->getlflag() 
    & ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN)
  );
  $tios->setcflag(
    ($tios->getcflag() & ~(CSIZE | PARENB)) | CS8
  );
  return;
}

my $clone = sub {    # $clone ()
  my ($src) = @_;
  return undef unless blessed($src) && $src->isa('POSIX::Termios');
  my $dst = POSIX::Termios->new();
  $dst->setiflag($src->getiflag());
  $dst->setoflag($src->getoflag());
  $dst->setcflag($src->getcflag());
  $dst->setlflag($src->getlflag());
  $dst->setispeed($src->getispeed());
  $dst->setospeed($src->getospeed());
  for my $i (0 .. NCCS - 1) {
    $dst->setcc($i, $src->getcc($i));
  }
  return $dst;
};

# ------------------------------------------------------------------------
# Params Check -----------------------------------------------------------
# ------------------------------------------------------------------------

# This sub is a wrapper around Params::Check::check that provides positional 
# argument checking. It returns a coderef that can be used to check the 
# arguments of a function. The coderef will return the original arguments if 
# they pass the checks, or will die with an error message if they fail.
# See Type::Params::compile for the inspiration for this function.
sub compile {
  return sub { @_ } unless STRICT;

  unless (@_) {
    return sub {
      Carp::croak "Expected no arguments" if @_;
      return @_;
    };
  }

  my %tmpl;
  @tmpl{1 .. @_} = @_;

  return sub {
    my %in;
    @in{1 .. @_} = @_;

    local $Params::Check::STRIP_LEADING_DASHES = 0;
    local $Params::Check::PRESERVE_CASE        = 1;
    local $Params::Check::CALLER_DEPTH
      = $Params::Check::CALLER_DEPTH + 1;

    Params::Check::check(\%tmpl, \%in, 0) or do {
      local $_ = Params::Check::last_error();
      s/\bKey '(\d+)'/Argument #$1/g;
      Carp::croak $_;
    };

    return @_;
  };
}

# Types::Standard like templates for Params::Check. 
use constant {
  _Bool      => { required => 1, allow => qr/\A[01]?\z/ },
  _Str       => { 
    required => 1, 
    defined => 1, default => '', strict_type => 1
  },
  _Int       => { required => 1, defined => 1, allow => qr/\A[-]?\d+\z/ },
  _ClassName => { required => 1, defined => 1, allow => qr/\A\w+(::\w+)*\z/ },
  _Ref       => { 
    required => 1, 
    allow => ($] >= 5.016) ? \&CORE::ref : sub { ref($_[0]) }
  },
  _ScalarRef => {
    required => 1, defined => 1, default => \undef, 
    strict_type => 1 
  },
  _ArrayRef => { required => 1, defined => 1, default => [], strict_type => 1 },
  _CodeRef  => { 
    required => 1, defined => 1, default => sub { }, 
    strict_type => 1
  },
  _Object   => { required => 1, allow => \&blessed },
};

sub _Maybe ($) {
  my ($aref) = @_;

  Carp::croak("_Maybe['a] expects exactly one template hashref")
    unless ref($aref) eq 'ARRAY' && @$aref == 1 && ref($aref->[0]) eq 'HASH';

  my ($t) = @$aref;
  my %u = %$t;

  my $allow       = delete $u{allow};
  my $strict_type = delete $u{strict_type};
  my $default     = $u{default};

  $u{defined} = 0;
  $u{allow} = sub {
    my ($v) = @_;
    return 1 unless defined $v;
    return 0 if $strict_type && ref($v) ne ref($default);
    return 1 unless defined $allow;
    return Params::Check::allow(
      $v,
      ref($allow) eq 'ARRAY' ? $allow : [ $allow ],
    );
  };
  return \%u;
}

# Types::Common::Numeric like templates for Params::Check. 
use constant {
  _PositiveInt => { required => 1, defined => 1, allow => qr/\A[1-9]\d*\z/ },
  _PositiveOrZeroInt => { required => 1, defined => 1, allow => qr/\A\d+\z/ },
};

# ------------------------------------------------------------------------
# WinVT ------------------------------------------------------------------
# ------------------------------------------------------------------------

use if _WIN32, 'Time::HiRes';
use if _WIN32, 'Win32::Console';
use if _WIN32, 'Win32API::File', qw(
  :Misc
  :Func
  :FILE_TYPE_
);

# Standard error codes (POSIX errors)
use if _WIN32, constant => {
  EIO        => exists(&Errno::EIO)        ? &Errno::EIO        : 5,
  EBADF      => exists(&Errno::EBADF)      ? &Errno::EBADF      : 9,
  EACCES     => exists(&Errno::EACCES)     ? &Errno::EACCES     : 13,
  EINVAL     => exists(&Errno::EINVAL)     ? &Errno::EINVAL     : 22,
  ENOTTY     => exists(&Errno::ENOTTY)     ? &Errno::ENOTTY     : 25,
  EPIPE      => exists(&Errno::EPIPE)      ? &Errno::EPIPE      : 32,
  EOPNOTSUPP => exists(&Errno::EOPNOTSUPP) ? &Errno::EOPNOTSUPP : 95,
};

# Windows Error Codes
use if _WIN32, constant => {
  ERROR_ACCESS_DENIED     => 0x5,
  ERROR_INVALID_HANDLE    => 0x6,
  ERROR_INVALID_PARAMETER => 0x57,
  ERROR_BROKEN_PIPE       => 0x6d,
  WSAEINVAL               => 0x2726,
};

# Windows INPUT_RECORD EventType
use if _WIN32, constant => {
  KEY_EVENT                => 0x0001,
  MOUSE_EVENT              => 0x0002,
  WINDOW_BUFFER_SIZE_EVENT => 0x0004,
  MENU_EVENT               => 0x0008,
  FOCUS_EVENT              => 0x0010,
};

# Windows Input mode flags
use if _WIN32, constant => {
  ENABLE_INSERT_MODE            => 0x0020,
  ENABLE_QUICK_EDIT_MODE        => 0x0040,
  ENABLE_VIRTUAL_TERMINAL_INPUT => 0x0200,
  ENABLE_EXTENDED_FLAGS         => 0x0080,
};

# Windows Output mode flags
use if _WIN32, constant => {
  ENABLE_VIRTUAL_TERMINAL_PROCESSING => 0x0004,
  DISABLE_NEWLINE_AUTO_RETURN        => 0x0008,
  ENABLE_LVB_GRID_WORLDWIDE          => 0x0010,
};

# Windows codepage's
# https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
use if _WIN32, constant => {
  CP_UTF8 => 65001,
};

# Windows PeekConsoleInput/ReadConsoleInput constants
use if _WIN32, constant => {
  # INPUT_RECORD
  wEventType        => 0,
  # KEY_EVENT_RECORD
  bKeyDown          => 1,
  wRepeatCount      => 2,
  wVirtualKeyCode   => 3,
  wVirtualScanCode  => 4,
  UnicodeChar       => 5,
  AsciiChar         => 5,
  dwControlKeyState => 6,
};

# Windows Virtual-Key Codes
use if _WIN32, constant => {
  VK_SHIFT   => 0x10,    # SHIFT key
  VK_CONTROL => 0x11,    # CTRL key
  VK_MENU    => 0x12,    # ALT key
  VK_CAPITAL => 0x14,    # CAPS LOCK key
  VK_NUMLOCK => 0x90,    # NUM LOCK key
  VK_SCROLL  => 0x91,    # SCROLL LOCK key
};

# Windows wait event constants
use if _WIN32, constant => {
  INFINITE       => 0xffffffff,
  WAIT_OBJECT_0  => 0x00000000,
  WAIT_TIMEOUT   => 0x00000102,
};

# Windows ReadConsoleInputW/WaitForSingleObject imports
BEGIN { if (_WIN32) {
  require Win32::API;

  Win32::API::More->Import('kernel32',
    'DWORD WINAPI WaitForSingleObject(
      HANDLE hHandle,
      DWORD  dwMilliseconds
    )'
  ) or die "Import WaitForSingleObject: $^E";

  my $ReadConsoleInputW = Win32::API::More->new('kernel32',
    'BOOL WINAPI ReadConsoleInputW(
      HANDLE  hConsoleInput,
      LPVOID  lpBuffer,
      DWORD   nLength,
      LPDWORD lpNumberOfEventsRead
    )'
  ) or die "Import ReadConsoleInputW: $^E";

  # Win32::Console::_ReadConsoleInput like wrapper for ReadConsoleInputW
  *ReadConsoleInputW = sub {    # @events ($hConsoleInput)
    state $sig = compile(
      _Int,
    );
    my ($hInput) = $sig->(@_);

    my $lpBuffer = "\0" x 20;
    my $read = 0;
    return ()
      unless $ReadConsoleInputW->Call($hInput, $lpBuffer, 1, $read) && $read;

    my @ir = unpack('S', $lpBuffer);
    my $type = $ir[0] // 0;
    switch: for ($type) {
      case: KEY_EVENT() == $_ and do {
        @ir = ( @ir, unpack('x4 L S S S S L', $lpBuffer) );
        last;
      };
      case: MOUSE_EVENT() == $_ and do {
        @ir = ( @ir, unpack('x4 s2 L L L', $lpBuffer) );
        last;
      };
      case: WINDOW_BUFFER_SIZE_EVENT() == $_ and do {
        @ir = ( @ir, unpack('x4 s2', $lpBuffer) );
        last;
      };
      case: MENU_EVENT()  == $_ || 
            FOCUS_EVENT() == $_ 
      and do {
        @ir = ( @ir, unpack('x4 L', $lpBuffer) );
        last;
      };
      default: {
        return ();
      }
    }
    return @ir > 1 ? @ir : ();
  };
}}

# ------------------------------------------------------------------------
# Helper classes ---------------------------------------------------------
# ------------------------------------------------------------------------

#
# The 'Termbox::Cell' class represents a single cell in the terminal. 
#

sub Termbox::Cell::new {    # $cell ()
  state $sig = compile(
    _ClassName,
  );
  my ($class) = $sig->(@_);
  return bless [ 
    "\0",   # UFT8 string
    0,      # bitwise foreground attributes
    0,      # bitwise background attributes
  ], $class;
}

sub Termbox::Cell::ch { ord $_[0]->[0] }
sub Termbox::Cell::fg { 0+  $_[0]->[1] }
sub Termbox::Cell::bg { 0+  $_[0]->[2] }
if (TB_OPT_EGC) {
  no warnings 'once';
  *Termbox::Cell::ech = sub {
    my $ch = $_[0]->[0];
    length($ch) > 1 ? [ unpack('U*', $ch) ] : undef;
  };
  *Termbox::Cell::nech = sub {
    my $ch = $_[0]->[0];
    my $n = length($ch);
    return ($ch =~ /\A\X\z/ && $n > 1) ? $n : 0;
  };
  *Termbox::Cell::cech = sub {
    my $ech = $_[0]->ech;
    $ech ? scalar(@$ech) : 0;
  };
}

sub Termbox::Cell::set {    # $int ($ch, $fg, $bg)
  state $sig = compile(
    _Object,
    _Str,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($cell, $ch, $fg, $bg) = $sig->(@_);

  $ch = "\0" unless length($ch);
  $cell->[0] = TB_OPT_EGC ? $ch : substr($ch, 0, 1);
  $cell->[1] = $fg;
  $cell->[2] = $bg;
  return TB_OK;
}

sub Termbox::Cell::equal {    # $bool ($other)
  state $sig = compile(
    _Object,
    _Object,
  );
  my ($a, $b) = $sig->(@_);
  return 0
    if !(ref $a && ref $b)
    || $a->[0] ne $b->[0]     # ch
    || $a->[1] != $b->[1]     # fg
    || $a->[2] != $b->[2];    # bg
  return 1;
}

sub Termbox::Cell::copy {    # $int ($src)
  state $sig = compile(
    _Object,
    _Object,
  );
  my ($dst, $src) = $sig->(@_);
  @$dst = @$src;
  return TB_OK;
}

#
# The 'Termbox::Event' class represents an input event from the terminal.
#

sub Termbox::Event::new {    # $event ()
  state $sig = compile(
    _ClassName,
  );
  my ($class) = $sig->(@_);
  return bless {
    type => 0,    # one of 'TB_EVENT_*' constants
    mod  => 0,    # bitwise 'TB_MOD_*' constants
    key  => 0,    # one of 'TB_KEY_*' constants
    ch   => 0,    # a Unicode codepoint
    w    => 0,    # resize height
    h    => 0,    # resize height
    x    => 0,    # mouse x
    y    => 0,    # mouse y
  }, $class;
};

sub Termbox::Event::type  { $_[0]->{type} }
sub Termbox::Event::mod   { $_[0]->{mod}  }
sub Termbox::Event::key   { $_[0]->{key}  }
sub Termbox::Event::ch    { $_[0]->{ch}   }
sub Termbox::Event::w     { $_[0]->{w}    }
sub Termbox::Event::h     { $_[0]->{h}    }
sub Termbox::Event::x     { $_[0]->{x}    }
sub Termbox::Event::y     { $_[0]->{y}    }

# 
# The 'cellbuf' class represents the cell buffer of the terminal,
# which holds the state of each cell on the screen.
#

sub cellbuf::new {    # $cellbuf ()
  state $sig = compile(
    _ClassName,
  );
  my ($class) = $sig->(@_);
  return bless {
    width  => 0,
    height => 0,
    cells  => [],
  }, $class;
};

sub cellbuf::init {    # $int ($width, $height)
  state $sig = compile(
    _Object,
    _PositiveInt,
    _PositiveInt,
  );
  my ($c, $w, $h) = $sig->(@_);
  $c->{width}  = $w;
  $c->{height} = $h;
  $c->{cells}  = [ map { Termbox::Cell->new() } 0 .. $w*$h-1 ];
  return TB_OK;
}

sub cellbuf::clear {    # $int ()
  state $sig = compile(
    _Object,
  );
  my ($c) = $sig->(@_);
  my $rv;
  for my $i (0 .. $c->{width}*$c->{height}-1) {
    return $rv if $rv = $c->{cells}[$i]->set(' ', $global->{fg}, $global->{bg});
  }
  return TB_OK;
}

sub cellbuf::get {    # $cell ($x, $y)
  state $sig = compile(
    _Object,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($c, $x, $y) = $sig->(@_);
  return $c->{cells}[ $x + $y * $c->{width} ];
}

sub cellbuf::in_bounds {    # $bool ($x, $y)
  state $sig = compile(
    _Object,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($c, $x, $y) = $sig->(@_);
  if ($x < 0 || $x >= $c->{width} || $y < 0 || $y >= $c->{height}) {
    return 0;
  }
  return 1;
}

sub cellbuf::resize {     # $int ($width, $height)
  state $sig = compile(
    _Object,
    _PositiveInt,
    _PositiveInt,
  );
  my ($c, $w, $h) = $sig->(@_);
  my $rv;

  my $ow = $c->{width};
  my $oh = $c->{height};

  if ($ow == $w && $oh == $h) {
    return TB_OK;
  }

  $w = $w < 1 ? 1 : $w;
  $h = $h < 1 ? 1 : $h;

  my $minw = ($w < $ow) ? $w : $ow;
  my $minh = ($h < $oh) ? $h : $oh;

  my $prev = $c->{cells};

  $rv = $c->init($w, $h);
  return $rv if $rv != TB_OK;
  $rv = $c->clear();
  return $rv if $rv != TB_OK;

  my ($x, $y);
  for ($x = 0; $x < $minw; $x++) {
    for ($y = 0; $y < $minh; $y++) {
      my ($src, $dst);
      $src = $prev->[($y * $ow) + $x];
      return TB_ERR_OUT_OF_BOUNDS unless $c->in_bounds($x, $y);
      $dst = $c->get($x, $y);
      return TB_ERR unless defined $dst;
      $rv = $dst->copy($src);
      return $rv if $rv != TB_OK;
    }
  }

  return TB_OK;
}

#
# captrie class for terminal capability matching
#

sub captrie::new {    # $captrie ()
  state $sig = compile(
    _ClassName,
  );
  my ($class) = $sig->(@_);
  return bless {
    exact      => {},
    prefixes   => {},
    alt        => undef,
  }, $class;
}

sub captrie::clear {    # $int ()
  state $sig = compile(
    _Object,
  );
  my ($self) = $sig->(@_);
  $self->{exact}     = {};
  $self->{prefixes}  = {};
  $self->{alt}       = undef;
  return TB_OK;
}

sub captrie::rebuild_alt {    # $int ()
  state $sig = compile(
    _Object,
  );
  my ($self) = $sig->(@_);
  my @ordered = sort {
       length($b) <=> length($a)
    || $a cmp $b
  } keys %{ $self->{exact} };
  $self->{alt} = @ordered ? join('|', map { quotemeta($_) } @ordered) : undef;
  return TB_OK;
}

sub captrie::has_prefix {    # $bool ($s)
  state $sig = compile(
    _Object,
    _Str,
  );
  my ($self, $s) = $sig->(@_);
  return 0 unless length($s);
  return exists $self->{prefixes}{$s} ? 1 : 0;
}

sub captrie::best_match {    # $s|undef ($buf)
  state $sig = compile(
    _Object,
    _Str,
  );
  my ($self, $buf) = $sig->(@_);
  return undef unless length($buf);
  my $alt = $self->{alt};
  return undef unless defined $alt;
  return $1 if $buf =~ /\A($alt)/s;
  return undef;
}

sub captrie::add {    # $int ($cap, $key, $mod)
  state $sig = compile(
    _Object,
    _Str,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($self, $cap, $key, $mod) = $sig->(@_);
  # Nothing to do for empty caps
  return TB_OK unless length($cap);
  return TB_ERR_CAP_COLLISION if exists $self->{exact}{$cap};

  $self->{exact}{$cap} = {
    key => 0 + $key,
    mod => 0 + $mod,
  };

  for my $i (1 .. length($cap) - 1) {
    my $p = substr($cap, 0, $i);
    $self->{prefixes}{$p} = 1;
  }

  return $self->rebuild_alt();
}

sub captrie::find {    # $int ($buf, \$last, \$depth)
  state $sig = compile(
    _Object,
    _Str,
    _Ref,
    _Ref,
  );
  my ($self, $buf, $last, $depth) = $sig->(@_);
  my $node = {
    is_leaf   => 0,
    key       => 0,
    mod       => 0,
    nchildren => scalar(keys %{ $self->{exact} }) ? 1 : 0,
    cap       => '',
  };

  if (defined(my $m = $self->best_match($buf))) {
    my $leaf = $self->{exact}{$m};
    $node = {
      is_leaf   => 1,
      key       => $leaf->{key},
      mod       => $leaf->{mod},
      # Keep C-shape node contract; derive child-ness from prefix table.
      nchildren => ($self->has_prefix($m) ? 1 : 0),
      cap       => $m,
    };
    $$depth = length($m);
  }
  elsif ($self->has_prefix($buf)) {
    $node->{nchildren} = 1;
    $node->{cap} = $buf;
    $$depth = length($buf);
  }
  else {
    $$depth = 0;
  }

  $$last = $node;
  return TB_OK;
}

# ------------------------------------------------------------------------
# Global state and initialization ----------------------------------------
# ------------------------------------------------------------------------

#
# The 'tb_global' struct holds the global state of the terminal, including
# filehandles, terminal state, colors, modes, parser state, buffers,
#

$global = {
  # Filehandles
  ttyfd       => _WIN32 ? INVALID_HANDLE_VALUE : -1,
  rfd         => _WIN32 ? INVALID_HANDLE_VALUE : -1,
  wfd         => _WIN32 ? INVALID_HANDLE_VALUE : -1,
  ttyfd_open  => 0,
  resize_pipefd => [-1, -1],

  # Terminal state
  width       => -1,
  height      => -1,
  cursor_x    => -1,
  cursor_y    => -1,
  last_x      => -1,
  last_y      => -1,

  # Colors
  fg          => TB_DEFAULT,
  bg          => TB_DEFAULT,
  last_fg     => ~TB_DEFAULT,
  last_bg     => ~TB_DEFAULT,

  # Modes
  input_mode  => TB_INPUT_ESC,
  output_mode => TB_OUTPUT_NORMAL,

  # Terminfo
  terminfo => '',
  # ->{nterminfo} is not needed

  # Parser
  caps        => [ (undef) x TB_CAP__COUNT ],
  cap_trie    => captrie->new(),

  # Buffers
  inbuf       => '',
  outbuf      => '',
  back        => cellbuf->new(),
  front       => cellbuf->new(),

  # Termios
  orig_tios   => undef,
  has_orig_tios => 0,

  # (Error) state
  last_errno  => 0,
  errbuf      => "",
  initialized => 0,
  # ->{errbuf} is not needed

  # Custom callbacks for escape sequence parsing
  fn_extract_esc_pre  => undef,
  fn_extract_esc_post => undef,
};

# ------------------------------------------------------------------------
#  Implementation of the termbox2 API incl. helpers ----------------------
# ------------------------------------------------------------------------

#
# Forwarding declarations of the public termbox API. 
#

# Initialize the termbox library
sub tb_init;
sub tb_init_file;
sub tb_init_fd;
sub tb_init_rwfd;
sub tb_shutdown;

# Return the size of the internal back buffer
sub tb_width;
sub tb_height;

# Clear the internal back buffer
sub tb_clear;
sub tb_set_clear_attrs;

# Synchronize the internal back buffer with the terminal by writing to tty
sub tb_present;

# Clear the internal front buffer and force a complete re-render
sub tb_invalidate;

# Set the position of the cursor
sub tb_set_cursor;
sub tb_hide_cursor;

# Set cell contents in the internal back buffer at the specified position
sub tb_set_cell;
sub tb_set_cell_ex;
sub tb_extend_cell;

# Return a reference to the cell at the specified position
sub tb_get_cell;

# Set the input and output mode
sub tb_set_input_mode;
sub tb_set_output_mode;

# Wait for an event
sub tb_peek_event;
sub tb_poll_event;

# Internal termbox fds that can be used with 'poll', 'select'
sub tb_get_fds;

# Print and printf functions
sub tb_print;
sub tb_printf;
sub tb_print_ex;
sub tb_printf_ex;

# Send raw bytes to terminal
sub tb_send;
sub tb_sendf;

# Set custom callbacks for escape sequence parsing
sub tb_set_func;    # Deprecated

# UTF-8 utility functions
sub tb_utf8_char_length;
sub tb_utf8_char_to_unicode;
sub tb_utf8_unicode_to_char;

# Library utility functions
sub tb_last_errno;
sub tb_strerror;
sub tb_cell_buffer;    # Deprecated
sub tb_has_truecolor;
sub tb_has_egc;
sub tb_attr_width;
sub tb_version;
sub tb_iswprint;
sub tb_wcwidth;

#
# Forwarding declarations of internal helper functions.
#

# Process management helpers
sub tb_reset;
sub tb_printf_inner;
sub tb_deinit;
sub tb_iswprint_ex;
sub tb_cluster_width;

# Terminal initialization helpers
sub init_term_attrs;
sub init_term_caps;

# Terminfo parsing helpers
sub load_terminfo;
sub load_terminfo_from_path;
sub read_terminfo_path;
sub parse_terminfo_caps;
sub load_builtin_caps;
sub get_terminfo_string;
sub get_terminfo_int16;

# Resize handling helpers
sub init_resize_handler;
sub resize_cellbufs;
sub handle_resize;
sub update_term_size;
sub update_term_size_via_esc;

# Escape-cap parser helpers
sub init_cap_trie;
sub cap_trie_add;
sub cap_trie_find;
sub cap_trie_deinit;

# Event extraction helpers
sub wait_event;
sub extract_event;
sub extract_esc;
sub extract_esc_user;
sub extract_esc_cap;
sub extract_esc_mouse;

# Cell related helpers
sub cell_cmp;
sub cell_copy;
sub cell_set;
sub cell_reserve_ech;
sub cell_free;

# Cell buffer related helpers
sub init_cellbuf;
sub cellbuf_init;
sub cellbuf_free;
sub cellbuf_clear;
sub cellbuf_get;
sub cellbuf_in_bounds;
sub cellbuf_resize;

# Sending output helpers
sub send_literal;
sub send_num;
sub send_init_escape_codes;
sub send_clear;
sub send_attr;
sub send_sgr;
sub send_cursor_if;
sub send_char;
sub send_cluster;
sub convert_num;

# Byte buffer related helpers
sub bytebuf_puts;
sub bytebuf_nputs;
sub bytebuf_shift;
sub bytebuf_flush;
sub bytebuf_reserve;
sub bytebuf_free;

# ------------------------------------------------------------------------
# Public API implementation ----------------------------------------------
# ------------------------------------------------------------------------

#
# Initialize the termbox library
#

sub tb_init {    # $int ()
  state $sig = compile();
  $sig->(@_);
if (_WIN32) {
  # Windows Terminal (WT) does not support the traditional termios interface, 
  # so we need to use the Windows API to open the console handles directly.
  use open IO => ':raw'; # https://github.com/Perl/perl5/issues/17665
  my $err = sysopen(TB_OUT, 'CONOUT$', O_RDWR) ? 0 : $!+0;
  if ($err != 0) {
    $global->{last_errno} = $err;
    return TB_ERR_WIN_NO_STDIO;
  }
  $err = sysopen(TB_IN, 'CONIN$', O_RDWR) ? 0 : $!+0;
  if ($err != 0) {
    $global->{last_errno} = $err;
    return TB_ERR_WIN_NO_STDIO;
  }
  $global->{ttyfd_open} = 1;
  return tb_init_rwfd(fileno(TB_IN), fileno(TB_OUT));
} #endif
  return tb_init_file('/dev/tty');
}

sub tb_init_file {    # $int ($path)
  state $sig = compile(
    _Str,
  );
  my ($path) =$sig->(@_);
  return TB_ERR_INIT_ALREADY if $global->{initialized};
if (_WIN32) {
  return TB_ERR_WIN_UNSUPPORTED;
} #endif
  my $ttyfd = sysopen(TB_OUT, $path, O_RDWR) ? (fileno(TB_OUT) // -1) : -1;
  if ($ttyfd < 0) {
    $global->{last_errno} = 0+ $!;
    return TB_ERR_INIT_OPEN;
  }
  $global->{ttyfd_open} = 1;
  return tb_init_fd($ttyfd);
}

sub tb_init_fd {    # $int ($ttyfd)
  state $sig = compile(
    _Int,
  );
  my ($ttyfd) = $sig->(@_);
if (_WIN32) {
  return TB_ERR_WIN_UNSUPPORTED;
} #endif
  return tb_init_rwfd($ttyfd, $ttyfd);
}

sub tb_init_rwfd {    # $int ($rfd, $wfd)
  state $sig = compile(
    _Int,
    _Int,
  );
  my ($rfd, $wfd) = $sig->(@_);
  my $rv;

  tb_reset();
if (_WIN32) {
  my ($hInput, $hOutput);

  for (1) {
    # Check if the file descriptors are windows handles
    $hInput = FdGetOsFHandle($rfd) // INVALID_HANDLE_VALUE;
    if ($hInput == INVALID_HANDLE_VALUE) { $rv = TB_ERR_WIN_NO_STDIO; last }
    $hOutput = FdGetOsFHandle($wfd) // INVALID_HANDLE_VALUE;
    if ($hOutput == INVALID_HANDLE_VALUE) { $rv = TB_ERR_WIN_NO_STDIO; last }

    # Ensure the input and output handle are valid console handles
    $^E = 0;
    Win32::Console::_GetConsoleMode($hInput);
    if ($^E) { $rv = TB_ERR_WIN_GET_CONMODE; last }
    my $mode_out = Win32::Console::_GetConsoleMode($hOutput);
    if ($^E) { $rv = TB_ERR_WIN_GET_CONMODE; last }

    # Check if the console handle supports virtual terminal processing
    Win32::Console::_SetConsoleMode($hOutput, 
      $mode_out | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    if ($^E) { $rv = TB_ERR_WIN_UNSUPPORTED; last }
    my $supportsVT = Win32::Console::_GetConsoleMode($hOutput) 
      & ENABLE_VIRTUAL_TERMINAL_PROCESSING ? 1 : 0;
    if ($^E) { $rv = TB_ERR_WIN_GET_CONMODE; last }

    # Restore the original console mode after checking for VT support
    Win32::Console::_SetConsoleMode($hOutput, $mode_out);
    if ($^E) { $rv = TB_ERR_WIN_SET_CONMODE; last }

    # If the console does not support VT processing, return an error
    if (!$supportsVT) { $rv = TB_ERR_WIN_UNSUPPORTED; last }
  };

  switch: for ($rv // 0) {
    case: TB_ERR_WIN_NO_STDIO() == $_ and do {
      $global->{last_errno} = $! = EBADF;
      last;
    };
    case: TB_ERR_WIN_GET_CONMODE() == $_ and do {
      $global->{last_errno} = $! = ENOTTY;
      last;
    };
    case: TB_ERR_WIN_UNSUPPORTED() == $_ and do {
      $global->{last_errno} = $! = EOPNOTSUPP;
      last;
    };
    default: {
      $rv ||= TB_OK;
    }
  }
  return $rv if $rv != TB_OK;

  $global->{ttyfd} = $hOutput;
  $global->{rfd} = $hInput;
  $global->{wfd} = $hOutput;
} else {
  $global->{ttyfd} =
    POSIX::isatty($rfd) ? $rfd :
    POSIX::isatty($wfd) ? $wfd :
    -1;
  $global->{rfd} = $rfd;
  $global->{wfd} = $wfd;
} #endif

  for (1) {
    $rv = init_term_attrs();        last if $rv != TB_OK;
    $rv = init_term_caps();         last if $rv != TB_OK;
    $rv = init_cap_trie();          last if $rv != TB_OK;
    $rv = init_resize_handler();    last if $rv != TB_OK;
    $rv = send_init_escape_codes(); last if $rv != TB_OK;
    $rv = send_clear();             last if $rv != TB_OK;
    $rv = update_term_size();       last if $rv != TB_OK;
    $rv = init_cellbuf();           last if $rv != TB_OK;

    $global->{initialized} = 1;
  };

  tb_deinit() if $rv != TB_OK;

  return $rv;
}

sub tb_shutdown {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  tb_deinit();
  return TB_OK;
}

#
# Return the size of the internal back buffer
#

sub tb_width {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  return $global->{width};
}

sub tb_height {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  return $global->{height};
}

#
# Clear the internal back buffer
#

sub tb_clear {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  return cellbuf_clear($global->{back});
}

sub tb_set_clear_attrs {    # $int ($fg, $bg)
  state $sig = compile(
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($fg, $bg) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  $global->{fg} = $fg;
  $global->{bg} = $bg;
  return TB_OK;
}

#
# Synchronize the internal back buffer with the terminal by writing to tty
#

sub tb_present {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};

  my $rv;

  # TODO: assert $global->{back}[width,height] == global->{front}[width,height]

  my $front       = $global->{front};
  my $back        = $global->{back};
  my $front_cells = $front->{cells};
  my $back_cells  = $back->{cells};
  my $width       = $front->{width};
  my $height      = $front->{height};

  $global->{last_x} = -1;
  $global->{last_y} = -1;

  my @last = ("\0", ~0, ~0);

  for (my $y = 0; $y < $height; $y++) {
    my $line_offset = $y * $width;

    for (my $x = 0; $x < $width; ) {
      my $cell_offset = $line_offset + $x;

      my $back_cell = $back_cells->[$cell_offset];
      my $front_cell = $front_cells->[$cell_offset];

      my $ch = $back_cell->[0];
      my $is_cluster = 0;
      my $ech;
      my $cp;
      my $w;

if (TB_OPT_EGC &&
#     if (
        length($ch) > 1 && $ch =~ /\A\X\z/
      ) {
        $is_cluster = 1;
        $ech = [ unpack 'U*', $ch ];
        $w = tb_cluster_width($ech, scalar @$ech);
      } else {
#endif
        state %wcwidth_cache;
        $cp = ord($ch);
        $w = $wcwidth_cache{$cp} //= tb_wcwidth($cp);
      }
      $w = 1 if $w < 1;    # wcwidth returns -1 for invalid codepoints

      if ( $back_cell->[0] ne $front_cell->[0]    # ch
        || $back_cell->[1] != $front_cell->[1]    # fg
        || $back_cell->[2] != $front_cell->[2]    # bg
      ) {
        @$front_cell = @$back_cell;

        if ($back_cell->[1] != $last[1] || $back_cell->[2] != $last[2]) {
          send_attr($back_cell->[1], $back_cell->[2]);
          @last = @$back_cell;
        }
        if ($w > 1 && $x >= $width - ($w - 1)) {
          # Not enough room for wide char, send spaces
          for (my $i = $x; $i < $width; $i++) {
            send_char($i, $y, ord(' '));
          }
        } else {
if (TB_OPT_EGC &&
#         if (
            $is_cluster
          ) {
            send_cluster($x, $y, $ech, scalar @$ech);
          } else {
#endif
            send_char($x, $y, $cp);
          }

          # When wcwidth>1, we need to advance the cursor by more
          # than 1, thereby skipping some cells. Set these skipped
          # cells to an invalid codepoint in the front buffer, so
          # that if this cell is later replaced by a wcwidth==1
          # char, we'll get a cell_cmp diff for the skipped cells
          # and properly re-render.
          for (my $i = 1; $i < $w; $i++) {
            my $front_wide = $front_cells->[$cell_offset + $i];
            $front_wide->[0] = "\x{fffd}";    # ch
            $front_wide->[1] = ~0;            # fg
            $front_wide->[2] = ~0;            # bg
          }
        }
      }
      $x += $w;
    }
  }

  $rv = send_cursor_if($global->{cursor_x}, $global->{cursor_y});
  return $rv if $rv != TB_OK;
  $rv = bytebuf_flush(\$global->{outbuf}, $global->{wfd});
  return $rv if $rv != TB_OK;

  return TB_OK;
}

#
# Clear the internal front buffer and force a complete re-render
#

sub tb_invalidate {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  my $rv = resize_cellbufs();
  return $rv if $rv != TB_OK;
  return TB_OK;
}

#
# Set the position of the cursor
#

sub tb_set_cursor {    # $int ($cx, $cy)
  state $sig = compile(
    _Int,
    _Int,
  );
  my ($cx, $cy) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};

  $cx = 0 if $cx < 0;
  $cy = 0 if $cy < 0;

  my $rv;
  if ($global->{cursor_x} == -1) {
    $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_SHOW_CURSOR]);
    return $rv if $rv != TB_OK;
  }
  $rv = send_cursor_if($cx, $cy);
  return $rv if $rv != TB_OK;

  $global->{cursor_x} = $cx;
  $global->{cursor_y} = $cy;

  return TB_OK;
}

sub tb_hide_cursor {   # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};

  if ($global->{cursor_x} >= 0) {
    my $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_HIDE_CURSOR]);
    return $rv if $rv != TB_OK;
  }

  $global->{cursor_x} = -1;
  $global->{cursor_y} = -1;

  return TB_OK;
}

#
# Set cell contents in the internal back buffer at the specified position
#

sub tb_set_cell {    # $int ($x, $y, $ch, $fg, $bg)
  state $sig = compile(
    _Int,
    _Int,
    _Str,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($x, $y, $ch, $fg, $bg) = $sig->(@_);
  # Note: tb_set_cell stores only the first Perl character
  return tb_set_cell_ex($x, $y, substr($ch, 0, 1), 1, $fg, $bg);
}

sub tb_set_cell_ex {    # $int ($x, $y, $ch, $nch, $fg, $bg)
  state $sig = compile(
    _Int,
    _Int,
    _Str,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($x, $y, $ch, $nch, $fg, $bg) = $sig->(@_);
  # Note: ch is a Perl string, not an array of codepoints
  # Note: nch is accepted for API compatibility but ignored in the Perl port
  return TB_ERR_NOT_INIT unless $global->{initialized};
  my $rv;
  my $cell;
  $rv = cellbuf_get($global->{back}, $x, $y, \$cell);
  return $rv if $rv != TB_OK;
  $rv = $cell->set($ch, $fg, $bg);
  return $rv if $rv != TB_OK;
  return TB_OK;
}

sub tb_extend_cell {    # $int ($x, $y, $ch)
  state $sig = compile(
    _Int,
    _Int,
    _Str,
  );
  my ($x, $y, $ch) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
if (TB_OPT_EGC) {
  # TODO: iswprint ch?
  my $rv;
  my $cell;
  $rv = cellbuf_get($global->{back}, $x, $y, \$cell);
  return $rv if $rv != TB_OK;
  # Note: tb_extend_cell appends only the first Perl character
  $cell->[0] .= substr($ch, 0, 1);
  return TB_OK;
} else {
  return TB_ERR;
} #endif
}

#
# Return a reference to the cell at the specified position
#

sub tb_get_cell {    # $int ($x, $y, $back, \$cell)
  state $sig = compile(
    _Int,
    _Int,
    _Bool,
    _Ref,
  );
  my ($x, $y, $back, $cell) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  return cellbuf_get($back ? $global->{back} : $global->{front}, $x, $y, $cell);
}

#
# Set the input and output mode
#

sub tb_set_input_mode {    # $int ($mode)
  state $sig = compile(
    _Int,
  );
  my ($mode) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};

  if ($mode == TB_INPUT_CURRENT) {
    return $global->{input_mode};
  }

  my $esc_or_alt = TB_INPUT_ESC | TB_INPUT_ALT;
  if (($mode & $esc_or_alt) == 0) {
    # neither specified; flip on ESC
    $mode |= TB_INPUT_ESC;
  } elsif (($mode & $esc_or_alt) == $esc_or_alt) {
    # both specified; flip off ALT
    $mode &= ~TB_INPUT_ALT;
  }

  if ($mode & TB_INPUT_MOUSE) {
    bytebuf_puts(\$global->{outbuf}, TB_HARDCAP_ENTER_MOUSE);
    bytebuf_flush(\$global->{outbuf}, $global->{wfd});
  } else {
    bytebuf_puts(\$global->{outbuf}, TB_HARDCAP_EXIT_MOUSE);
    bytebuf_flush(\$global->{outbuf}, $global->{wfd});
  }

  $global->{input_mode} = $mode;
  return TB_OK;
}

sub tb_set_output_mode {    # $int ($mode)
  state $sig = compile(
    _Int,
  );
  my ($mode) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  switch: for ($mode) {
    case: TB_OUTPUT_CURRENT == $_ and 
      return $global->{output_mode};
    case: TB_OUTPUT_NORMAL    == $_ || 
          TB_OUTPUT_256       == $_ ||
          TB_OUTPUT_216       == $_ ||
          TB_OUTPUT_GRAYSCALE == $_ ||
#if 
    (TB_OPT_ATTR_W >= 32 &&
          TB_OUTPUT_TRUECOLOR() == $_)
#endif
    and do {
      $global->{last_fg} = ~$global->{fg};
      $global->{last_bg} = ~$global->{bg};
      $global->{output_mode} = $mode;
      return TB_OK;
    }
  }
  return TB_ERR;
}

#
# Wait for an event
#

sub tb_peek_event {   # $int ($event, $timeout_ms)
  state $sig = compile(
    _Object,
    _Int,
  );
  my ($event, $timeout_ms) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  return wait_event($event, $timeout_ms);
}

sub tb_poll_event {   # $int ($event)
  state $sig = compile(
    _Object,
  );
  my ($event) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
  return wait_event($event, -1);
}

#
# Internal termbox fds that can be used with 'poll', 'select'
#

sub tb_get_fds {      # $int (\$ttyfd, \$resizefd)
  state $sig = compile(
    _ScalarRef,
    _ScalarRef,
  );
  my ($ttyfd, $resizefd) = $sig->(@_);
  return TB_ERR_NOT_INIT unless $global->{initialized};
if (_WIN32) {
  return TB_ERR_WIN_UNSUPPORTED;
} #endif
  $$ttyfd    = $global->{rfd};
  $$resizefd = $global->{resize_pipefd}[0];

  return TB_OK;
}

#
# Print and printf functions
#

sub tb_print {    # $int ($x, $y, $fg, $bg, $str)
  state $sig = compile(
    _Int,
    _Int,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
    _Str,
  );
  my ($x, $y, $fg, $bg, $str) = $sig->(@_);
  return tb_print_ex($x, $y, $fg, $bg, undef, $str);
}

sub tb_printf {    # $int ($x, $y, $fg, $bg, $fmt, @args)
  state $sig = compile(
    _Int,
    _Int,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
    _Str,
  );
  my ($x, $y, $fg, $bg, $fmt, @args) = ($sig->(@_[0..4]), @_[5..$#_]);
  return tb_printf_inner($x, $y, $fg, $bg, undef, $fmt, @args);
}

sub tb_print_ex {    # $int ($x, $y, $fg, $bg, \$out_w|undef, $str)
  state $sig = compile(
    _Int,
    _Int,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
    _Maybe[_ScalarRef],
    _Str,
  );
  my ($x, $y, $fg, $bg, $out_w, $str) = $sig->(@_);

  return TB_ERR_NOT_INIT unless $global->{initialized};

  my $back = $global->{back};
  return TB_ERR_OUT_OF_BOUNDS unless $back->in_bounds($x, $y);

  $$out_w = 0 if defined $out_w;

  my $rv;
  my $w;
  my $ix = $x;
  my $x_prev = $x;
  my $uni;

  while ($str) {
    $rv = tb_utf8_char_to_unicode(\$uni, $str);
    if ($rv < 0) {
      $uni = 0xfffd;            # replace invalid UTF-8 char with U+FFFD
      bytes::substr($str, 0, -$rv, '');
    } elsif ($rv > 0) {
      bytes::substr($str, 0, $rv, '');
    } else {
      last; # shouldn't get here
    }

    if ($uni eq ord("\n")) {    # TODO: \r, \t, \v, \f, etc?
      $x = $ix;
      $x_prev = $x;
      $y++;
      next;
    }

    if (!tb_iswprint_ex($uni, \$w)) {
      $uni = 0xfffd;            # replace non-printable with U+FFFD
      $w = 1;
    }

    if ($w < 0) {
      return TB_ERR;            # shouldn't happen if iswprint
    }
    elsif ($w == 0) {           # combining character
      if ($back->in_bounds($x_prev, $y)) {
        $rv = tb_extend_cell($x_prev, $y, chr $uni);
        return $rv if $rv != TB_OK;
      }
    }
    else {
      if ($back->in_bounds($x, $y)) {
        $rv = tb_set_cell($x, $y, chr $uni, $fg, $bg);
        return $rv if $rv != TB_OK;
      }
      $x_prev = $x;
      $x += $w;
      $$out_w += $w if defined $out_w;
    }
  }

  return TB_OK;
}

sub tb_printf_ex {    # $int ($x, $y, $fg, $bg, \$out_w|undef, $fmt, @args)
  goto &tb_printf_inner;
}

#
# Send raw bytes to terminal
#

sub tb_send {    # $int ($buf, $nbuf)
  state $sig = compile(
    _Str,
    _PositiveOrZeroInt,
  );
  my ($buf, $nbuf) = $sig->(@_);
  return bytebuf_nputs(\$global->{outbuf}, $buf, $nbuf);
}

sub tb_sendf {   # $int ($fmt, @args)
  state $sig = compile(
    _Str,
  );
  my ($fmt, @args) = ($sig->(shift), @_);
  my $buf = @args ? sprintf($fmt, @args) : $fmt;
  my $len = bytes::length($buf);
  return TB_ERR if $len >= TB_OPT_PRINTF_BUF;
  return tb_send($buf, $len);
}

#
# Set custom callbacks for escape sequence parsing
#

sub tb_set_func {    # $int ($fn_type, $fn)
  state $sig = compile(
    _Int,
    _CodeRef,
  );
  my ($fn_type, $fn) = $sig->(@_);

  state $warned = 0;
  warn "tb_set_func() is deprecated and may be removed in a future release\n" 
    if STRICT && !$warned++;

  switch: for ($fn_type) {
    case: TB_FUNC_EXTRACT_PRE == $_ and do {
      $global->{fn_extract_esc_pre} = $fn;
      return TB_OK;
    };
    case: TB_FUNC_EXTRACT_POST == $_ and do {
      $global->{fn_extract_esc_post} = $fn;
      return TB_OK;
    };
  }

  return TB_ERR;
}

#
# UTF-8 utility functions
#

sub tb_utf8_char_length {    # $length ($c)
  state $sig = compile(
    _Str,
  );
  my ($c) = $sig->(@_);
  return 0 if $c eq '';
  $c = bytes::substr($c, 0, 1);
  state $utf8_length = {};
  $utf8_length->{$c} //= do {
    my $b = unpack('C', $c);
      ($b < 0xC0) ? 1
    : ($b < 0xE0) ? 2
    : ($b < 0xF0) ? 3
    : ($b < 0xF8) ? 4
    : ($b < 0xFC) ? 5
    : ($b < 0xFE) ? 6
    :               1;
  };
}

sub tb_utf8_char_to_unicode {    # $length (\$out, $c)
  state $sig = compile(
    _ScalarRef,
    _Str,
  );
  my ($out, $c) = $sig->(@_);
  use bytes;

  return 0 if $c eq '';
  my $b0  = substr($c, 0, 1);
  return 0 if $b0 eq "\0";
  my $len = tb_utf8_char_length($b0);

  my @c = unpack('C*', substr($c, 0, $len));

  state $utf8_mask = [0x7F, 0x1F, 0x0F, 0x07, 0x03, 0x01];
  my $mask = $utf8_mask->[$len - 1] // 0x7F;

  my $result = $c[0] & $mask;

  my $i;
  for ($i = 1; $i < @c && $c[$i] != 0; $i++) {
    $result <<= 6;
    $result |= $c[$i] & 0x3F;
  }

  return -$i if $i != $len;

  $$out = $result;
  return $len;
}

sub tb_utf8_unicode_to_char {    # $length (\$out, $c)
  state $sig = compile(
    _ScalarRef,
    _PositiveOrZeroInt,
  );
  my ($out, $c) = $sig->(@_);

  # Fast path for real Unicode scalar values (<= 0x10FFFF)
  if ($c <= 0x10FFFF) {
    my $s = chr($c);
    utf8::encode($s);
    $$out = $s;
    return bytes::length($s);
  }

  # Fallback for "extended UTF-8" (5/6-byte), C-compatible behavior
  my ($first, $len);

  if    ($c < 0x80)      { $first = 0x00; $len = 1; }
  elsif ($c < 0x800)     { $first = 0xC0; $len = 2; }
  elsif ($c < 0x10000)   { $first = 0xE0; $len = 3; }
  elsif ($c < 0x200000)  { $first = 0xF0; $len = 4; }
  elsif ($c < 0x4000000) { $first = 0xF8; $len = 5; }
  else                   { $first = 0xFC; $len = 6; }

  my @out = (0) x $len;
  for (my $i = $len - 1; $i > 0; --$i) {
    $out[$i] = ($c & 0x3F) | 0x80;
    $c >>= 6;
  }
  $out[0] = $c | $first;
  $$out = pack('C*', @out);

  return $len;
}

#
# Library utility functions
#

sub tb_last_errno {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return 0+ $global->{last_errno};
}

sub tb_strerror {    # $str ($err)
  state $sig = compile(
    _Int,
  );
  my ($err) = $sig->(@_);
  switch: for (int($err)) {
    case: TB_OK == $_ and 
      return "Success";
    case: TB_ERR_NEED_MORE == $_ and 
      return "Not enough input";
    case: TB_ERR_INIT_ALREADY == $_ and 
      return "Termbox initialized already";
    case: TB_ERR_MEM == $_ and 
      return "Out of memory";
    case: TB_ERR_NO_EVENT == $_ and 
      return "No event";
    case: TB_ERR_NO_TERM == $_ and 
      return "No TERM in environment";
    case: TB_ERR_NOT_INIT == $_ and 
      return "Termbox not initialized";
    case: TB_ERR_OUT_OF_BOUNDS == $_ and 
      return "Out of bounds";
    case: TB_ERR_UNSUPPORTED_TERM == $_ and 
      return "Unsupported terminal";
    case: TB_ERR_CAP_COLLISION == $_ and 
      return "Termcaps collision";
    case: TB_ERR_RESIZE_SSCANF == $_ and
      return "Terminal width/height not received by sscanf() after resize";
if (_WIN32) {
    case: TB_ERR_WIN_UNSUPPORTED() == $_ and 
      return "Unsupporrted (Windows)";
    case: TB_ERR_WIN_NO_STDIO() == $_ and 
      return "Stdio not available (Windows)";
    case: TB_ERR_WIN_SET_CONMODE() == $_ and 
      return "Failed to set console mode (Windows)";
    case: TB_ERR_WIN_GET_CONMODE() == $_ and 
      return "Failed to get console mode (Windows)";
    case: TB_ERR_WIN_RESIZE() == $_ and 
      return "Failed to resize console (Windows)";
} #endif
    case: 
      TB_ERR                  == $_ ||
      TB_ERR_INIT_OPEN        == $_ ||
      TB_ERR_READ             == $_ ||
      TB_ERR_RESIZE_IOCTL     == $_ ||
      TB_ERR_RESIZE_PIPE      == $_ ||
      TB_ERR_RESIZE_SIGACTION == $_ ||
      TB_ERR_POLL             == $_ ||
      TB_ERR_TCGETATTR        == $_ ||
      TB_ERR_TCSETATTR        == $_ ||
      TB_ERR_RESIZE_WRITE     == $_ ||
      TB_ERR_RESIZE_POLL      == $_ ||
      TB_ERR_RESIZE_READ      == $_ 
    and do {
      $! = $global->{last_errno} if $global->{last_errno};
      return $! ? "$!" : "Error: $_";
    };
    default: {
      $! = $global->{last_errno} if $global->{last_errno};
      return $! ? "$!" : "Unknown Error";
    }
  }
}

sub tb_cell_buffer {    # \@ ()
  state $sig = compile();
  $sig->(@_);

  state $warned = 0;
  warn "tb_cell_buffer() is deprecated; ".
       "use tb_get_cell() and related APIs instead\n"
    if STRICT && !$warned++;

  my $back = $global->{back};
  return [] unless ref($back) eq 'cellbuf' && ref($back->{cells}) eq 'ARRAY';
  return $back->{cells};
}

sub tb_has_truecolor {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_OPT_ATTR_W >= 32 ? 1 : 0;
}

sub tb_has_egc {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_OPT_EGC ? 1 : 0;
}

sub tb_attr_width {    # $int ()
  state $sig = compile();
  $sig->(@_);
  return TB_OPT_ATTR_W;
}

sub tb_version {    # $str ()
  state $sig = compile();
  $sig->(@_);
  return TB_VERSION_STR;
}

sub tb_iswprint {    # $int ($codepoint)
  state $sig = compile(
    _PositiveOrZeroInt,
  );
  my ($codepoint) = $sig->(@_);
  return tb_iswprint_ex($codepoint, undef);
}

sub tb_wcwidth {    # $int ($codepoint)
  state $sig = compile(
    _PositiveOrZeroInt,
  );
  my ($codepoint) = $sig->(@_);
if (TB_OPT_LIBC_WCHAR) {
  return wcwidth($codepoint);
} else {
  return Terminal::WCWidth::wcwidth($codepoint);
} #endif
}

# ------------------------------------------------------------------------
# Internal helper implementation -----------------------------------------
# ------------------------------------------------------------------------

#
# Process Management Helpers
#

sub tb_reset {    # $int ()
  state $sig = compile();
  $sig->(@_);

  my $ttyfd_open = $global->{ttyfd_open};
  my $orig_tios  = _WIN32 ? $global->{orig_tios} : undef;
  $global = {
    ttyfd         => _WIN32 ? INVALID_HANDLE_VALUE : -1,
    rfd           => _WIN32 ? INVALID_HANDLE_VALUE : -1,
    wfd           => _WIN32 ? INVALID_HANDLE_VALUE : -1,
    ttyfd_open    => $ttyfd_open,
    resize_pipefd => [-1, -1],

    width         => -1,
    height        => -1,
    cursor_x      => -1,
    cursor_y      => -1,
    last_x        => -1,
    last_y        => -1,

    fg            => TB_DEFAULT,
    bg            => TB_DEFAULT,
    last_fg       => ~TB_DEFAULT,
    last_bg       => ~TB_DEFAULT,

    input_mode    => TB_INPUT_ESC,
    output_mode   => TB_OUTPUT_NORMAL,

    terminfo      => '',

    caps          => [ (undef) x TB_CAP__COUNT ],
    cap_trie      => captrie->new(),

    inbuf         => '',
    outbuf        => '',
    back          => cellbuf->new(),
    front         => cellbuf->new(),

    orig_tios     => $orig_tios,
    has_orig_tios => 0,

    last_errno    => 0,
    errbuf        => '',
    initialized   => 0,

    fn_extract_esc_pre  => undef,
    fn_extract_esc_post => undef,
  };

  return TB_OK;
}

sub tb_printf_inner {    # $int ($x, $y, $fg, $bg, \$out_w|undef, $fmt, @args)
  state $sig = compile(
    _Int,
    _Int,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
    _Maybe[_ScalarRef],
    _Str,
  );
  my ($x, $y, $fg, $bg, $out_w, $fmt, @args) = ($sig->(@_[0..5]), @_[6..$#_]);

  my $str = @args ? sprintf($fmt, @args) : $fmt;
  return TB_ERR 
    if !defined($str) 
    || length($str) >= TB_OPT_PRINTF_BUF;

  return tb_print_ex($x, $y, $fg, $bg, $out_w, $str);
}

sub tb_deinit {    # $int ()
  state $sig = compile();
  $sig->(@_);

  if (defined($global->{caps}[0]) && $global->{wfd} >= 0) {
    bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_SHOW_CURSOR]);
    bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_SGR0]);
    bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_CLEAR_SCREEN]);
    bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_EXIT_CA]);
    bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_EXIT_KEYPAD]);
    bytebuf_puts(\$global->{outbuf}, TB_HARDCAP_EXIT_MOUSE);
    bytebuf_flush(\$global->{outbuf}, $global->{wfd});
  }

  if ($global->{ttyfd} >= 0) {
    if ($global->{has_orig_tios}) {
if (_WIN32) {
      # Restore the console input mode
      my $hInput = $global->{rfd} // INVALID_HANDLE_VALUE;
      if ($hInput == INVALID_HANDLE_VALUE) {
        $^E = ERROR_INVALID_HANDLE;
        $global->{last_errno} = $! = EBADF;
        return TB_ERR_WIN_NO_STDIO;
      }
      my $orig_mode_in = $global->{orig_tios}{mode_in};
      if (defined $orig_mode_in) {
        $^E = 0;
        Win32::Console::_SetConsoleMode($hInput, $orig_mode_in);
        if ($^E) {
          $global->{last_errno} = $! = ENOTTY;
          return TB_ERR_WIN_SET_CONMODE;
        }
      }

      # Restore the console output mode
      my $hOutput = $global->{wfd} // INVALID_HANDLE_VALUE;
      if ($hOutput == INVALID_HANDLE_VALUE) {
        $^E = ERROR_INVALID_HANDLE;
        $global->{last_errno} = $! = EBADF;
        return TB_ERR_WIN_NO_STDIO;
      }
      my $orig_mode_out = $global->{orig_tios}{mode_out};
      if (defined $orig_mode_out) {
        $^E = 0;
        Win32::Console::_SetConsoleMode($hOutput, $orig_mode_out);
        if ($^E) {
          $global->{last_errno} = $! = ENOTTY;
          return TB_ERR_WIN_SET_CONMODE;
        }
      }

      # Restore the console output codepage
      my $orig_cp_out = $global->{orig_tios}{cp_out};
      if (defined $orig_cp_out) {
        if (!Win32::Console::_SetConsoleOutputCP($orig_cp_out)) {
          $global->{last_errno} = $! = EIO;
          return TB_ERR_WIN_SET_CONMODE;
        }
      }
} else {
      $global->{orig_tios}->setattr($global->{ttyfd}, TCSAFLUSH);
} #endif
    }
    if ($global->{ttyfd_open}) {
      close(TB_OUT);
if (_WIN32) {
      close(TB_IN);
} #endif
      $global->{ttyfd_open} = 0;
      $global->{ttyfd} = -1;
    }
  }

if (!_WIN32) {
  $SIG{WINCH} = 'DEFAULT' if exists $SIG{WINCH};
  foreach my $fd (@{ $global->{resize_pipefd}}) {
    POSIX::close($fd) if $fd >= 0;
  }
} #endif

  cellbuf_free($global->{back});
  cellbuf_free($global->{front});
  bytebuf_free(\$global->{inbuf});
  bytebuf_free(\$global->{outbuf});

  $global->{terminfo} = '' if $global->{terminfo};

  my $rv = $global->{cap_trie}->clear() if $global->{cap_trie};
  return $rv if $rv != TB_OK;

  tb_reset();
  return TB_OK;
}

END { if ($global->{initialized}) {
  if (STRICT) { warn "tb_shutdown() not called before program exit\n"; sleep 2 }
  tb_deinit();
}}

sub tb_iswprint_ex {    # $bool ($ch, \$width|undef)
  state $sig = compile(
    _PositiveOrZeroInt,
    _Maybe[_ScalarRef],
  );
  my ($ch, $width) = $sig->(@_);
if (TB_OPT_LIBC_WCHAR) {
  my $w = wcwidth($ch);
  $$width = $w if defined $width;

  # NUL is not printable even though width is 0.
  return $ch != 0 && $w >= 0 ? 1 : 0;
} else {
  # Fast path for 1-byte codepoints
  if (($ch >= 0x20 && $ch <= 0x7e) || ($ch >= 0xa0 && $ch <= 0xff)) {
    $$width = 1 if defined $width;
    return 1;
  }
  if ($ch <= 0xff) {
    $$width = ($ch == 0 ? 0 : -1) if defined $width;
    return 0;
  }

  my $w = Terminal::WCWidth::wcwidth($ch);
  $$width = $w if defined $width;
  return $w >= 0 ? 1 : 0;
} #endif
}

sub tb_cluster_width {    # $int (\@cluster, $nch)
  state $sig = compile(
    _ArrayRef,
    _PositiveOrZeroInt,
  );
  my ($cluster, $nch) = $sig->(@_);
  
  my $wmax = -1;
  my ($vs15, $vs16, $ri, $zwj) = (0, 0, 0, 0);

  for my $i (0 .. $nch-1) {
    my $c = $cluster->[$i] // return -1;
    if    ($c == 0xfe0e) { $vs15++ }
    elsif ($c == 0xfe0f) { $vs16++ }
    elsif ($c == 0x200d) { $zwj++ }
    elsif ($c >= 0x1f1e6 && $c <= 0x1f1ff) { $ri++ }

    my $w = tb_wcwidth($c);
    $w = -1 unless defined $w;
    $wmax = $w if $w > $wmax;
  }

  if ($wmax >= 1) {
    return 1 if $vs15;
    return 2 if $vs16 || $zwj || $ri >= 2;
  }

  return $wmax;
}

#
# Terminal initialization helpers
#

sub init_term_attrs {    # $int ()
  state $sig = compile();
  $sig->(@_);

  return TB_OK if $global->{ttyfd} < 0;

if (_WIN32) {
  # Set the console input mode
  my $hInput = $global->{rfd} // INVALID_HANDLE_VALUE;
  if ($hInput == INVALID_HANDLE_VALUE) {
    $^E = ERROR_INVALID_HANDLE;
    $global->{last_errno} = $! = EBADF;
    return TB_ERR_WIN_NO_STDIO;
  }
  $^E = 0;
  my $orig_mode_in = Win32::Console::_GetConsoleMode($hInput);
  if ($^E) {
    $global->{last_errno} = $! = ENOTTY;
    return TB_ERR_WIN_GET_CONMODE;
  }
  my $mode = $orig_mode_in;
  $mode &= ~ENABLE_ECHO_INPUT();      # Turn off echo in a terminal
  $mode &= ~ENABLE_LINE_INPUT();      # no CR for ReadFile or ReadConsole
  $mode |= ENABLE_WINDOW_INPUT();     # Report changes in buffer size
  $mode &= ~ENABLE_PROCESSED_INPUT(); # Report CTRL+C and SHIFT+Arrow events
  $mode |= ENABLE_EXTENDED_FLAGS();   # Disable the Quick Edit mode,
  $mode &= ~ENABLE_QUICK_EDIT_MODE(); # which inhibits the mouse
  $mode |= ENABLE_VIRTUAL_TERMINAL_INPUT(); # Allow ANSI escape sequences
  $^E = 0;
  Win32::Console::_SetConsoleMode($hInput, $mode);
  if ($^E) {
    $global->{last_errno} = $! = ENOTTY;
    return TB_ERR_WIN_SET_CONMODE;
  }

  # Set the console output mode
  my $hOutput = $global->{wfd} // INVALID_HANDLE_VALUE;
  if ($hOutput == INVALID_HANDLE_VALUE) {
    $^E = ERROR_INVALID_HANDLE;
    $global->{last_errno} = $! = EBADF;
    return TB_ERR_WIN_NO_STDIO;
  }
  $^E = 0;
  my $orig_mode_out = Win32::Console::_GetConsoleMode($hOutput);
  if ($^E) {
    $global->{last_errno} = $! = ENOTTY;
    return TB_ERR_WIN_GET_CONMODE;
  }
  $mode = $orig_mode_out;
  $mode |= ENABLE_PROCESSED_OUTPUT();     # enable when using escape sequences.
  $mode &= ~ENABLE_WRAP_AT_EOL_OUTPUT();  # Avoid scrolling when reaching EOL.
  $mode |= DISABLE_NEWLINE_AUTO_RETURN(); # Do not do CR on LF.
  $mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING(); # Allow ANSI escape sequences.
  $^E = 0;
  Win32::Console::_SetConsoleMode($hOutput, $mode);
  if ($^E) {
    $global->{last_errno} = $! = ENOTTY;
    return TB_ERR_WIN_SET_CONMODE;
  }

  # Set the console output codepage to utf8
  $^E = 0;
  my $orig_cp_out = Win32::Console::_GetConsoleOutputCP();
  if ($^E) {
    $global->{last_errno} = $! = EIO;
    return TB_ERR_WIN_GET_CONMODE;
  }
  if (!Win32::Console::_SetConsoleOutputCP(CP_UTF8())) {
    $global->{last_errno} = $! = EIO;
    return TB_ERR_WIN_SET_CONMODE;
  }

  if (!$global->{has_orig_tios}) {
    $global->{orig_tios} = {
      mode_in  => $orig_mode_in,
      mode_out => $orig_mode_out,
      cp_out   => $orig_cp_out,
    };
    $global->{has_orig_tios} = 1;
  }

  return TB_OK;
} #endif

  $global->{orig_tios} = POSIX::Termios->new() // return TB_ERR_TCGETATTR;

  if (!defined $global->{orig_tios}->getattr($global->{ttyfd})) {
    $global->{last_errno} = 0+ $!;
    return TB_ERR_TCGETATTR;
  }

  my $tios = $global->{orig_tios}->$clone() // return TB_ERR_TCSETATTR;
  $global->{has_orig_tios} = 1;

  cfmakeraw($tios);
  $tios->setcc(VMIN,  1);
  $tios->setcc(VTIME, 0);

  if (!defined $tios->setattr($global->{ttyfd}, TCSAFLUSH)) {
    $global->{last_errno} = 0+ $!;
    return TB_ERR_TCSETATTR;
  }

  return TB_OK;
}

sub init_term_caps {    # $int ()
  state $sig = compile();
  $sig->(@_);
if (_WIN32) {
  return load_builtin_caps();
} #endif
  if (load_terminfo() == TB_OK) {
    return parse_terminfo_caps();
  }
  return load_builtin_caps();
}

#
# Terminfo parsing helpers
#

sub load_terminfo {    # $int ()
  state $sig = compile();
  $sig->(@_);
if (_WIN32) {
  return TB_ERR_WIN_UNSUPPORTED;
} #endif
  my $rv;

  # See terminfo(5) "Fetching Compiled Descriptions" for a description of
  # this behavior. Some of these paths are compile-time ncurses options, so
  # best guesses are used here.
  my $term = $ENV{TERM};
  return TB_ERR unless $term;

  # If TERMINFO is set, try that directory first
  if (defined(my $terminfo = $ENV{"TERMINFO"})) {
    $rv = load_terminfo_from_path($terminfo, $term);
    return $rv if $rv == TB_OK;
  }

  # Next try ~/.terminfo
  if (defined(my $home = $ENV{"HOME"})) {
    my $tmp = "$home/.terminfo";

    return TB_ERR if length($tmp) >= TB_PATH_MAX;

    $rv = load_terminfo_from_path($tmp, $term);
    return $rv if $rv == TB_OK;
  }

  # Next try TERMINFO_DIRS
  #
  # Note, empty entries are supposed to be interpretted as the "compiled-in
  # default", which is of course system-dependent. Previously /etc/terminfo
  # was used here. Let's skip empty entries altogether rather than give
  # precedence to a guess, and check common paths after this loop.
  if (defined(my $dirs = $ENV{"TERMINFO_DIRS"})) {
    return TB_ERR if length($dirs) >= TB_PATH_MAX;
    foreach my $dir (split /:/, $dirs, -1) {
      next if $dir eq '';
      $rv = load_terminfo_from_path($dir, $term);
      return $rv if $rv == TB_OK;
    }
  }

  # Try compile-time terminfo directory if available
  if (defined TB_TERMINFO_DIR) {
    $rv = load_terminfo_from_path(TB_TERMINFO_DIR, $term);
    return $rv if $rv == TB_OK;
  }

  foreach my $dir (qw(
    /usr/local/etc/terminfo
    /usr/local/share/terminfo
    /usr/local/lib/terminfo
    /etc/terminfo
    /usr/share/terminfo
    /usr/lib/terminfo
    /usr/share/lib/terminfo
    /lib/terminfo
  )) {
    $rv = load_terminfo_from_path($dir, $term);
    return $rv if $rv == TB_OK;
  }

  return TB_ERR;
}

sub load_terminfo_from_path {    # $int ($path, $term)
  state $sig = compile(
    _Str,
    _Str,
  );
  my ($path, $term) = $sig->(@_);
  my $rv;
  my $tmp;

  # Look for term at this terminfo location, e.g., <terminfo>/x/xterm
  $tmp = "$path/" . substr($term, 0, 1) . "/$term";
  return TB_ERR if length($tmp) >= TB_PATH_MAX;

  $rv = read_terminfo_path($tmp);
  return $rv if $rv == TB_OK;

  if ($^O eq 'darwin') {
    # Try the Darwin equivalent path, e.g., <terminfo>/78/xterm
    $tmp = "$path/" . sprintf('%x', ord(substr($term, 0, 1))) . "/$term";
    return TB_ERR if length($tmp) >= TB_PATH_MAX;

    return read_terminfo_path($tmp);
  }

  return TB_ERR;
}

sub read_terminfo_path {    # $int ($path)
  state $sig = compile(
    _Str,
  );
  my ($path) = $sig->(@_);

  open(my $fp, '<:raw', $path)
    or return TB_ERR;

  my @st = stat($fp);
  if (!@st) {
    close($fp);
    return TB_ERR;
  }

  my $fsize = $st[7];

  my $data = '';
  my $nread = sysread($fp, $data, $fsize);

  if (!defined($nread) || $nread != $fsize) {
    close($fp);
    return TB_ERR;
  }

  $global->{terminfo} = $data;

  close($fp);
  return TB_OK;
}

sub parse_terminfo_caps {    # $int ()
  state $sig = compile();
  $sig->(@_);

  my $terminfo = $global->{terminfo};
  my $nterminfo = length($terminfo) // 0;

  # Ensure there's at least a header's worth of data
  return TB_ERR if $nterminfo < 6 * INT16_SIZE;

  my $terminfo_cap_indexes = eval {
    no warnings 'once';
    require Termbox::PP::Terminfo::Builtin;
    \@Termbox::PP::Terminfo::Builtin::terminfo_cap_indexes; 
  } or return TB_ERR;

  my ($magic_number, $nbytes_names, $nbytes_bools, $num_ints, $num_offsets, 
    $nbytes_strings);

  # header[0] the magic number (octal 0432 or 01036)
  # header[1] the size, in bytes, of the names section
  # header[2] the number of bytes in the boolean section
  # header[3] the number of short integers in the numbers section
  # header[4] the number of offsets (short integers) in the strings section
  # header[5] the size, in bytes, of the string table
  get_terminfo_int16(0 * INT16_SIZE, \$magic_number);
  get_terminfo_int16(1 * INT16_SIZE, \$nbytes_names);
  get_terminfo_int16(2 * INT16_SIZE, \$nbytes_bools);
  get_terminfo_int16(3 * INT16_SIZE, \$num_ints);
  get_terminfo_int16(4 * INT16_SIZE, \$num_offsets);
  get_terminfo_int16(5 * INT16_SIZE, \$nbytes_strings);

  # Legacy ints are 16-bit, extended ints are 32-bit
  my $bytes_per_int = $magic_number == 01036 ? 4     # 32-bit
                                             : 2;    # 16-bit

  # Between the boolean section and the number section, a null byte will be
  # inserted, if necessary, to ensure that the number section begins on 
  # an even byte
  my $align_offset = (($nbytes_names + $nbytes_bools) % 2 != 0) ? 1 : 0;

  my $nbytes_header = 6 * INT16_SIZE;
  my $pos_str_offsets =
      $nbytes_header    # header (12 bytes)
    + $nbytes_names     # length of names section
    + $nbytes_bools     # length of boolean section
    + $align_offset
    + ($num_ints * $bytes_per_int);    # length of string offsets section

  my $pos_str_table =
      $pos_str_offsets
    + ($num_offsets * INT16_SIZE);    # length of string offsets table

  $global->{caps} ||= [];

  # Load caps
  for (my $i = 0; $i < TB_CAP__COUNT; $i++) {
    my $cap = get_terminfo_string($pos_str_offsets, $num_offsets,
      $pos_str_table, $nbytes_strings, $terminfo_cap_indexes->[$i]);
    # Something is not right
    return TB_ERR unless defined $cap;
    $global->{caps}->[$i] = $cap;
  }

  return TB_OK;
}

sub load_builtin_caps {    # $int ()
  state $sig = compile();
  $sig->(@_);
  my $term = $ENV{"TERM"};
if (_WIN32) {
  # Windows Virtual Terminal is xterm-256color compatible
  # https://github.com/microsoft/terminal/issues/6045#issuecomment-631645277
  # https://superuser.com/a/1691012
  $term ||= 'xterm-256color' 
} #endif
  return TB_ERR_NO_TERM unless $term;

  my $builtin_terms = do {
    require Termbox::PP::Terminfo::Builtin;
    no warnings 'once';
    \%Termbox::PP::Terminfo::Builtin::builtin_terms;
  } or return TB_ERR;
  my $builtin_terms_orders = do {
    require Termbox::PP::Terminfo::Builtin;
    no warnings 'once';
    \@Termbox::PP::Terminfo::Builtin::builtin_terms_orders;
  } or return TB_ERR;

  # Check for exact TERM match
  if (exists $builtin_terms->{$term}) {
    my $caps = $builtin_terms->{$term};
    @{ $global->{caps} } = @$caps[0 .. TB_CAP__COUNT - 1];
    return TB_OK;
  }

  # Check for partial TERM or alias match
  foreach my $name (@$builtin_terms_orders) {
    next if index($term, $name) < 0;
    next unless exists $builtin_terms->{$name};

    my $caps = $builtin_terms->{$name};
    @{ $global->{caps} } = @$caps[0 .. TB_CAP__COUNT - 1];
    return TB_OK;
  }

  return TB_ERR_UNSUPPORTED_TERM;
}

sub get_terminfo_string {    # $str|undef ($offsets_pos, $offsets_len, $table_pos, $table_size, $index)
  state $sig = compile(
    _Int,
    _Int,
    _Int,
    _Int,
    _Int,
  );
  my ($offsets_pos, $offsets_len, $table_pos, $table_size, $index) = $sig->(@_);

  if ($index >= $offsets_len) {
    # An index beyond the offset table indicates absent
    # See 'convert_strings' in tinfo 'read_entry.c'
    return '';
  }

  my $table_offset;
  my $table_offset_offset = $offsets_pos + ($index * INT16_SIZE);
  if (get_terminfo_int16($table_offset_offset, \$table_offset) != TB_OK) {
    # offset beyond end of terminfo entry
    # Truncated/corrupt terminfo entry?
    return undef;
  }

  if ($table_offset < 0 || $table_offset >= $table_size) {
    # A negative offset indicates absent
    # An offset beyond the string table indicates absent
    # See 'convert_strings' in tinfo 'read_entry.c'
    return '';
  }

  my $str_offset = $table_pos + $table_offset;
  if ($str_offset >= length($global->{terminfo})) {
    # string beyond end of terminfo entry
    # Truncated/corrupt terminfo entry?
    return undef;
  }

  my $str = substr($global->{terminfo}, $str_offset);
  my $len = index($str, "\0");
  return $len >= 0 ? substr($str, 0, $len) : undef;
}

sub get_terminfo_int16 {    # $int ($offset, \$val)
  state $sig = compile(
    _Int,
    _ScalarRef,
  );
  my ($offset, $val) = $sig->(@_);
  if ($offset < 0 || $offset + INT16_SIZE > length($global->{terminfo})) {
    $$val = -1;
    return TB_ERR;
  }
  $$val = unpack('s<', substr($global->{terminfo}, $offset, INT16_SIZE));
  return TB_OK;
}

#
# Resize handling helpers
#

sub init_resize_handler {    # $int ()
  state $sig = compile();
  $sig->(@_);
if (_WIN32) {
  return TB_OK;
} #endif
  my ($rfd, $wfd);
  unless (($rfd, $wfd) = POSIX::pipe()) {
    $global->{last_errno} = 0+ $!;
    return TB_ERR_RESIZE_PIPE;
  }

  $global->{resize_pipefd} = [$rfd, $wfd];

  $SIG{WINCH} = \&handle_resize if exists $SIG{WINCH};
  return TB_OK;
}

sub resize_cellbufs {    # $int ()
  state $sig = compile();
  $sig->(@_);
  my $rv;
  $rv = cellbuf_resize($global->{back}, $global->{width}, $global->{height});
  return $rv if $rv != TB_OK;
  $rv = cellbuf_resize($global->{front}, $global->{width}, $global->{height});
  return $rv if $rv != TB_OK;
  $rv = cellbuf_clear($global->{front});
  return $rv if $rv != TB_OK;
  $rv = send_clear();
  return $rv if $rv != TB_OK;
  return TB_OK;
}

sub handle_resize {    # void ($sig)
  state $sig = compile(
    _Int,
  );
  my ($signo) = $sig->(@_);
if (_WIN32) {
  return;
} #endif
  local $! = $!;
  my $payload = pack('i', $signo);
  POSIX::write($global->{resize_pipefd}[1], $payload, length($payload));
  return;
}

sub update_term_size {    # $int ()
  state $sig = compile();
  $sig->(@_);

if (_WIN32) {
  my $hOutput = $global->{ttyfd} // INVALID_HANDLE_VALUE;
  return TB_OK if $hOutput == INVALID_HANDLE_VALUE;
  my ($col, $row) = Win32::Console::_GetConsoleScreenBufferInfo($hOutput);
  unless ($col && $row) {
    $global->{last_errno} = $! = ENOTTY;
    return TB_ERR_WIN_RESIZE;
  }
  $global->{width}  = $col;
  $global->{height} = $row;
  return TB_OK;
} #endif

  my ($rv, $ioctl_errno);

  return TB_OK if $global->{ttyfd} < 0;

  my $fh = IO::File->new_from_fd($global->{ttyfd}, 'w');
  return TB_OK if !$fh;

  my $sz = pack('S4', 0, 0, 0, 0);

  # Try ioctl TIOCGWINSZ
  if (eval { require 'sys/ioctl.ph'; 1 } && ioctl($fh, &TIOCGWINSZ, $sz)) {
    my ($row, $col) = unpack('S4', $sz);
    $global->{width}  = $col;
    $global->{height} = $row;
    return TB_OK;
  }
  $ioctl_errno = 0+ $!;

  # Try >cursor(9999,9999), >u7, <u6
  $rv = update_term_size_via_esc();
  return TB_OK if $rv == TB_OK;

  $global->{last_errno} = $ioctl_errno;
  return TB_ERR_RESIZE_IOCTL;
}

sub update_term_size_via_esc {    # $int ()
  state $sig = compile();
  $sig->(@_);
if (_WIN32) {
  return TB_ERR_WIN_UNSUPPORTED;
} #endif
  my $move_and_report = "\e[9999;9999H\e[6n";

  my $write_rv = POSIX::write(
    $global->{wfd},
    $move_and_report,
    length($move_and_report),
  );
  return TB_ERR_RESIZE_WRITE
    if !defined($write_rv) 
    || $write_rv != length($move_and_report);

  my $rin = '';
  vec($rin, $global->{rfd}, 1) = 1;

  my $timeout = TB_RESIZE_FALLBACK_MS / 1000;
  my $select_rv = select($rin, undef, undef, $timeout);
  if ($select_rv != 1) {
    $global->{last_errno} = 0+ $!;
    return TB_ERR_RESIZE_POLL;
  }

  my $buf = '';
  my $read_rv = POSIX::read($global->{rfd}, $buf, TB_OPT_READ_BUF) // -1;
  if ($read_rv < 1) {
    $global->{last_errno} = 0+ $!;
    return TB_ERR_RESIZE_READ;
  }

  if ($buf !~ /\e\[(\d+);(\d+)R/) {
    return TB_ERR_RESIZE_SSCANF;
  }
  my ($rh, $rw) = ($1, $2);

  $global->{width}  = $rw;
  $global->{height} = $rh;
  return TB_OK;
}

#
# Escape-cap parser helpers
#

sub init_cap_trie {    # $int ()
  state $sig = compile();
  $sig->(@_);

  my $trie = $global->{cap_trie} //= captrie->new();
  my $rv = $trie->clear();
  return $rv if $rv != TB_OK;

  my $builtin_mod_caps = eval {
    no warnings 'once';
    require Termbox::PP::Terminfo::Builtin;
    \%Termbox::PP::Terminfo::Builtin::builtin_mod_caps; 
  } or return TB_ERR;

  # Add caps from terminfo or built-in
  # Collisions are expected as some terminfo entries have dupes. (For
  # example, att605-pc collides on TB_CAP_F4 and TB_CAP_DELETE.) First cap
  # in TB_CAP_* index order will win.
  #
  # TODO: Reorder TB_CAP_* so more critical caps come first.
  for my $i (0 .. TB_CAP__COUNT_KEYS - 1) {
    $rv = $trie->add($global->{caps}[$i], tb_key_i($i), 0);
    return $rv if $rv != TB_OK && $rv != TB_ERR_CAP_COLLISION;
  }

  # Add built-in mod caps
  #
  # Collisions are OK here as well. This can happen if $global->{caps} collides
  # with builtin_mod_caps. It is desirable to give precedence to $global->{caps}
  # here.
  while (my ($cap, $entry) = each %$builtin_mod_caps) {
    my $key = $entry->{key} // next;
    my $mod = $entry->{mod} // next;
    $rv = $trie->add($cap, $key, $mod);
    return $rv if $rv != TB_OK && $rv != TB_ERR_CAP_COLLISION;
  }

  return TB_OK;
}

sub cap_trie_add {    # $int ($cap|undef, $key, $mod)
  state $sig = compile(
    _Maybe[_Str],
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($cap, $key, $mod) = $sig->(@_);
  my $trie = $global->{cap_trie} or return TB_ERR;
  return $trie->add($cap, $key, $mod);
}

# Returns a hash-ref node in $$last with {is_leaf,key,mod,nchildren,cap}.
sub cap_trie_find {    # $int ($buf|undef, $nbuf, \$last, \$depth)
  state $sig = compile(
    _Maybe[_Str],
    _PositiveOrZeroInt,
    _Ref,
    _ScalarRef,
  );
  my ($buf, $nbuf, $last, $depth) = $sig->(@_);
  my $trie = $global->{cap_trie} or return TB_ERR;
  return $trie->find($buf, $last, $depth);    # Perl does not need nbuf
}

sub cap_trie_deinit {    # $int ($node)
  state $sig = compile(
    _Object,
  );
  my ($node) = $sig->(@_);
  return $node->clear();
}

#
# Event extraction helpers
#

sub wait_event {    # $int ($event, $timeout)
  state $sig = compile(
    _Object,
    _Int,
  );
  my ($event, $timeout) = $sig->(@_);

  my $rv;
  my $buf = '';
  state $empty_event = Termbox::Event->new();

  %$event = %$empty_event;

  # Fast path: buffered input already yields a full event
  $rv = extract_event($event);
  return TB_OK if $rv == TB_OK;

if (_WIN32) {
  # Get console input handle for WaitForSingleObject() and ReadConsoleInputW()
  my $hInput = $global->{rfd} // INVALID_HANDLE_VALUE;
  if ($hInput == INVALID_HANDLE_VALUE) {
    $^E = ERROR_INVALID_HANDLE;
    $global->{last_errno} = $! = EBADF;
    return TB_ERR_POLL;
  }

  # Poll timeout tracking
  my $start = Time::HiRes::time();

  # Undefined on the first iteration, defined after the first wait attempt
  my $wait_time;

  # Preserve a pending UTF-16 high surrogate across poll calls
  state $pending_high_surrogate;

  while (1) {
    # Compute remaining wait time for WaitForSingleObject()
    if ($timeout < 0) {
      $wait_time = INFINITE;
    } elsif ($timeout == 0) {
      # Allow only a single non-blocking poll attempt
      return TB_ERR_NO_EVENT if defined $wait_time;
      $wait_time = 0;
    } else {
      my $elapsed = int((Time::HiRes::time() - $start) * 1000);
      # Allow at least one wait attempt for positive timeouts
      return TB_ERR_NO_EVENT if defined $wait_time && $elapsed >= $timeout;
      $wait_time = $timeout - $elapsed;
    }

    # Use WaitForSingleObject() to wait for console input events
    $rv = WaitForSingleObject($hInput, $wait_time);
    if ($rv == WAIT_TIMEOUT) {
      $global->{last_errno} = $! = 0;
      return TB_ERR_NO_EVENT;
    }
    elsif ($rv != WAIT_OBJECT_0) {
      my $err = 0+ $^E;
      if    ($err == ERROR_INVALID_HANDLE) { $! = EBADF  }
      elsif ($err == ERROR_ACCESS_DENIED)  { $! = EACCES }
      else                                 { $! = EINVAL }
      $global->{last_errno} = 0+ $!;
      return TB_ERR_POLL;
    }

    # Indicates whether at least one relevant input record was processed
    my $dispatched = 0;

    # Read wide input records from the console because higher-level console
    # I/O is still not reliable for full Unicode input handling.
    $^E = 0;
    my $nevent = Win32::Console::_GetNumberOfConsoleInputEvents($hInput);
    if ($^E) {
      $global->{last_errno} = $! = EIO;
      return TB_ERR_POLL;
    }
    while ($nevent--) {
      my @ir = ReadConsoleInputW($hInput);

      # Skip null events
      next unless @ir;

      if ($ir[wEventType] == KEY_EVENT) {
        # Discard key-up events unless Windows reports pasted text through 
        # VK_MENU.
        next 
          unless $ir[bKeyDown]
          || ($ir[wVirtualKeyCode] == VK_MENU && $ir[UnicodeChar]);

        # Discard pure modifier/lock key events only if they do not carry text
        next if !$ir[UnicodeChar] && (
             $ir[wVirtualKeyCode] == VK_SHIFT
          || $ir[wVirtualKeyCode] == VK_CONTROL
          || $ir[wVirtualKeyCode] == VK_MENU
          || $ir[wVirtualKeyCode] == VK_CAPITAL
          || $ir[wVirtualKeyCode] == VK_NUMLOCK
          || $ir[wVirtualKeyCode] == VK_SCROLL
          );

        while ($ir[wRepeatCount]--) {
          my $wc = $ir[UnicodeChar];

          # Skip null characters
          next if !$wc;

          # High surrogate
          if ($wc >= 0xD800 && $wc <= 0xDBFF) {
            $pending_high_surrogate = $wc;
            next;
          }

          # Low surrogate
          if ($wc >= 0xDC00 && $wc <= 0xDFFF) {
            if (defined $pending_high_surrogate) {
              my $high = $pending_high_surrogate;
              $pending_high_surrogate = undef;
              # combine surrogate pair to get the codepoint
              my $codepoint =
                0x10000 + (($high - 0xD800) << 10) + ($wc - 0xDC00);
              my $ch = chr($codepoint);
              utf8::encode($ch);
              bytebuf_nputs(\$global->{inbuf}, $ch, length($ch));
              $dispatched = 1;
              next;
            }

            # Ignore dangling low surrogates
            next;
          }

          # Drop a previously pending high surrogate if a non-low-surrogate 
          # arrives
          $pending_high_surrogate = undef;

          # Normal BMP character
          my $ch = chr($wc);
          utf8::encode($ch);
          bytebuf_nputs(\$global->{inbuf}, $ch, length($ch));
          $dispatched = 1;
        }
      }
      elsif ($ir[wEventType] == WINDOW_BUFFER_SIZE_EVENT) {
        my $w = $global->{width};
        my $h = $global->{height};

        $rv = update_term_size();
        return $rv if $rv != TB_OK;

        # Only dispatch a resize event if the size actually changed
        next if $w == $global->{width} && $h == $global->{height};

        $rv = resize_cellbufs();
        return $rv if $rv != TB_OK;

        $event->{type} = TB_EVENT_RESIZE;
        $event->{w}    = $global->{width};
        $event->{h}    = $global->{height};

        # Reset any pending high surrogate since the resize event is dispatched
        $pending_high_surrogate = undef;
        $dispatched = 1;
        return TB_OK;
      }
      else {
        # MOUSE_EVENT, FOCUS_EVENT, MENU_EVENT are ignored explicitly
        next;
      }
    }

    # No relevant input was dispatched, continue polling
    next unless $dispatched;
  
    %$event = %$empty_event;
    $rv = extract_event($event);
    return TB_OK if $rv == TB_OK;

  } #/ while (1);

  return $rv;
} #endif

  my $rfd      = $global->{rfd};
  my $resizefd = $global->{resize_pipefd}[0];

  # Perl select timeout is seconds as float; undef means block forever
  my $timeout_sec = ($timeout < 0) ? undef : ($timeout / 1000);

  do {
    my $rin = '';
    vec($rin, $rfd,      1) = 1;
    vec($rin, $resizefd, 1) = 1;

    my $rout = $rin;

    my $select_rv = select($rout, undef, undef, $timeout_sec);

    if ($select_rv < 0) {
      # Let EINTR/EAGAIN bubble up
      $global->{last_errno} = 0+ $!;
      return TB_ERR_POLL;
    }
    if ($select_rv == 0) {
      return TB_ERR_NO_EVENT;
    }

    my $tty_has_events    = vec($rout, $rfd,      1);
    my $resize_has_events = vec($rout, $resizefd, 1);

    if ($tty_has_events) {
      my $buf = '';
      my $read_rv = POSIX::read($rfd, $buf, TB_OPT_READ_BUF) // -1;
      if ($read_rv < 0) {
        $global->{last_errno} = 0+ $!;
        return TB_ERR_READ;
      } elsif ($read_rv > 0) {
        bytebuf_nputs(\$global->{inbuf}, $buf, $read_rv);
      }
    }

    if ($resize_has_events) {
      my $ignore = pack('i', 0);
      POSIX::read($resizefd, $ignore, length($ignore));
      # TODO: Harden against errors encountered mid-resize
      $rv = update_term_size();
      return $rv if $rv != TB_OK;
      $rv = resize_cellbufs();
      return $rv if $rv != TB_OK;

      $event->{type} = TB_EVENT_RESIZE;
      $event->{w}    = $global->{width};
      $event->{h}    = $global->{height};
      return TB_OK;
    }

    # Try to extract an event after consuming input / handling resize
    %$event = %$empty_event;
    $rv = extract_event($event);
    return TB_OK if $rv == TB_OK;

  } while ($timeout < 0);

  return $rv;
}

sub extract_event {    # $int ($event)
  state $sig = compile(
    _Object,
  );
  my ($event) = $sig->(@_);
  my $trie = $global->{cap_trie};
  alias: for my $in ($global->{inbuf}) {

  return TB_ERR unless length($in);

  use bytes;
  my $b0 = substr($in, 0, 1);
  if ($b0 eq "\e") {
    # Escape sequence?
    # In TB_INPUT_ESC, skip if the buffer is a single escape char
    unless (($global->{input_mode} & TB_INPUT_ESC) && length($in) == 1) {
      my $rv = extract_esc($event);
      return $rv if $rv == TB_OK || $rv == TB_ERR_NEED_MORE;
    }

    # Escape key?
    if ($global->{input_mode} & TB_INPUT_ESC) {
      $event->{type} = TB_EVENT_KEY;
      $event->{ch} = 0;
      $event->{key} = TB_KEY_ESC;
      $event->{mod} = 0;
      substr($in, 0, 1, '');
      return TB_OK;
    }

    # Recurse for alt key
    $event->{mod} |= TB_MOD_ALT;
    substr($in, 0, 1, '');
    return extract_event($event);
  }

  # ASCII control key?
  my $is_ctrl = ord($b0) < TB_KEY_SPACE || ord($b0) == TB_KEY_BACKSPACE2;
  if ($is_ctrl) {
    $event->{type} = TB_EVENT_KEY;
    $event->{ch} = 0;
    $event->{key} = ord($in);
    $event->{mod} |= TB_MOD_CTRL;
    substr($in, 0, 1, '');
    return TB_OK;
  }

  # UTF-8?
  my $need = tb_utf8_char_length($b0);
  if (length($in) >= $need) {
    $event->{type} = TB_EVENT_KEY;
    tb_utf8_char_to_unicode(\$event->{ch}, $in);
    $event->{key} = 0;
    substr($in, 0, $need, '');
    return TB_OK;
  }

  # Need more input
  return TB_ERR
  } #/ alias:
}

sub extract_esc {    # $int ($event)
  state $sig = compile(
    _Object,
  );
  my ($event) = $sig->(@_);

  my $rv;

  $rv = extract_esc_user($event, 0);
  return $rv if $rv == TB_OK || $rv == TB_ERR_NEED_MORE;

  $rv = extract_esc_cap($event);
  return $rv if $rv == TB_OK || $rv == TB_ERR_NEED_MORE;

  $rv = extract_esc_mouse($event);
  return $rv if $rv == TB_OK || $rv == TB_ERR_NEED_MORE;

  $rv = extract_esc_user($event, 1);
  return $rv if $rv == TB_OK || $rv == TB_ERR_NEED_MORE;

  return TB_ERR;
}

sub extract_esc_user {    # $int ($event, $is_post)
  state $sig = compile(
    _Object,
    _Bool,
  );
  my ($event, $is_post) = $sig->(@_);

  my $fn = $is_post ? $global->{fn_extract_esc_post}
                    : $global->{fn_extract_esc_pre};
  return TB_ERR unless ref($fn) eq 'CODE';

  my $consumed = 0;
  my $rv = $fn->($event, \$consumed);

  if ($rv == TB_OK) {
    bytebuf_shift(\$global->{inbuf}, $consumed);
  }

  return $rv if $rv == TB_OK || $rv == TB_ERR_NEED_MORE;
  return TB_ERR;
}

sub extract_esc_mouse {    # $int ($event)
  state $sig = compile(
    _Object,
  );
  my ($event) = $sig->(@_);

  use bytes;
  alias: for my $in ($global->{inbuf}) {
  my @in = unpack('C*', $in);

  # Bail if not enough to determine type
  if (@in < 2) {
    return TB_ERR_NEED_MORE;
  } elsif ($in[1] != ord('[')) {
    return TB_ERR;
  } elsif (@in < 3) {
    return TB_ERR_NEED_MORE;
  }

  # Discern type of mouse event from 3rd byte
  my $type = TYPE_VT200;
  if ($in[2] == ord('M')) {
    # X10 mouse encoding, the simplest one: \x1b [ M Cb Cx Cy
    $type = TYPE_VT200;
  }
  elsif ($in[2] == ord('<')) {
    # xterm 1006 extended mode or urxvt 1015 extended mode
    # xterm: \x1b [ < Cb ; Cx ; Cy (M or m)
    $type = TYPE_1006;
  }
  else {
    # urxvt: \x1b [ Cb ; Cx ; Cy M
    $type = TYPE_1015;
  }

  my $buf_shift = 0;

  switch_parse: for ($type) {
    case: TYPE_VT200 == $_ and do {
      # In this mode, we need 6 bytes
      return TB_ERR_NEED_MORE if @in < 6;

      my $b = $in[3] - 0x20;

      local $_;
      switch: for ($b & 3) {
        case: 0 == $_ and do {
          $event->{key} = ($b & 64) ? TB_KEY_MOUSE_WHEEL_UP
                                    : TB_KEY_MOUSE_LEFT;
          last;
        };
        case: 1 == $_ and do {
          $event->{key} = ($b & 64) ? TB_KEY_MOUSE_WHEEL_DOWN
                                    : TB_KEY_MOUSE_MIDDLE;
          last;
        };
        case: 2 == $_ and do {
          $event->{key} = TB_KEY_MOUSE_RIGHT;
          last;
        };
        case: 3 == $_ and do {
          $event->{key} = TB_KEY_MOUSE_RELEASE;
          last;
        };
        default: {
          return TB_ERR;
        };
      }

      if (($b & 32) != 0) {
        $event->{mod} |= TB_MOD_MOTION;
      }

      # The coord is 1,1 for upper left
      $event->{x} = $in[4] - 0x21;
      $event->{y} = $in[5] - 0x21;

      # Eat 6 bytes
      $buf_shift = 6;
      last;
    };

    case: TYPE_1006 == $_ ||    # fallthrough
          TYPE_1015 == $_
    and do {
      my @num = (-1, -1, -1);
      my $num_i = 0;
      my $cur_num = -1;
      my $trail = ord(' ');

      my $i = 2;
      ++$i if $type == TYPE_1006;    # skip '<'

      # Parse %d;%d;%d[mM] into @num
      while ($i < @in && $num_i < 3) {
        my $c = $in[$i];

        if ($c >= ord('0') && $c <= ord('9')) {
          # Digit
          $cur_num = 0 if $cur_num == -1;
          $cur_num *= 10;
          $cur_num += $c - ord('0');
          ++$i;
          next;
        }

        if ($cur_num != -1
          && (($num_i < 2 && $c == ord(';'))
            || ($num_i == 2 && ($c == ord('m') || $c == ord('M')))))
        {
          # We're at a semi-colon, 'm', or 'M' and we have a number
          $num[$num_i] = $cur_num;
          ++$num_i;
          $cur_num = -1;
          $trail = $c;
          ++$i;
          next;
        }

        # Something else; not a mouse event
        return TB_ERR;
      }

      # If we didn't get to the 3rd number, we need more
      return TB_ERR_NEED_MORE if $num[2] == -1;

      # We have a valid mouse event, eat i bytes from the buffer
      $buf_shift = $i;

      $num[0] -= 0x20 if $type == TYPE_1015;

      local $_;
      switch: for ($num[0] & 3) {
        case: 0 == $_ and do {
          $event->{key} = ($num[0] & 64) ? TB_KEY_MOUSE_WHEEL_UP
                                         : TB_KEY_MOUSE_LEFT;
          last;
        };
        case: 1 == $_ and do {
          $event->{key} = ($num[0] & 64) ? TB_KEY_MOUSE_WHEEL_DOWN
                                         : TB_KEY_MOUSE_MIDDLE;
          last;
        };
        case: 2 == $_ and do {
          $event->{key} = TB_KEY_MOUSE_RIGHT;
          last;
        };
        case: 3 == $_ and do {
          $event->{key} = TB_KEY_MOUSE_RELEASE;
          last;
        };
        default: {
          return TB_ERR;
        };
      }

      # On xterm mouse release is signaled by lowercase m
      if ($trail == ord('m')) {
        $event->{key} = TB_KEY_MOUSE_RELEASE;
      }

      if (($num[0] & 32) != 0) {
        $event->{mod} |= TB_MOD_MOTION;
      }

      $event->{x} = ($num[1] - 1 < 0) ? 0 : $num[1] - 1;
      $event->{y} = ($num[2] - 1 < 0) ? 0 : $num[2] - 1;
      last;
    };
  }

  substr($in, 0, $buf_shift, '') if $buf_shift > 0;

  $event->{type} = TB_EVENT_MOUSE;

  return TB_OK;
  } #/ alias:
}

sub extract_esc_cap {    # $int ($event)
  state $sig = compile(
    _Object,
  );
  my ($event) = $sig->(@_);
  my $trie = $global->{cap_trie};
  alias: for my $in ($global->{inbuf}) {
  my $node;
  my $depth;

  my $rv = $trie->find($in, \$node, \$depth);
  return $rv if $rv != TB_OK;

  if ($node->{is_leaf}) {
    # Found a leaf node
    $event->{type} = TB_EVENT_KEY;
    $event->{ch}  = 0;
    $event->{key} = $node->{key};
    $event->{mod} = $node->{mod};
    substr($in, 0, $depth, '');
    return TB_OK;
  }
  elsif ($node->{nchildren} > 0 && length($in) <= $depth) {
    # Found a branch node (not enough input)
    return TB_ERR_NEED_MORE;
  }

  return TB_ERR;
  } #/ alias:
}

#
# Cell related helpers
#

sub cell_cmp {    # $int ($a, $b)
  state $sig = compile(
    _Object,
    _Object,
  );
  my ($a, $b) = $sig->(@_);
  return $a->equal($b) ? 0 : 1;
}

sub cell_copy {    # $int ($dst, $src)
  goto &Termbox::Cell::copy;
}

sub cell_set {    # $int ($cell, \@ch, $nch, $fg, $bg)
  state $sig = compile(
    _Object,
    _ArrayRef,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($cell, $ch, $nch, $fg, $bg) = $sig->(@_);
  return $cell->set(pack('U*', @$ch), $fg, $bg);
}

sub cell_reserve_ech {    # $int ($cell, $n)
  state $sig = compile(
    _Object,
    _PositiveOrZeroInt,
  );
  my ($cell, $n) = $sig->(@_);
  return TB_OPT_EGC ? TB_OK : TB_ERR;
}

sub cell_free {    # $int ($cell)
  state $sig = compile(
    _Object,
  );
  my ($cell) = $sig->(@_);
  $cell->[0] = "\0";    # ch
  $cell->[1] = 0;       # fg
  $cell->[2] = 0;       # bg
  return TB_OK;
}

#
# Cell buffer related helpers
#

sub init_cellbuf {    # $int ()
  state $sig = compile();
  $sig->(@_);
  my $rv;

  $global->{back}  ||= cellbuf->new();
  $global->{front} ||= cellbuf->new();

  $rv = $global->{back}->init($global->{width}, $global->{height});
  return $rv if $rv != TB_OK;
  $rv = $global->{front}->init($global->{width}, $global->{height});
  return $rv if $rv != TB_OK;
  $rv = $global->{back}->clear();
  return $rv if $rv != TB_OK;
  $rv = $global->{front}->clear();
  return $rv if $rv != TB_OK;

  return TB_OK;
}

sub cellbuf_init {    # $int ($c, $w, $h)
  goto &cellbuf::init;
}

sub cellbuf_free {    # $int ($c)
  state $sig = compile(
    _Object,
  );
  my ($c) = $sig->(@_);
  for my $cell (@{ $c->{cells} || [] }) {
    my $rv = cell_free($cell);
    return $rv if $rv != TB_OK;
  }

  $c->{width} = 0;
  $c->{height} = 0;
  $c->{cells} = [];
  return TB_OK;
}

sub cellbuf_clear {    # $int ($c)
  goto &cellbuf::clear;
}

sub cellbuf_get {    # $int ($c, $x, $y, \$out)
  state $sig = compile(
    _Object,
    _Int,
    _Int,
    _Ref,
  );
  my ($c, $x, $y, $out) = $sig->(@_);
  return TB_ERR_OUT_OF_BOUNDS unless $c->in_bounds($x, $y);
  $$out = $c->get($x, $y);
  return defined $$out ? TB_OK : TB_ERR;
}

sub cellbuf_in_bounds {    # $int ($c, $x, $y)
  goto &cellbuf::in_bounds;
}

sub cellbuf_resize {    # $int ($c, $w, $h)
  goto &cellbuf::resize;
}

#
# Sending output helpers
#

sub send_literal {   # $int ($rv, $a)
  state $sig = compile(
    _Maybe[_Int],
    _Str,
  );
  my ($rv, $a) = $sig->(@_);
  alias: for $rv ($_[0]) {
  $global->{outbuf} .= $a;
  return $rv = TB_OK;
  } #/ alias:
}

sub send_num {   # $int ($rv, \$buf, $n)
  state $sig = compile(
    _Maybe[_Int],
    _ScalarRef,
    _PositiveOrZeroInt,
  );
  my ($rv, $buf, $n) = $sig->(@_);
  alias: for $rv ($_[0]) {
  $global->{outbuf} .= sprintf('%u', $n);
  return $rv = TB_OK;
  } #/ alias:
}

sub send_init_escape_codes {   # $int ()
  state $sig = compile();
  $sig->(@_);
  my $rv;
  $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_ENTER_CA]);
  return $rv if $rv != TB_OK;
  $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_ENTER_KEYPAD]);
  return $rv if $rv != TB_OK;
  $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_HIDE_CURSOR]);
  return $rv if $rv != TB_OK;
  return TB_OK;
}

sub send_clear {   # $int ()
  state $sig = compile();
  $sig->(@_);
  my $rv;

  $rv = send_attr($global->{fg}, $global->{bg});
  return $rv if $rv != TB_OK;
  $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_CLEAR_SCREEN]);
  return $rv if $rv != TB_OK;

  $rv = send_cursor_if($global->{cursor_x}, $global->{cursor_y});
  return $rv if $rv != TB_OK;
  $rv = bytebuf_flush(\$global->{outbuf}, $global->{wfd});
  return $rv if $rv != TB_OK;

  $global->{last_x} = -1;
  $global->{last_y} = -1;

  return TB_OK;
}

sub send_attr {    # $int ($fg, $bg)
  state $sig = compile(
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
  );
  my ($fg, $bg) = $sig->(@_);
  my $rv;

  if ($fg == $global->{last_fg} && $bg == $global->{last_bg}) {
    return TB_OK;
  }

  $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_SGR0]);
  return $rv if $rv != TB_OK;

  my ($cfg, $cbg);
  switch: for ($global->{output_mode}) {
    DEFAULT: do {};
    case: TB_OUTPUT_NORMAL == $_ and do {
      # The minus 1 below is because our colors are 1-indexed starting
      # from black. Black is represented by a 30, 40, 90, or 100 for fg,
      # bg, bright fg, or bright bg respectively. Red is 31, 41, 91,
      # 101, etc.
      $cfg = ($fg & TB_BRIGHT ? 90 : 30) + ($fg & 0x0f) - 1;
      $cbg = ($bg & TB_BRIGHT ? 100 : 40) + ($bg & 0x0f) - 1;
      last;
    };
    case: TB_OUTPUT_256 == $_ and do {
      $cfg = $fg & 0xff;
      $cbg = $bg & 0xff;
      $cfg = 0 if $fg & TB_HI_BLACK;
      $cbg = 0 if $bg & TB_HI_BLACK;
      last;
    };
    case: TB_OUTPUT_216 == $_ and do {
      $cfg = $fg & 0xff;
      $cbg = $bg & 0xff;
      $cfg = 216 if $cfg > 216;
      $cbg = 216 if $cbg > 216;
      $cfg += 0x0f;
      $cbg += 0x0f;
      last;
    };
    case: TB_OUTPUT_GRAYSCALE == $_ and do {
      $cfg = $fg & 0xff;
      $cbg = $bg & 0xff;
      $cfg = 24 if $cfg > 24;
      $cbg = 24 if $cbg > 24;
      $cfg += 0xe7;
      $cbg += 0xe7;
      last;
    };
if (TB_OPT_ATTR_W >= 32) {
    case: TB_OUTPUT_TRUECOLOR() == $_ and do {
      $cfg = $fg & 0xffffff;
      $cbg = $bg & 0xffffff;
      $cfg = 0 if $fg & TB_HI_BLACK;
      $cbg = 0 if $bg & TB_HI_BLACK;
      last;
    };
} # endif
    default: {
      $_ = TB_OUTPUT_NORMAL;
      goto DEFAULT;
    };
  }

  if ($fg & TB_BOLD) {
    $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_BOLD]);
    return $rv if $rv != TB_OK;
  }
  if ($fg & TB_BLINK) {
    $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_BLINK]);
    return $rv if $rv != TB_OK;
  }
  if ($fg & TB_UNDERLINE) {
    $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_UNDERLINE]);
    return $rv if $rv != TB_OK;
  }
  if ($fg & TB_ITALIC) {
    $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_ITALIC]);
    return $rv if $rv != TB_OK;
  }
  if ($fg & TB_DIM) {
    $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_DIM]);
    return $rv if $rv != TB_OK;
  }
if (TB_OPT_ATTR_W == 64) {
    if ($fg & TB_STRIKEOUT) {
      $rv = bytebuf_puts(\$global->{outbuf}, 
        $global->{caps}[TB_HARDCAP_STRIKEOUT]);
      return $rv if $rv != TB_OK;
    }
    if ($fg & TB_UNDERLINE_2) {
      $rv = bytebuf_puts(\$global->{outbuf}, 
        $global->{caps}[TB_HARDCAP_UNDERLINE_2]);
      return $rv if $rv != TB_OK;
    }
    if ($fg & TB_OVERLINE) {
      $rv = bytebuf_puts(\$global->{outbuf}, 
        $global->{caps}[TB_HARDCAP_OVERLINE]);
      return $rv if $rv != TB_OK;
    }
    if ($fg & TB_INVISIBLE) {
      $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_INVISIBLE]);
      return $rv if $rv != TB_OK;
    }
} #endif

  if (($fg & TB_REVERSE) || ($bg & TB_REVERSE)) {
    $rv = bytebuf_puts(\$global->{outbuf}, $global->{caps}[TB_CAP_REVERSE]);
    return $rv if $rv != TB_OK;
  }
  my $fg_is_default = ($fg & 0xff) == 0;
  my $bg_is_default = ($bg & 0xff) == 0;
  if ($global->{output_mode} == TB_OUTPUT_256) {
    $fg_is_default = 0 if $fg & TB_HI_BLACK;
    $bg_is_default = 0 if $bg & TB_HI_BLACK;
  }
if (TB_OPT_ATTR_W >= 32) {
    if ($global->{output_mode} == TB_OUTPUT_TRUECOLOR) {
      $fg_is_default = (($fg & 0xffffff) == 0) && (($fg & TB_HI_BLACK) == 0);
      $bg_is_default = (($bg & 0xffffff) == 0) && (($bg & TB_HI_BLACK) == 0);
    }
} #endif

  $rv = send_sgr($cfg, $cbg, $fg_is_default, $bg_is_default);
  return $rv if $rv != TB_OK;

  $global->{last_fg} = $fg;
  $global->{last_bg} = $bg;

  return TB_OK;
}

sub send_sgr {    # $int ($cfg, $cbg, $fg_is_default, $bg_is_default)
  state $sig = compile(
    _PositiveOrZeroInt,
    _PositiveOrZeroInt,
    _Bool,
    _Bool,
  );
  my ($cfg, $cbg, $fg_is_default, $bg_is_default) = $sig->(@_);
  my $rv;
  my $nbuf = '';

  return TB_OK if $fg_is_default && $bg_is_default;

  switch: for ($global->{output_mode}) {
    DEFAULT: do {};
    case: TB_OUTPUT_NORMAL == $_ and do {
      send_literal($rv, "\x1b[")                    == TB_OK or return $rv;
      if (!$fg_is_default) {
        send_num($rv, \$nbuf, $cfg)                 == TB_OK or return $rv;
        if (!$bg_is_default) {
          send_literal($rv, ";")                    == TB_OK or return $rv;
        }
      }
      if (!$bg_is_default) {
        send_num($rv, \$nbuf, $cbg)                 == TB_OK or return $rv;
      }
      send_literal($rv, "m")                        == TB_OK or return $rv;
      last;
    };
    case: TB_OUTPUT_256       == $_ ||
          TB_OUTPUT_216       == $_ ||
          TB_OUTPUT_GRAYSCALE == $_
    and do {
      send_literal($rv, "\x1b[")                    == TB_OK or return $rv;
      if (!$fg_is_default) {
        send_literal($rv, "38;5;")                  == TB_OK or return $rv;
        send_num($rv, \$nbuf, $cfg)                 == TB_OK or return $rv;
        if (!$bg_is_default) {
          send_literal($rv, ";")                    == TB_OK or return $rv;
        }
      }
      if (!$bg_is_default) {
        send_literal($rv, "48;5;")                  == TB_OK or return $rv;
        send_num($rv, \$nbuf, $cbg)                 == TB_OK or return $rv;
      }
      send_literal($rv, "m")                        == TB_OK or return $rv;
      last;
    };
if (TB_OPT_ATTR_W >= 32) {
    case: TB_OUTPUT_TRUECOLOR() == $_ and do {
      send_literal($rv, "\x1b[")                    == TB_OK or return $rv;
      if (!$fg_is_default) {
        send_literal($rv, "38;2;")                  == TB_OK or return $rv;
        send_num($rv, \$nbuf, ($cfg >> 16) & 0xff)  == TB_OK or return $rv;
        send_literal($rv, ";")                      == TB_OK or return $rv;
        send_num($rv, \$nbuf, ($cfg >> 8) & 0xff)   == TB_OK or return $rv;
        send_literal($rv, ";")                      == TB_OK or return $rv;
        send_num($rv, \$nbuf, $cfg & 0xff)          == TB_OK or return $rv;
        if (!$bg_is_default) {
          send_literal($rv, ";")                    == TB_OK or return $rv;
        }
      }
      if (!$bg_is_default) {
        send_literal($rv, "48;2;")                  == TB_OK or return $rv;
        send_num($rv, \$nbuf, ($cbg >> 16) & 0xff)  == TB_OK or return $rv;
        send_literal($rv, ";")                      == TB_OK or return $rv;
        send_num($rv, \$nbuf, ($cbg >> 8) & 0xff)   == TB_OK or return $rv;
        send_literal($rv, ";")                      == TB_OK or return $rv;
        send_num($rv, \$nbuf, $cbg & 0xff)          == TB_OK or return $rv;
      }
      send_literal($rv, "m")                        == TB_OK or return $rv;
      last;
    };
} #endif
    default: {
      $_ = TB_OUTPUT_NORMAL;
      goto DEFAULT;
    };
  }
  return TB_OK;
}

sub send_cursor_if {    # $int ($x, $y)
  state $sig = compile(
    _Int,
    _Int,
  );
  my ($x, $y) = $sig->(@_);
  my $rv;
  my $nbuf = '';
  return TB_OK if $x < 0 || $y < 0;
  send_literal($rv, "\x1b[")                        == TB_OK or return $rv;
  send_num($rv, \$nbuf, $y + 1)                     == TB_OK or return $rv;
  send_literal($rv, ";")                            == TB_OK or return $rv;
  send_num($rv, \$nbuf, $x + 1)                     == TB_OK or return $rv;
  send_literal($rv, "H")                            == TB_OK or return $rv;
  return TB_OK;
}

sub send_char {    # $int ($x, $y, $ch)
  state $sig = compile(
    _Int,
    _Int,
    _PositiveOrZeroInt,
  );
  my ($x, $y, $ch) = $sig->(@_);
  return send_cluster($x, $y, [$ch], 1);
}

sub send_cluster {    # $int ($x, $y, \@ch, $nch)
  state $sig = compile(
    _Int,
    _Int,
    _ArrayRef,
    _PositiveOrZeroInt,
  );
  my ($x, $y, $ch, $nch) = $sig->(@_);

  if ($global->{last_x} != $x - 1 || $global->{last_y} != $y) {
    my $rv = send_cursor_if($x, $y);
    return $rv if $rv != TB_OK;
  }
  $global->{last_x} = $x;
  $global->{last_y} = $y;

  foreach my $ch32 (@$ch) {
    if (!tb_iswprint_ex($ch32, undef)) {
      $ch32 = 0xfffd;    # replace non-printable codepoints with U+FFFD
    }
    my $cu8_len = tb_utf8_unicode_to_char(\my $chu8, $ch32);
    my $rv = bytebuf_nputs(\$global->{outbuf}, $chu8, $cu8_len);
    return $rv if $rv != TB_OK;
  }

  return TB_OK;
}

sub convert_num {    # $len ($num, \$buf)
  state $sig = compile(
    _PositiveOrZeroInt,
    _ScalarRef,
  );
  my ($num, $buf) = $sig->(@_);
  $$buf = sprintf('%u', $num);
  return bytes::length($$buf);
}

#
# Byte buffer related helpers
#

sub bytebuf_puts {    # $int (\$buf, $str)
  state $sig = compile(
    _ScalarRef,
    _Str,
  );
  my ($b, $str) = $sig->(@_);
  # Nothing to do for empty caps
  $$b .= $str if bytes::length($str);
  return TB_OK
}

sub bytebuf_nputs {    # $int (\$buf, $str, $nstr)
  state $sig = compile(
    _ScalarRef,
    _Str,
    _PositiveOrZeroInt,
  );
  my ($b, $str, $nstr) = $sig->(@_);
  $$b .= bytes::substr($str, 0, $nstr);
  return TB_OK;
}

sub bytebuf_shift {    # $int (\$buf, $n)
  state $sig = compile(
    _ScalarRef,
    _PositiveOrZeroInt,
  );
  my ($b, $n) = $sig->(@_);
  use bytes;
  $n = length($$b) if $n > length($$b);
  substr($$b, 0, $n, '');
  return TB_OK;
}

sub bytebuf_flush {    # $int (\$buf, $fd)
  state $sig = compile(
    _ScalarRef,
    _Int,
  );
  my ($b, $fd) = $sig->(@_);
  use bytes;
  return TB_OK unless length($$b);
  my $want = length($$b);
  my $wrote;
if (_WIN32) {
  my $hFile = $fd // INVALID_HANDLE_VALUE;
  if (!Win32API::File::WriteFile($hFile, $$b, $want, $wrote, [])) {
    my $err = 0+ $^E;
    if    ($err == ERROR_INVALID_HANDLE)    { $! = EBADF  }
    elsif ($err == ERROR_INVALID_PARAMETER) { $! = EINVAL }
    elsif ($err == ERROR_BROKEN_PIPE)       { $! = EPIPE  }
    else                                    { $! = EIO    }
  }
} else {
  $wrote = POSIX::write($fd // -1, $$b, $want) // 0;
} #endif
  # Partial writes are treated as errors
  if ($wrote != $want) {
    $global->{last_errno} = 0+ $!;
    return TB_ERR;
  }
  $$b = '';
  return TB_OK;
}

sub bytebuf_reserve {    # $int (\$buf, $sz)
  state $sig = compile(
    _ScalarRef,
    _PositiveOrZeroInt,
  );
  $sig->(@_);
  return TB_OK;
}

sub bytebuf_free {    # $int (\$buf)
  state $sig = compile(
    _ScalarRef,
  );
  my ($b) = $sig->(@_);
  $$b = '';
  return TB_OK;
}

# Hack to make 'use Termbox' work without an actual Termbox.pm file.
$INC{"Termbox.pm"} = __FILE__;
