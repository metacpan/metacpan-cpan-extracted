#!/usr/bin/perl -w
#
# Make sure the VT102 module can process basic text OK.
#
# Copyright (C) Andrew Wood
# NO WARRANTY - see COPYING.
#

require Term::VT102;
require 't/testbase';

run_tests ([(
  [ 10, 5, "line 1\r\n  line 2\r\n  line 3\r\nline 4",
    "line 1" . ("\0" x 4),
    "  line 2" . ("\0" x 2),
    "  line 3" . ("\0" x 2),
    "line 4" . ("\0" x 4),
  ],
  [ 80, 25, " line 1 \n    line 2\n    line 3\n line 4 ",
    " line 1 " . ("\0" x 72),
    ("\0" x 8) . "    line 2" . ("\0" x 62),
    ("\0" x 18) . "    line 3" . ("\0" x 52),
    ("\0" x 28) . " line 4 " . ("\0" x 44),
  ],
  [ 40, 5, "line 1\ttab 1\r\n  line 2\ttab 2\ttab 3\r\n  line 3\r\nline 4",
    "line 1\0\0tab 1" . ("\0" x 27),
    "  line 2\0\0\0\0\0\0\0\0tab 2\0\0\0tab 3" . ("\0" x 11),
    "  line 3" . ("\0" x 32),
    "line 4" . ("\0" x 34),
  ],
)]);

# EOF
