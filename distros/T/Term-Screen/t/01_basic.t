#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 29;         

use_ok('Term::Screen');

can_ok("Term::Screen", "new");
can_ok("Term::Screen", "DESTROY");
can_ok("Term::Screen", "term");
can_ok("Term::Screen", "rows");
can_ok("Term::Screen", "cols");
can_ok("Term::Screen", "at");
can_ok("Term::Screen", "resize");
can_ok("Term::Screen", "normal");
can_ok("Term::Screen", "bold");
can_ok("Term::Screen", "reverse");
can_ok("Term::Screen", "clrscr");
can_ok("Term::Screen", "clreol");
can_ok("Term::Screen", "clreos");
can_ok("Term::Screen", "il");
can_ok("Term::Screen", "dl");
can_ok("Term::Screen", "ic_exists");
can_ok("Term::Screen", "ic");
can_ok("Term::Screen", "dc_exists");
can_ok("Term::Screen", "dc");
can_ok("Term::Screen", "puts");
can_ok("Term::Screen", "getch");
can_ok("Term::Screen", "def_key");
can_ok("Term::Screen", "key_pressed");
can_ok("Term::Screen", "echo");
can_ok("Term::Screen", "noecho");
can_ok("Term::Screen", "flush_input");
can_ok("Term::Screen", "stuff_input");
can_ok("Term::Screen", "get_fn_keys");
