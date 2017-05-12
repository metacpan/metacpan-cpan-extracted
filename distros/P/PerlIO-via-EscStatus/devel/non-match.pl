#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


my $str = "\e_EscStatus\e\\";

sub non_match {
  my ($str, $level) = @_;
  $level ||= 0;

  my $c = substr($str,0,1);
  my $rest = substr($str,1);
  if ($c eq "\e") {
    $c = "\\e";
  } elsif ($c eq "\\") {
    $c = "\\\\";
  }

  if (length ($str) == 1) {
    return "[^$c]";
  } elif ($level > 0) {
    return "(?:[^$c]|$c" . non_match($rest,$level+1) . ")";
  } else {
    # outermost
    return "(?:(?>[^$c]+)|$c" . non_match($rest,$level+1) . ")";
  }
}

print "/^",non_match ($str),"*/\n";


my $buf = "zz\e_Es";
if ($buf =~ /^([^\e]++|\e([^_]|_([^E]|E[^s])))*/) {
  print "1: '",$1,"'\n";
  print "2: '",$2,"'\n";
  print "match:  '",$&,"'\n";
  print "beyond: '",$',"'\n";
} else {
  print "no\n";
}

exit 0;
