#!/usr/bin/perl -w

# Copyright 2010, 2014 Kevin Ryde

# This file is part of POSIX-Wide.
#
# POSIX-Wide is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# POSIX-Wide is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with POSIX-Wide.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<HERE;
sub foo {
  return __FILE__.':'.__LINE__;
}
HERE

# #line 123 "foo"
sub bar {
  return __FILE__.':'.__LINE__;
}

print foo(),"\n";
print bar(),"\n";
exit 0;
