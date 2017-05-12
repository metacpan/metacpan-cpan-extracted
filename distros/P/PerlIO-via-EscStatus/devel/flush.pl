#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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


package PerlIO::via::MyBelow;
use strict;
use warnings;
use Data::Dumper;

sub PUSHED {
  my ($class, $mode, $fh) = @_;
  print STDERR "(below) pushed\n";
  { my $saver = SelectSaver->new ($fh);
    print STDERR "(below) lower autoflush ", (!!$| ? "on" : "off"), "\n";
  }
  return bless { }, $class;
}

sub FLUSH {
  my ($self, $fh) = @_;
  print STDERR "(below) FLUSH\n";
  return 0;
}

sub WRITE {
  my ($self, $buf, $fh) = @_;
  print STDERR "(below) WRITE ",length($buf),"\n";
  print $fh $buf or return -1;
  return length($buf);
}

package PerlIO::via::MyFlush;
use strict;
use warnings;
use Data::Dumper;

sub PUSHED {
  my ($class, $mode, $fh) = @_;
  print STDERR "pushed ", Data::Dumper::Dumper ([$class,$mode,$fh]);
  { my $saver = SelectSaver->new ($fh);
    print STDERR "lower autoflush ", (!!$| ? "on" : "off"), "\n";
  }
  return bless { }, $class;
}

sub FLUSH {
  my ($self, $fh) = @_;
  print STDERR "FLUSH\n";
  return 0;
}

sub WRITE {
  my ($self, $buf, $fh) = @_;
  print STDERR "WRITE ",length($buf),"\n";
  { my $saver = SelectSaver->new ($fh);
    print STDERR "lower autoflush ", (!!$| ? "on" : "off"), "\n";
  }
  print $fh $buf or return -1;
  return length($buf);
}

package main;
use strict;
use warnings;
use IO::Handle;

print STDERR "begin autoflush ", (!!$| ? "on" : "off"), "\n";

$| = 0;
$| = 1;
print STDERR "binmode\n";
binmode (STDOUT, ':via(MyBelow)') or die $!;
$| = 0;
$| = 1;
binmode (STDOUT, ':via(MyFlush)') or die $!;
$| = 0;
$| = 1;
binmode (STDOUT, ':encoding(latin-1)') or die $!;
$| = 0;
$| = 1;
print STDERR "binmode done\n";

# print STDERR "pushed autoflush ", (!!$| ? "on" : "off"), "\n";
# 
# print STDERR "\n->flush\n";
# if (STDOUT->flush) {
#   print STDERR " ->flush ok\n";
# } else {
#   print STDERR " ->flush error\n";
# }
# print STDERR "now autoflush ", (!!$| ? "on" : "off"), "\n";
# 
# print STDERR "\nbang flush\n";
# $! = 1;
# local $| = 1;
# print STDERR "! ",$!+0,"\n";
# print STDERR "bang flush done\n";
# print STDERR "now autoflush ", (!!$| ? "on" : "off"), "\n";
# 
# print STDERR "\nprint empty\n";
# if (print "") {
#   print STDERR "empty ok\n";
# } else {
#   print STDERR "empty error\n";
# }

$| = 0;
$| = 1;
print STDERR "\n";
print STDERR "now autoflush ", (!!$| ? "on" : "off"), "\n";
print STDERR "print out\n";
if (print "out\n") {
  print STDERR " out ok\n";
} else {
  print STDERR " out error\n";
}

$| = 0;
$| = 1;
print STDERR "\n";
print STDERR "now autoflush ", (!!$| ? "on" : "off"), "\n";
print STDERR "print out\n";
if (print "out\n") {
  print STDERR " out ok\n";
} else {
  print STDERR " out error\n";
}

print STDERR "\nbinmode\n";
binmode STDOUT;
print STDERR "\nexit\n";
exit 0;
