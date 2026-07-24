# ------------------------------------------------------------------------
#
#   Termbox (Perl port)
#
#   Implementation based on termbox2 v2.7.0-dev, 8. Feb 2026
#
#   Copyright (C) 2010-2020 nsf <no.smile.face@gmail.com>
#                 2015-2026 Adam Saponara <as@php.net>
#
# ------------------------------------------------------------------------
#   Author: 2024-2026 J. Schneider
# ------------------------------------------------------------------------

package Termbox::PP::Terminfo::Builtin;

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

BEGIN {
  require Termbox::PP;
  Termbox->import(qw(
    /^TB_KEY_/
    /^TB_MOD_/
  ));
}

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Exporter 'import';

our @EXPORT_OK = qw(
  @terminfo_cap_indexes
  %builtin_terms
  @builtin_terms_orders
  %builtin_mod_caps
);

# ------------------------------------------------------------------------
# Variables --------------------------------------------------------------
# ------------------------------------------------------------------------

our @terminfo_cap_indexes = (
  66,     # kf1 (TB_CAP_F1)
  68,     # kf2 (TB_CAP_F2)
  69,     # kf3 (TB_CAP_F3)
  70,     # kf4 (TB_CAP_F4)
  71,     # kf5 (TB_CAP_F5)
  72,     # kf6 (TB_CAP_F6)
  73,     # kf7 (TB_CAP_F7)
  74,     # kf8 (TB_CAP_F8)
  75,     # kf9 (TB_CAP_F9)
  67,     # kf10 (TB_CAP_F10)
  216,    # kf11 (TB_CAP_F11)
  217,    # kf12 (TB_CAP_F12)
  77,     # kich1 (TB_CAP_INSERT)
  59,     # kdch1 (TB_CAP_DELETE)
  76,     # khome (TB_CAP_HOME)
  164,    # kend (TB_CAP_END)
  82,     # kpp (TB_CAP_PGUP)
  81,     # knp (TB_CAP_PGDN)
  87,     # kcuu1 (TB_CAP_ARROW_UP)
  61,     # kcud1 (TB_CAP_ARROW_DOWN)
  79,     # kcub1 (TB_CAP_ARROW_LEFT)
  83,     # kcuf1 (TB_CAP_ARROW_RIGHT)
  148,    # kcbt (TB_CAP_BACK_TAB)
  28,     # smcup (TB_CAP_ENTER_CA)
  40,     # rmcup (TB_CAP_EXIT_CA)
  16,     # cnorm (TB_CAP_SHOW_CURSOR)
  13,     # civis (TB_CAP_HIDE_CURSOR)
  5,      # clear (TB_CAP_CLEAR_SCREEN)
  39,     # sgr0 (TB_CAP_SGR0)
  36,     # smul (TB_CAP_UNDERLINE)
  27,     # bold (TB_CAP_BOLD)
  26,     # blink (TB_CAP_BLINK)
  311,    # sitm (TB_CAP_ITALIC)
  34,     # rev (TB_CAP_REVERSE)
  89,     # smkx (TB_CAP_ENTER_KEYPAD)
  88,     # rmkx (TB_CAP_EXIT_KEYPAD)
  30,     # dim (TB_CAP_DIM)
  32,     # invis (TB_CAP_INVISIBLE)
);

# Terminal capability tables (Escape-Sequenzen)
our %builtin_terms = (
  xterm => [
    "\eOP",                 # kf1 (TB_CAP_F1)
    "\eOQ",                 # kf2 (TB_CAP_F2)
    "\eOR",                 # kf3 (TB_CAP_F3)
    "\eOS",                 # kf4 (TB_CAP_F4)
    "\e[15~",               # kf5 (TB_CAP_F5)
    "\e[17~",               # kf6 (TB_CAP_F6)
    "\e[18~",               # kf7 (TB_CAP_F7)
    "\e[19~",               # kf8 (TB_CAP_F8)
    "\e[20~",               # kf9 (TB_CAP_F9)
    "\e[21~",               # kf10 (TB_CAP_F10)
    "\e[23~",               # kf11 (TB_CAP_F11)
    "\e[24~",               # kf12 (TB_CAP_F12)
    "\e[2~",                # insert (TB_CAP_INSERT)
    "\e[3~",                # delete (TB_CAP_DELETE)
    "\eOH",                 # home (TB_CAP_HOME)
    "\eOF",                 # end (TB_CAP_END)
    "\e[5~",                # page up (TB_CAP_PGUP)
    "\e[6~",                # page down (TB_CAP_PGDN)
    "\eOA",                 # arrow up (TB_CAP_ARROW_UP)
    "\eOB",                 # arrow down (TB_CAP_ARROW_DOWN)
    "\eOD",                 # arrow left (TB_CAP_ARROW_LEFT)
    "\eOC",                 # arrow right (TB_CAP_ARROW_RIGHT)
    "\e[Z",                 # back tab (TB_CAP_BACK_TAB)
    "\e[?1049h\e[22;0;0t",  # enter ca mode (TB_CAP_ENTER_CA)
    "\e[?1049l\e[23;0;0t",  # exit ca mode (TB_CAP_EXIT_CA)
    "\e[?12l\e[?25h",       # show cursor (TB_CAP_SHOW_CURSOR)
    "\e[?25l",              # hide cursor (TB_CAP_HIDE_CURSOR)
    "\e[H\e[2J",            # clear screen (TB_CAP_CLEAR_SCREEN)
    "\e(B\e[m",             # sgr0 (TB_CAP_SGR0)
    "\e[4m",                # underline (TB_CAP_UNDERLINE)
    "\e[1m",                # bold (TB_CAP_BOLD)
    "\e[5m",                # blink (TB_CAP_BLINK)
    "\e[3m",                # italic (TB_CAP_ITALIC)
    "\e[7m",                # reverse (TB_CAP_REVERSE)
    "\e[?1h\e=",            # enter keypad (TB_CAP_ENTER_KEYPAD)
    "\e[?1l\e>",            # exit keypad (TB_CAP_EXIT_KEYPAD)
    "\e[2m",                # dim (TB_CAP_DIM)
    "\e[8m",                # invisible (TB_CAP_INVISIBLE)
  ],
  linux => [
    "\e[[A",          # kf1 (TB_CAP_F1)
    "\e[[B",          # kf2 (TB_CAP_F2)
    "\e[[C",          # kf3 (TB_CAP_F3)
    "\e[[D",          # kf4 (TB_CAP_F4)
    "\e[[E",          # kf5 (TB_CAP_F5)
    "\e[17~",         # kf6 (TB_CAP_F6)
    "\e[18~",         # kf7 (TB_CAP_F7)
    "\e[19~",         # kf8 (TB_CAP_F8)
    "\e[20~",         # kf9 (TB_CAP_F9)
    "\e[21~",         # kf10 (TB_CAP_F10)
    "\e[23~",         # kf11 (TB_CAP_F11)
    "\e[24~",         # kf12 (TB_CAP_F12)
    "\e[2~",          # insert (TB_CAP_INSERT)
    "\e[3~",          # delete (TB_CAP_DELETE)
    "\e[1~",          # home (TB_CAP_HOME)
    "\e[4~",          # end (TB_CAP_END)
    "\e[5~",          # page up (TB_CAP_PGUP)
    "\e[6~",          # page down (TB_CAP_PGDN)
    "\e[A",           # arrow up (TB_CAP_ARROW_UP)
    "\e[B",           # arrow down (TB_CAP_ARROW_DOWN)
    "\e[D",           # arrow left (TB_CAP_ARROW_LEFT)
    "\e[C",           # arrow right (TB_CAP_ARROW_RIGHT)
    "\e\011",         # back tab (TB_CAP_BACK_TAB)
    "",               # enter ca mode (TB_CAP_ENTER_CA)
    "",               # exit ca mode (TB_CAP_EXIT_CA)
    "\e[?25h\e[?0c",  # show cursor (TB_CAP_SHOW_CURSOR)
    "\e[?25l\e[?1c",  # hide cursor (TB_CAP_HIDE_CURSOR)
    "\e[H\e[J",       # clear screen (TB_CAP_CLEAR_SCREEN)
    "\e[m\017",       # sgr0 (TB_CAP_SGR0)
    "\e[4m",          # underline (TB_CAP_UNDERLINE)
    "\e[1m",          # bold (TB_CAP_BOLD)
    "\e[5m",          # blink (TB_CAP_BLINK)
    "",               # italic (TB_CAP_ITALIC)
    "\e[7m",          # reverse (TB_CAP_REVERSE)
    "",               # enter keypad (TB_CAP_ENTER_KEYPAD)
    "",               # exit keypad (TB_CAP_EXIT_KEYPAD)
    "\e[2m",          # dim (TB_CAP_DIM)
    "",               # invisible (TB_CAP_INVISIBLE)
  ],
  screen => [
    "\eOP",           # kf1 (TB_CAP_F1)
    "\eOQ",           # kf2 (TB_CAP_F2)
    "\eOR",           # kf3 (TB_CAP_F3)
    "\eOS",           # kf4 (TB_CAP_F4)
    "\e[15~",         # kf5 (TB_CAP_F5)
    "\e[17~",         # kf6 (TB_CAP_F6)
    "\e[18~",         # kf7 (TB_CAP_F7)
    "\e[19~",         # kf8 (TB_CAP_F8)
    "\e[20~",         # kf9 (TB_CAP_F9)
    "\e[21~",         # kf10 (TB_CAP_F10)
    "\e[23~",         # kf11 (TB_CAP_F11)
    "\e[24~",         # kf12 (TB_CAP_F12)
    "\e[2~",          # insert (TB_CAP_INSERT)
    "\e[3~",          # delete (TB_CAP_DELETE)
    "\e[1~",          # home (TB_CAP_HOME)
    "\e[4~",          # end (TB_CAP_END)
    "\e[5~",          # page up (TB_CAP_PGUP)
    "\e[6~",          # page down (TB_CAP_PGDN)
    "\eOA",           # arrow up (TB_CAP_ARROW_UP)
    "\eOB",           # arrow down (TB_CAP_ARROW_DOWN)
    "\eOD",           # arrow left (TB_CAP_ARROW_LEFT)
    "\eOC",           # arrow right (TB_CAP_ARROW_RIGHT)
    "\e[Z",           # back tab (TB_CAP_BACK_TAB)
    "\e[?1049h",      # enter ca mode (TB_CAP_ENTER_CA)
    "\e[?1049l",      # exit ca mode (TB_CAP_EXIT_CA)
    "\e[34h\e[?25h",  # show cursor (TB_CAP_SHOW_CURSOR)
    "\e[?25l",        # hide cursor (TB_CAP_HIDE_CURSOR)
    "\e[H\e[J",       # clear screen (TB_CAP_CLEAR_SCREEN)
    "\e[m\017",       # sgr0 (TB_CAP_SGR0)
    "\e[4m",          # underline (TB_CAP_UNDERLINE)
    "\e[1m",          # bold (TB_CAP_BOLD)
    "\e[5m",          # blink (TB_CAP_BLINK)
    "",               # italic (TB_CAP_ITALIC)
    "\e[7m",          # reverse (TB_CAP_REVERSE)
    "\e[?1h\e=",      # enter keypad (TB_CAP_ENTER_KEYPAD)
    "\e[?1l\e>",      # exit keypad (TB_CAP_EXIT_KEYPAD)
    "\e[2m",          # dim (TB_CAP_DIM)
    "",               # invisible (TB_CAP_INVISIBLE)
  ],
  'rxvt-256color' => [
    "\e[11~",           # kf1 (TB_CAP_F1)
    "\e[12~",           # kf2 (TB_CAP_F2)
    "\e[13~",           # kf3 (TB_CAP_F3)
    "\e[14~",           # kf4 (TB_CAP_F4)
    "\e[15~",           # kf5 (TB_CAP_F5)
    "\e[17~",           # kf6 (TB_CAP_F6)
    "\e[18~",           # kf7 (TB_CAP_F7)
    "\e[19~",           # kf8 (TB_CAP_F8)
    "\e[20~",           # kf9 (TB_CAP_F9)
    "\e[21~",           # kf10 (TB_CAP_F10)
    "\e[23~",           # kf11 (TB_CAP_F11)
    "\e[24~",           # kf12 (TB_CAP_F12)
    "\e[2~",            # insert (TB_CAP_INSERT)
    "\e[3~",            # delete (TB_CAP_DELETE)
    "\e[7~",            # home (TB_CAP_HOME)
    "\e[8~",            # end (TB_CAP_END)
    "\e[5~",            # page up (TB_CAP_PGUP)
    "\e[6~",            # page down (TB_CAP_PGDN)
    "\e[A",             # arrow up (TB_CAP_ARROW_UP)
    "\e[B",             # arrow down (TB_CAP_ARROW_DOWN)
    "\e[D",             # arrow left (TB_CAP_ARROW_LEFT)
    "\e[C",             # arrow right (TB_CAP_ARROW_RIGHT)
    "\e[Z",             # back tab (TB_CAP_BACK_TAB)
    "\e7\e[?47h",       # enter ca mode (TB_CAP_ENTER_CA)
    "\e[2J\e[?47l\e8",  # exit ca mode (TB_CAP_EXIT_CA)
    "\e[?25h",          # show cursor (TB_CAP_SHOW_CURSOR)
    "\e[?25l",          # hide cursor (TB_CAP_HIDE_CURSOR)
    "\e[H\e[2J",        # clear screen (TB_CAP_CLEAR_SCREEN)
    "\e[m\017",         # sgr0 (TB_CAP_SGR0)
    "\e[4m",            # underline (TB_CAP_UNDERLINE)
    "\e[1m",            # bold (TB_CAP_BOLD)
    "\e[5m",            # blink (TB_CAP_BLINK)
    "",                 # italic (TB_CAP_ITALIC)
    "\e[7m",            # reverse (TB_CAP_REVERSE)
    "\e=",              # enter keypad (TB_CAP_ENTER_KEYPAD)
    "\e>",              # exit keypad (TB_CAP_EXIT_KEYPAD)
    "",                 # dim (TB_CAP_DIM)
    "",                 # invisible (TB_CAP_INVISIBLE)
  ],
  'rxvt-unicode' => [
    "\e[11~",         # kf1 (TB_CAP_F1)
    "\e[12~",         # kf2 (TB_CAP_F2)
    "\e[13~",         # kf3 (TB_CAP_F3)
    "\e[14~",         # kf4 (TB_CAP_F4)
    "\e[15~",         # kf5 (TB_CAP_F5)
    "\e[17~",         # kf6 (TB_CAP_F6)
    "\e[18~",         # kf7 (TB_CAP_F7)
    "\e[19~",         # kf8 (TB_CAP_F8)
    "\e[20~",         # kf9 (TB_CAP_F9)
    "\e[21~",         # kf10 (TB_CAP_F10)
    "\e[23~",         # kf11 (TB_CAP_F11)
    "\e[24~",         # kf12 (TB_CAP_F12)
    "\e[2~",          # insert (TB_CAP_INSERT)
    "\e[3~",          # delete (TB_CAP_DELETE)
    "\e[7~",          # home (TB_CAP_HOME)
    "\e[8~",          # end (TB_CAP_END)
    "\e[5~",          # page up (TB_CAP_PGUP)
    "\e[6~",          # page down (TB_CAP_PGDN)
    "\e[A",           # arrow up (TB_CAP_ARROW_UP)
    "\e[B",           # arrow down (TB_CAP_ARROW_DOWN)
    "\e[D",           # arrow left (TB_CAP_ARROW_LEFT)
    "\e[C",           # arrow right (TB_CAP_ARROW_RIGHT)
    "\e[Z",           # back tab (TB_CAP_BACK_TAB)
    "\e[?1049h",      # enter ca mode (TB_CAP_ENTER_CA)
    "\e[r\e[?1049l",  # exit ca mode (TB_CAP_EXIT_CA)
    "\e[?12l\e[?25h", # show cursor (TB_CAP_SHOW_CURSOR)
    "\e[?25l",        # hide cursor (TB_CAP_HIDE_CURSOR)
    "\e[H\e[2J",      # clear screen (TB_CAP_CLEAR_SCREEN)
    "\e[m\e(B",       # sgr0 (TB_CAP_SGR0)
    "\e[4m",          # underline (TB_CAP_UNDERLINE)
    "\e[1m",          # bold (TB_CAP_BOLD)
    "\e[5m",          # blink (TB_CAP_BLINK)
    "\e[3m",          # italic (TB_CAP_ITALIC)
    "\e[7m",          # reverse (TB_CAP_REVERSE)
    "\e=",            # enter keypad (TB_CAP_ENTER_KEYPAD)
    "\e>",            # exit keypad (TB_CAP_EXIT_KEYPAD)
    "",               # dim (TB_CAP_DIM)
    "",               # invisible (TB_CAP_INVISIBLE)
  ],
  Eterm => [
    "\e[11~",           # kf1 (TB_CAP_F1)
    "\e[12~",           # kf2 (TB_CAP_F2)
    "\e[13~",           # kf3 (TB_CAP_F3)
    "\e[14~",           # kf4 (TB_CAP_F4)
    "\e[15~",           # kf5 (TB_CAP_F5)
    "\e[17~",           # kf6 (TB_CAP_F6)
    "\e[18~",           # kf7 (TB_CAP_F7)
    "\e[19~",           # kf8 (TB_CAP_F8)
    "\e[20~",           # kf9 (TB_CAP_F9)
    "\e[21~",           # kf10 (TB_CAP_F10)
    "\e[23~",           # kf11 (TB_CAP_F11)
    "\e[24~",           # kf12 (TB_CAP_F12)
    "\e[2~",            # insert (TB_CAP_INSERT)
    "\e[3~",            # delete (TB_CAP_DELETE)
    "\e[7~",            # home (TB_CAP_HOME)
    "\e[8~",            # end (TB_CAP_END)
    "\e[5~",            # page up (TB_CAP_PGUP)
    "\e[6~",            # page down (TB_CAP_PGDN)
    "\e[A",             # arrow up (TB_CAP_ARROW_UP)
    "\e[B",             # arrow down (TB_CAP_ARROW_DOWN)
    "\e[D",             # arrow left (TB_CAP_ARROW_LEFT)
    "\e[C",             # arrow right (TB_CAP_ARROW_RIGHT)
    "",                 # back tab (TB_CAP_BACK_TAB)
    "\e7\e[?47h",       # enter ca mode (TB_CAP_ENTER_CA)
    "\e[2J\e[?47l\e8",  # exit ca mode (TB_CAP_EXIT_CA)
    "\e[?25h",          # show cursor (TB_CAP_SHOW_CURSOR)
    "\e[?25l",          # hide cursor (TB_CAP_HIDE_CURSOR)
    "\e[H\e[2J",        # clear screen (TB_CAP_CLEAR_SCREEN)
    "\e[m\017",         # sgr0 (TB_CAP_SGR0)
    "\e[4m",            # underline (TB_CAP_UNDERLINE)
    "\e[1m",            # bold (TB_CAP_BOLD)
    "\e[5m",            # blink (TB_CAP_BLINK)
    "",                 # italic (TB_CAP_ITALIC)
    "\e[7m",            # reverse (TB_CAP_REVERSE)
    "",                 # enter keypad (TB_CAP_ENTER_KEYPAD)
    "",                 # exit keypad (TB_CAP_EXIT_KEYPAD)
    "",                 # dim (TB_CAP_DIM)
    "",                 # invisible (TB_CAP_INVISIBLE)
  ],
);

$builtin_terms{tmux} = $builtin_terms{screen};
$builtin_terms{rxvt} = $builtin_terms{"rxvt-unicode"};

our @builtin_terms_orders = qw(
  xterm
  linux
  screen        tmux
  rxvt-256color
  rxvt-unicode  rxvt
  Eterm
);

our %builtin_mod_caps = (
  # xterm arrows
  "\e[1;2A" => { key => TB_KEY_ARROW_UP, mod => TB_MOD_SHIFT                  },
  "\e[1;3A" => { key => TB_KEY_ARROW_UP, mod => TB_MOD_ALT                    },
  "\e[1;4A" => { key => TB_KEY_ARROW_UP, mod => TB_MOD_ALT | TB_MOD_SHIFT     },
  "\e[1;5A" => { key => TB_KEY_ARROW_UP, mod => TB_MOD_CTRL                   },
  "\e[1;6A" => { key => TB_KEY_ARROW_UP, mod => TB_MOD_CTRL | TB_MOD_SHIFT    },
  "\e[1;7A" => { key => TB_KEY_ARROW_UP, mod => TB_MOD_CTRL | TB_MOD_ALT      },
  "\e[1;8A" => { key => TB_KEY_ARROW_UP, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2B" => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_SHIFT                },
  "\e[1;3B" => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_ALT                  },
  "\e[1;4B" => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_ALT | TB_MOD_SHIFT   },
  "\e[1;5B" => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_CTRL                 },
  "\e[1;6B" => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_CTRL | TB_MOD_SHIFT  },
  "\e[1;7B" => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_CTRL | TB_MOD_ALT    },
  "\e[1;8B" => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_SHIFT               },
  "\e[1;3C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_ALT                 },
  "\e[1;4C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_ALT | TB_MOD_SHIFT  },
  "\e[1;5C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL                },
  "\e[1;6C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL | TB_MOD_SHIFT },
  "\e[1;7C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL | TB_MOD_ALT   },
  "\e[1;8C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2D" => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_SHIFT                },
  "\e[1;3D" => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_ALT                  },
  "\e[1;4D" => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_ALT | TB_MOD_SHIFT   },
  "\e[1;5D" => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_CTRL                 },
  "\e[1;6D" => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_CTRL | TB_MOD_SHIFT  },
  "\e[1;7D" => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_CTRL | TB_MOD_ALT    },
  "\e[1;8D" => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  # xterm keys
  "\e[1;2H" => { key => TB_KEY_HOME, mod => TB_MOD_SHIFT                      },
  "\e[1;3H" => { key => TB_KEY_HOME, mod => TB_MOD_ALT                        },
  "\e[1;4H" => { key => TB_KEY_HOME, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[1;5H" => { key => TB_KEY_HOME, mod => TB_MOD_CTRL                       },
  "\e[1;6H" => { key => TB_KEY_HOME, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[1;7H" => { key => TB_KEY_HOME, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e[1;8H" => { key => TB_KEY_HOME, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2F" => { key => TB_KEY_END, mod => TB_MOD_SHIFT                       },
  "\e[1;3F" => { key => TB_KEY_END, mod => TB_MOD_ALT                         },
  "\e[1;4F" => { key => TB_KEY_END, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[1;5F" => { key => TB_KEY_END, mod => TB_MOD_CTRL                        },
  "\e[1;6F" => { key => TB_KEY_END, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[1;7F" => { key => TB_KEY_END, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e[1;8F" => { key => TB_KEY_END, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[2;2~" => { key => TB_KEY_INSERT, mod => TB_MOD_SHIFT                    },
  "\e[2;3~" => { key => TB_KEY_INSERT, mod => TB_MOD_ALT                      },
  "\e[2;4~" => { key => TB_KEY_INSERT, mod => TB_MOD_ALT | TB_MOD_SHIFT       },
  "\e[2;5~" => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL                     },
  "\e[2;6~" => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL | TB_MOD_SHIFT      },
  "\e[2;7~" => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL | TB_MOD_ALT        },
  "\e[2;8~" => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[3;2~" => { key => TB_KEY_DELETE, mod => TB_MOD_SHIFT                    },
  "\e[3;3~" => { key => TB_KEY_DELETE, mod => TB_MOD_ALT                      },
  "\e[3;4~" => { key => TB_KEY_DELETE, mod => TB_MOD_ALT | TB_MOD_SHIFT       },
  "\e[3;5~" => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL                     },
  "\e[3;6~" => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL | TB_MOD_SHIFT      },
  "\e[3;7~" => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL | TB_MOD_ALT        },
  "\e[3;8~" => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[5;2~" => { key => TB_KEY_PGUP, mod => TB_MOD_SHIFT                      },
  "\e[5;3~" => { key => TB_KEY_PGUP, mod => TB_MOD_ALT                        },
  "\e[5;4~" => { key => TB_KEY_PGUP, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[5;5~" => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL                       },
  "\e[5;6~" => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[5;7~" => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e[5;8~" => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[6;2~" => { key => TB_KEY_PGDN, mod => TB_MOD_SHIFT                      },
  "\e[6;3~" => { key => TB_KEY_PGDN, mod => TB_MOD_ALT                        },
  "\e[6;4~" => { key => TB_KEY_PGDN, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[6;5~" => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL                       },
  "\e[6;6~" => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[6;7~" => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e[6;8~" => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2P" => { key => TB_KEY_F1, mod => TB_MOD_SHIFT                        },
  "\e[1;3P" => { key => TB_KEY_F1, mod => TB_MOD_ALT                          },
  "\e[1;4P" => { key => TB_KEY_F1, mod => TB_MOD_ALT | TB_MOD_SHIFT           },
  "\e[1;5P" => { key => TB_KEY_F1, mod => TB_MOD_CTRL                         },
  "\e[1;6P" => { key => TB_KEY_F1, mod => TB_MOD_CTRL | TB_MOD_SHIFT          },
  "\e[1;7P" => { key => TB_KEY_F1, mod => TB_MOD_CTRL | TB_MOD_ALT            },
  "\e[1;8P" => { key => TB_KEY_F1, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2Q" => { key => TB_KEY_F2, mod => TB_MOD_SHIFT                        },
  "\e[1;3Q" => { key => TB_KEY_F2, mod => TB_MOD_ALT                          },
  "\e[1;4Q" => { key => TB_KEY_F2, mod => TB_MOD_ALT | TB_MOD_SHIFT           },
  "\e[1;5Q" => { key => TB_KEY_F2, mod => TB_MOD_CTRL                         },
  "\e[1;6Q" => { key => TB_KEY_F2, mod => TB_MOD_CTRL | TB_MOD_SHIFT          },
  "\e[1;7Q" => { key => TB_KEY_F2, mod => TB_MOD_CTRL | TB_MOD_ALT            },
  "\e[1;8Q" => { key => TB_KEY_F2, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2R" => { key => TB_KEY_F3, mod => TB_MOD_SHIFT                        },
  "\e[1;3R" => { key => TB_KEY_F3, mod => TB_MOD_ALT                          },
  "\e[1;4R" => { key => TB_KEY_F3, mod => TB_MOD_ALT | TB_MOD_SHIFT           },
  "\e[1;5R" => { key => TB_KEY_F3, mod => TB_MOD_CTRL                         },
  "\e[1;6R" => { key => TB_KEY_F3, mod => TB_MOD_CTRL | TB_MOD_SHIFT          },
  "\e[1;7R" => { key => TB_KEY_F3, mod => TB_MOD_CTRL | TB_MOD_ALT            },
  "\e[1;8R" => { key => TB_KEY_F3, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[1;2S" => { key => TB_KEY_F4, mod => TB_MOD_SHIFT                        },
  "\e[1;3S" => { key => TB_KEY_F4, mod => TB_MOD_ALT                          },
  "\e[1;4S" => { key => TB_KEY_F4, mod => TB_MOD_ALT | TB_MOD_SHIFT           },
  "\e[1;5S" => { key => TB_KEY_F4, mod => TB_MOD_CTRL                         },
  "\e[1;6S" => { key => TB_KEY_F4, mod => TB_MOD_CTRL | TB_MOD_SHIFT          },
  "\e[1;7S" => { key => TB_KEY_F4, mod => TB_MOD_CTRL | TB_MOD_ALT            },
  "\e[1;8S" => { key => TB_KEY_F4, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[15;2~" => { key => TB_KEY_F5, mod => TB_MOD_SHIFT                       },
  "\e[15;3~" => { key => TB_KEY_F5, mod => TB_MOD_ALT                         },
  "\e[15;4~" => { key => TB_KEY_F5, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[15;5~" => { key => TB_KEY_F5, mod => TB_MOD_CTRL                        },
  "\e[15;6~" => { key => TB_KEY_F5, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[15;7~" => { key => TB_KEY_F5, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e[15;8~" => { key => TB_KEY_F5, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[17;2~" => { key => TB_KEY_F6, mod => TB_MOD_SHIFT                       },
  "\e[17;3~" => { key => TB_KEY_F6, mod => TB_MOD_ALT                         },
  "\e[17;4~" => { key => TB_KEY_F6, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[17;5~" => { key => TB_KEY_F6, mod => TB_MOD_CTRL                        },
  "\e[17;6~" => { key => TB_KEY_F6, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[17;7~" => { key => TB_KEY_F6, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e[17;8~" => { key => TB_KEY_F6, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[18;2~" => { key => TB_KEY_F7, mod => TB_MOD_SHIFT                       },
  "\e[18;3~" => { key => TB_KEY_F7, mod => TB_MOD_ALT                         },
  "\e[18;4~" => { key => TB_KEY_F7, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[18;5~" => { key => TB_KEY_F7, mod => TB_MOD_CTRL                        },
  "\e[18;6~" => { key => TB_KEY_F7, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[18;7~" => { key => TB_KEY_F7, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e[18;8~" => { key => TB_KEY_F7, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[19;2~" => { key => TB_KEY_F8, mod => TB_MOD_SHIFT                       },
  "\e[19;3~" => { key => TB_KEY_F8, mod => TB_MOD_ALT                         },
  "\e[19;4~" => { key => TB_KEY_F8, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[19;5~" => { key => TB_KEY_F8, mod => TB_MOD_CTRL                        },
  "\e[19;6~" => { key => TB_KEY_F8, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[19;7~" => { key => TB_KEY_F8, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e[19;8~" => { key => TB_KEY_F8, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[20;2~" => { key => TB_KEY_F9, mod => TB_MOD_SHIFT                       },
  "\e[20;3~" => { key => TB_KEY_F9, mod => TB_MOD_ALT                         },
  "\e[20;4~" => { key => TB_KEY_F9, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[20;5~" => { key => TB_KEY_F9, mod => TB_MOD_CTRL                        },
  "\e[20;6~" => { key => TB_KEY_F9, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[20;7~" => { key => TB_KEY_F9, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e[20;8~" => { key => TB_KEY_F9, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[21;2~" => { key => TB_KEY_F10, mod => TB_MOD_SHIFT                      },
  "\e[21;3~" => { key => TB_KEY_F10, mod => TB_MOD_ALT                        },
  "\e[21;4~" => { key => TB_KEY_F10, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[21;5~" => { key => TB_KEY_F10, mod => TB_MOD_CTRL                       },
  "\e[21;6~" => { key => TB_KEY_F10, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[21;7~" => { key => TB_KEY_F10, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e[21;8~" => { key => TB_KEY_F10, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[23;2~" => { key => TB_KEY_F11, mod => TB_MOD_SHIFT                      },
  "\e[23;3~" => { key => TB_KEY_F11, mod => TB_MOD_ALT                        },
  "\e[23;4~" => { key => TB_KEY_F11, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[23;5~" => { key => TB_KEY_F11, mod => TB_MOD_CTRL                       },
  "\e[23;6~" => { key => TB_KEY_F11, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[23;7~" => { key => TB_KEY_F11, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e[23;8~" => { key => TB_KEY_F11, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e[24;2~" => { key => TB_KEY_F12, mod => TB_MOD_SHIFT                      },
  "\e[24;3~" => { key => TB_KEY_F12, mod => TB_MOD_ALT                        },
  "\e[24;4~" => { key => TB_KEY_F12, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[24;5~" => { key => TB_KEY_F12, mod => TB_MOD_CTRL                       },
  "\e[24;6~" => { key => TB_KEY_F12, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[24;7~" => { key => TB_KEY_F12, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e[24;8~" => { key => TB_KEY_F12, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  # rxvt arrows
  "\e[a"    => { key => TB_KEY_ARROW_UP, mod => TB_MOD_SHIFT                  },
  "\e\e[A"  => { key => TB_KEY_ARROW_UP, mod => TB_MOD_ALT                    },
  "\e\e[a"  => { key => TB_KEY_ARROW_UP, mod => TB_MOD_ALT | TB_MOD_SHIFT     },
  "\eOa"    => { key => TB_KEY_ARROW_UP, mod => TB_MOD_CTRL                   },
  "\e\eOa"  => { key => TB_KEY_ARROW_UP, mod => TB_MOD_CTRL | TB_MOD_ALT      },

  "\e[b"    => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_SHIFT                },
  "\e\e[B"  => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_ALT                  },
  "\e\e[b"  => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_ALT | TB_MOD_SHIFT   },
  "\eOb"    => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_CTRL                 },
  "\e\eOb"  => { key => TB_KEY_ARROW_DOWN, mod => TB_MOD_CTRL | TB_MOD_ALT    },

  "\e[c"    => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_SHIFT               },
  "\e\e[C"  => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_ALT                 },
  "\e\e[c"  => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_ALT | TB_MOD_SHIFT  },
  "\eOc"    => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL                },
  "\e\eOc"  => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL | TB_MOD_ALT   },

  "\e[d"    => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_SHIFT                },
  "\e\e[D"  => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_ALT                  },
  "\e\e[d"  => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_ALT | TB_MOD_SHIFT   },
  "\eOd"    => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_CTRL                 },
  "\e\eOd"  => { key => TB_KEY_ARROW_LEFT, mod => TB_MOD_CTRL | TB_MOD_ALT    },

  # rxvt keys
  "\e[7\$"   => { key => TB_KEY_HOME, mod => TB_MOD_SHIFT                     },
  "\e\e[7~"  => { key => TB_KEY_HOME, mod => TB_MOD_ALT                       },
  "\e\e[7\$" => { key => TB_KEY_HOME, mod => TB_MOD_ALT | TB_MOD_SHIFT        },
  "\e[7^"    => { key => TB_KEY_HOME, mod => TB_MOD_CTRL                      },
  "\e[7@"    => { key => TB_KEY_HOME, mod => TB_MOD_CTRL | TB_MOD_SHIFT       },
  "\e\e[7^"  => { key => TB_KEY_HOME, mod => TB_MOD_CTRL | TB_MOD_ALT         },
  "\e\e[7@"  => { key => TB_KEY_HOME, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},

  "\e\e[8~"  => { key => TB_KEY_END, mod => TB_MOD_ALT                        },
  "\e\e[8\$" => { key => TB_KEY_END, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[8^"    => { key => TB_KEY_END, mod => TB_MOD_CTRL                       },
  "\e\e[8^"  => { key => TB_KEY_END, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e\e[8@"  => { key => TB_KEY_END, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[8@"    => { key => TB_KEY_END, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[8\$"   => { key => TB_KEY_END, mod => TB_MOD_SHIFT                      },

  "\e\e[2~"  => { key => TB_KEY_INSERT, mod => TB_MOD_ALT                     },
  "\e\e[2\$" => { key => TB_KEY_INSERT, mod => TB_MOD_ALT | TB_MOD_SHIFT      },
  "\e[2^"    => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL                    },
  "\e\e[2^"  => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL | TB_MOD_ALT       },
  "\e\e[2@"  => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[2@"    => { key => TB_KEY_INSERT, mod => TB_MOD_CTRL | TB_MOD_SHIFT     },
  "\e[2\$"   => { key => TB_KEY_INSERT, mod => TB_MOD_SHIFT                   },

  "\e\e[3~"  => { key => TB_KEY_DELETE, mod => TB_MOD_ALT                     },
  "\e\e[3\$" => { key => TB_KEY_DELETE, mod => TB_MOD_ALT | TB_MOD_SHIFT      },
  "\e[3^"    => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL                    },
  "\e\e[3^"  => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL | TB_MOD_ALT       },
  "\e\e[3@"  => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[3@"    => { key => TB_KEY_DELETE, mod => TB_MOD_CTRL | TB_MOD_SHIFT     },
  "\e[3\$"   => { key => TB_KEY_DELETE, mod => TB_MOD_SHIFT                   },

  "\e\e[5~"  => { key => TB_KEY_PGUP, mod => TB_MOD_ALT                       },
  "\e\e[5\$" => { key => TB_KEY_PGUP, mod => TB_MOD_ALT | TB_MOD_SHIFT        },
  "\e[5^"    => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL                      },
  "\e\e[5^"  => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL | TB_MOD_ALT         },
  "\e\e[5@"  => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[5@"    => { key => TB_KEY_PGUP, mod => TB_MOD_CTRL | TB_MOD_SHIFT       },
  "\e[5\$"   => { key => TB_KEY_PGUP, mod => TB_MOD_SHIFT                     },

  "\e\e[6~"  => { key => TB_KEY_PGDN, mod => TB_MOD_ALT                       },
  "\e\e[6\$" => { key => TB_KEY_PGDN, mod => TB_MOD_ALT | TB_MOD_SHIFT        },
  "\e[6^"    => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL                      },
  "\e\e[6^"  => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL | TB_MOD_ALT         },
  "\e\e[6@"  => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[6@"    => { key => TB_KEY_PGDN, mod => TB_MOD_CTRL | TB_MOD_SHIFT       },
  "\e[6\$"   => { key => TB_KEY_PGDN, mod => TB_MOD_SHIFT                     },

  "\e\e[11~" => { key => TB_KEY_F1, mod => TB_MOD_ALT                         },
  "\e\e[23~" => { key => TB_KEY_F1, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[11^"   => { key => TB_KEY_F1, mod => TB_MOD_CTRL                        },
  "\e\e[11^" => { key => TB_KEY_F1, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[23^" => { key => TB_KEY_F1, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[23^"   => { key => TB_KEY_F1, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[23~"   => { key => TB_KEY_F1, mod => TB_MOD_SHIFT                       },

  "\e\e[12~" => { key => TB_KEY_F2, mod => TB_MOD_ALT                         },
  "\e\e[24~" => { key => TB_KEY_F2, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[12^"   => { key => TB_KEY_F2, mod => TB_MOD_CTRL                        },
  "\e\e[12^" => { key => TB_KEY_F2, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[24^" => { key => TB_KEY_F2, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[24^"   => { key => TB_KEY_F2, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[24~"   => { key => TB_KEY_F2, mod => TB_MOD_SHIFT                       },

  "\e\e[13~" => { key => TB_KEY_F3, mod => TB_MOD_ALT                         },
  "\e\e[25~" => { key => TB_KEY_F3, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[13^"   => { key => TB_KEY_F3, mod => TB_MOD_CTRL                        },
  "\e\e[13^" => { key => TB_KEY_F3, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[25^" => { key => TB_KEY_F3, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[25^"   => { key => TB_KEY_F3, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[25~"   => { key => TB_KEY_F3, mod => TB_MOD_SHIFT                       },

  "\e\e[14~" => { key => TB_KEY_F4, mod => TB_MOD_ALT                         },
  "\e\e[26~" => { key => TB_KEY_F4, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[14^"   => { key => TB_KEY_F4, mod => TB_MOD_CTRL                        },
  "\e\e[14^" => { key => TB_KEY_F4, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[26^" => { key => TB_KEY_F4, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[26^"   => { key => TB_KEY_F4, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[26~"   => { key => TB_KEY_F4, mod => TB_MOD_SHIFT                       },

  "\e\e[15~" => { key => TB_KEY_F5, mod => TB_MOD_ALT                         },
  "\e\e[28~" => { key => TB_KEY_F5, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[15^"   => { key => TB_KEY_F5, mod => TB_MOD_CTRL                        },
  "\e\e[15^" => { key => TB_KEY_F5, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[28^" => { key => TB_KEY_F5, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[28^"   => { key => TB_KEY_F5, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[28~"   => { key => TB_KEY_F5, mod => TB_MOD_SHIFT                       },

  "\e\e[17~" => { key => TB_KEY_F6, mod => TB_MOD_ALT                         },
  "\e\e[29~" => { key => TB_KEY_F6, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[17^"   => { key => TB_KEY_F6, mod => TB_MOD_CTRL                        },
  "\e\e[17^" => { key => TB_KEY_F6, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[29^" => { key => TB_KEY_F6, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[29^"   => { key => TB_KEY_F6, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[29~"   => { key => TB_KEY_F6, mod => TB_MOD_SHIFT                       },

  "\e\e[18~" => { key => TB_KEY_F7, mod => TB_MOD_ALT                         },
  "\e\e[31~" => { key => TB_KEY_F7, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[18^"   => { key => TB_KEY_F7, mod => TB_MOD_CTRL                        },
  "\e\e[18^" => { key => TB_KEY_F7, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[31^" => { key => TB_KEY_F7, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[31^"   => { key => TB_KEY_F7, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[31~"   => { key => TB_KEY_F7, mod => TB_MOD_SHIFT                       },

  "\e\e[19~" => { key => TB_KEY_F8, mod => TB_MOD_ALT                         },
  "\e\e[32~" => { key => TB_KEY_F8, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[19^"   => { key => TB_KEY_F8, mod => TB_MOD_CTRL                        },
  "\e\e[19^" => { key => TB_KEY_F8, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[32^" => { key => TB_KEY_F8, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[32^"   => { key => TB_KEY_F8, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[32~"   => { key => TB_KEY_F8, mod => TB_MOD_SHIFT                       },

  "\e\e[20~" => { key => TB_KEY_F9, mod => TB_MOD_ALT                         },
  "\e\e[33~" => { key => TB_KEY_F9, mod => TB_MOD_ALT | TB_MOD_SHIFT          },
  "\e[20^"   => { key => TB_KEY_F9, mod => TB_MOD_CTRL                        },
  "\e\e[20^" => { key => TB_KEY_F9, mod => TB_MOD_CTRL | TB_MOD_ALT           },
  "\e\e[33^" => { key => TB_KEY_F9, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[33^"   => { key => TB_KEY_F9, mod => TB_MOD_CTRL | TB_MOD_SHIFT         },
  "\e[33~"   => { key => TB_KEY_F9, mod => TB_MOD_SHIFT                       },

  "\e\e[21~" => { key => TB_KEY_F10, mod => TB_MOD_ALT                        },
  "\e\e[34~" => { key => TB_KEY_F10, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[21^"   => { key => TB_KEY_F10, mod => TB_MOD_CTRL                       },
  "\e\e[21^" => { key => TB_KEY_F10, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e\e[34^" => { key => TB_KEY_F10, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[34^"   => { key => TB_KEY_F10, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[34~"   => { key => TB_KEY_F10, mod => TB_MOD_SHIFT                      },

  "\e\e[23~" => { key => TB_KEY_F11, mod => TB_MOD_ALT                        },
  "\e\e[23\$"=> { key => TB_KEY_F11, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[23^"   => { key => TB_KEY_F11, mod => TB_MOD_CTRL                       },
  "\e\e[23^" => { key => TB_KEY_F11, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e\e[23@" => { key => TB_KEY_F11, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[23@"   => { key => TB_KEY_F11, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[23\$"  => { key => TB_KEY_F11, mod => TB_MOD_SHIFT                      },

  "\e\e[24~" => { key => TB_KEY_F12, mod => TB_MOD_ALT                        },
  "\e\e[24\$"=> { key => TB_KEY_F12, mod => TB_MOD_ALT | TB_MOD_SHIFT         },
  "\e[24^"   => { key => TB_KEY_F12, mod => TB_MOD_CTRL                       },
  "\e\e[24^" => { key => TB_KEY_F12, mod => TB_MOD_CTRL | TB_MOD_ALT          },
  "\e\e[24@" => { key => TB_KEY_F12, mod => TB_MOD_CTRL | TB_MOD_ALT | TB_MOD_SHIFT},
  "\e[24@"   => { key => TB_KEY_F12, mod => TB_MOD_CTRL | TB_MOD_SHIFT        },
  "\e[24\$"  => { key => TB_KEY_F12, mod => TB_MOD_SHIFT                      },

  # linux console/putty arrows
  "\e[A" => { key => TB_KEY_ARROW_UP,    mod => TB_MOD_SHIFT                  },
  "\e[B" => { key => TB_KEY_ARROW_DOWN,  mod => TB_MOD_SHIFT                  },
  "\e[C" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_SHIFT                  },
  "\e[D" => { key => TB_KEY_ARROW_LEFT,  mod => TB_MOD_SHIFT                  },

  # more putty arrows
  "\eOA"   => { key => TB_KEY_ARROW_UP,    mod => TB_MOD_CTRL                 },
  "\e\eOA" => { key => TB_KEY_ARROW_UP,    mod => TB_MOD_CTRL | TB_MOD_ALT    },
  "\eOB"   => { key => TB_KEY_ARROW_DOWN,  mod => TB_MOD_CTRL                 },
  "\e\eOB" => { key => TB_KEY_ARROW_DOWN,  mod => TB_MOD_CTRL | TB_MOD_ALT    },
  "\eOC"   => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL                 },
  "\e\eOC" => { key => TB_KEY_ARROW_RIGHT, mod => TB_MOD_CTRL | TB_MOD_ALT    },
  "\eOD"   => { key => TB_KEY_ARROW_LEFT,  mod => TB_MOD_CTRL                 },
  "\e\eOD" => { key => TB_KEY_ARROW_LEFT,  mod => TB_MOD_CTRL | TB_MOD_ALT    },
);

1;
