#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.


# 5.8.4 needs property specs in same package, doesn't have
# "EastAsianWidth:W", and doesn't allow user-defined properties to use other
# user-defined properties, or some such.
#

package Foo;
use strict;
use warnings;

sub IsZero {
  return "+utf8::Me\n"  # mark, enclosing
       . "+utf8::Mn\n"  # mark, non-spacing
       . "+utf8::Cf\n"  # control, format
       . "-00AD\n"      #    but exclude soft hyphen which is in Cf
       . "+0007\n"      # BEL
       . "+000D\n";     # CR, for our purposes
}

package main;
use strict;
use warnings;

sub IsZZ {
  return "\n";
  return "+utf8::Me\n"  # mark, enclosing
       . "+utf8::Mn\n"  # mark, non-spacing
       . "+utf8::Cf\n"  # control, format
       . "-00AD\n"      #    but exclude soft hyphen which is in Cf
       . "+0007\n"      # BEL
       . "+000D\n";     # CR, for our purposes
}

my $str = "\a";

if ($str =~ /\p{IsZZ}/) {
  print "yes\n";
} else {
  print "no\n";
}

package Foo;
if ($str =~ /\p{IsZero}/) {
  print "yes\n";
} else {
  print "no\n";
}

'x' =~ /\p{EastAsianWidth:W}/;

if ($str =~ /\p{EastAsianWidth:W}/) {
  print "yes\n";
} else {
  print "no\n";
}
