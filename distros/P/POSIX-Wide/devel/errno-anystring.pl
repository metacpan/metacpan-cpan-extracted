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

use blib "$ENV{HOME}/perl/scalar-list-utils/Scalar-List-Utils-1.23";
use blib "$ENV{HOME}/perl/errno-anystring/Errno-AnyString-1.03";

{
  require Errno::AnyString;
  require Scalar::Util;
  print "Scalar::Util ",Scalar::Util->VERSION,"\n";

  my $str = "\x{2022}";
  print "str: ",(utf8::is_utf8($str) ? "is utf8" : "not utf8"),"\n";

  my $enum = 12345;
  my $dual = Errno::AnyString::register_errstr ($str, $enum);
  my $dstr = "$dual";
  print "dstr: ",(utf8::is_utf8($dstr) ? "is utf8" : "not utf8"),"\n";

  my $estr = "$Errno::AnyString::Errno2Errstr{$enum}";
  print "Errno2Errstr: ",(utf8::is_utf8($estr) ? "is utf8" : "not utf8"),"\n";

  $! = $enum;
  my $out = "$!";
  print "$out\n";
  print "out: ",(utf8::is_utf8($out) ? "is utf8" : "not utf8"),"\n";
  printf ("%d %X\n", $!+0, $!+0);

  exit 0;
}
{
  require Scalar::Util;
  my $str = "\x{2022}";
  print "str: ",(utf8::is_utf8($str) ? "is utf8" : "not utf8"),"\n";
  my $dual = Scalar::Util::dualvar(123, $str);
  my $dstr = "$dual";
  print "dstr: ",(utf8::is_utf8($dstr) ? "is utf8" : "not utf8"),"\n";
  exit 0;
}

{
  require Errno::AnyString;
  require POSIX;
  Errno::AnyString::register_errstr ("My error", 12345);
  print POSIX::strerror(12345),"\n";

  $! = 12345;
  POSIX::perror("blah");
  exit 0;
}

{
  local $! = 2;

  { local $! = 3;
    require Errno::AnyString;
    print "$!\n";
    printf ("%d %X\n", $!+0, $!+0);
  }
  print "$!\n";
  printf ("%d %X\n", $!+0, $!+0);

  $! = Errno::AnyString::custom_errstr ("Something no good");
  print "$!\n";
  printf ("%d %X\n", $!+0, $!+0);

  exit 0;
}

{
  require POSIX;
  require Errno::AnyString;

  $! = Errno::AnyString::custom_errstr ("Something no good");
  print "$!\n";
  printf ("%d %X\n", $!+0, $!+0);

  $! = Errno::AnyString::custom_errstr ("Another bad thing");
  print "$!\n";
  printf ("%d %X\n", $!+0, $!+0);

  $! = POSIX::ENOENT();
  print "$!\n";
  printf ("%d %X\n", $!+0, $!+0);

  Errno::AnyString::register_errstr ("My error", 12345);
  $! = 12345;
  print "$!\n";
  printf ("%d %X\n", $!+0, $!+0);
  print POSIX::strerror(2),"\n";

  exit 0;
}
