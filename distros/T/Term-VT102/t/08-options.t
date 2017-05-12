#!/usr/bin/perl -w
#
# Make sure the VT102 module's option settings work.
#
# Copyright (C) Andrew Wood
# NO WARRANTY - see COPYING.
#

require Term::VT102;
require 't/testbase';

run_tests ([(
  [ { 'LFTOCRLF' => 1 }, 10, 5, "line 1\n  line 2\n  line 3\nline 4",
    "line 1" . ("\0" x 4),
    "  line 2" . ("\0" x 2),
    "  line 3" . ("\0" x 2),
    "line 4" . ("\0" x 4),
  ],
  [ { 'LINEWRAP' => 1 }, 10, 5, "abcdefghijklmnopqrstuvwxyz",
    "abcdefghij",
    "klmnopqrst",
    "uvwxyz" . ("\0" x 4),
  ],
)]);

# EOF
