#!perl
#
# This file is part of Software-Copyright
#
# This software is Copyright (c) 2022 by Dominique Dumont <dod@debian.org>.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use Test::Synopsis;

all_synopsis_ok();
