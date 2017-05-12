#!/usr/bin/perl -w

# Copyright 2009, 2010, 2014 Kevin Ryde

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
use POSIX ();
use lib::abs 'lib';
use POSIX::Wide;

my $loc = POSIX::setlocale(POSIX::LC_ALL());
print "Locale = $loc\n";

my $set = 'fr_FR';
$set = 'en_GB';
$set = 'ar_IN';
$ENV{'LANGUAGE'} = $set;
# $ENV{'LANG'} = 'en_IN';
# $ENV{'LC_ALL'} = 'en_IN';
# $ENV{'LC_ALL'} = 'en_IN';
$loc = POSIX::setlocale(POSIX::LC_ALL, $set);
print "Locale = $loc\n";

$loc = POSIX::setlocale(POSIX::LC_MESSAGES);
print "Locale = $loc\n";
{
  my $s = strerror(2);
  print "err2 = $s ",(utf8::is_utf8($s) ? "UTF8" : "BYTE"), "\n";
}
{
  $! = 1;
  my $x = $POSIX::Wide::ERRNO;
  print "ERRNO = ",$!+0," ",$x+0," $x ",(utf8::is_utf8($x) ? "UTF8" : "BYTE"),
    "\n";
}
# my $str = "$!";
# say "err2 = $str";
print strftime("%a %b",localtime(time())),"\n";;
print POSIX::asctime(localtime(time()));
print POSIX::ctime(time());

{
  my $l = POSIX::Wide::localeconv();
  #   say "frac_digits ",$l->{'frac_digits'};
  #   say "grouping ",$l->{'grouping'};

  foreach my $key (sort keys %$l) {
    my $value = $l->{$key};
    printf "%-20s ",$key; hstr($value);
  }

  # 20A8 RUPEE SIGN
  # (progn (insert (decode-char 'ucs #x20A8)) (describe-char (1- (point))) (backward-delete-char 1))
}

