#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Regexp-Common-Other.
#
# Regexp-Common-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Regexp-Common-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.

use strict;
BEGIN { push @INC, '/usr/share/perl5'; }

use Regexp::Common 'Emacs';
use Regexp::Common 'RE_Emacs_autosave';

# uncomment this to run the ### lines
use Smart::Comments;


{
  my $backup = $RE{Emacs}{backup};
  print ref $backup,"\n";
  print $backup,"\n";
  print $backup->{-single},"\n";
  print $backup->{-numbered},"\n";
  print $backup->{-keep},"\n";
  exit 0;
}
{
  opendir DH, '.' or die $!;
  while (my $filename = readdir DH) {
    next if $filename =~ $RE{Emacs}{skipfile};
    print "$filename\n";
  }
  closedir DH;
  exit 0;
}

{
  print $RE{Emacs}{skipfile},"\n";
  print $RE{Emacs}{backup},"\n";
  print $RE{Emacs}{backup}{-unonly},"\n";
  print $RE{Emacs}{lockfile},"\n";
  print $RE{Emacs}{autosave},"\n";

  print RE_Emacs_autosave(),"\n";
  print "\n";

  foreach my $filename ('foo.c',
                        'foo.c~',
                        '~',
                        '/~',
                        'x/~',
                        '/~123~',
                        '/dir/~123~',
                        '/dir/.~123~',
                        'foo.c.~9~',
                        'foo.c.9~',
                        'foo.cx~9~',
                        'foo.c.~123~',
                        '#foo.c#',
                        '.#foo.c',
                       ) {
    printf "%-20s", $filename;
    if ($filename =~ /$RE{Emacs}{backup}{-keep}/) {
      my $base = $2; $base = 'undef' if ! defined $base;
      my $num = $3; $num = 'undef' if ! defined $num;
      print "back[$base][$num]";
    } else {
      #    print "no  "
    }
    print " ";
    if ($filename =~ /$RE{Emacs}{backup}{-unonly}{-keep}/) {
      my $base = $2; $base = 'undef' if ! defined $base;
      my $num = $3; $num = 'undef' if ! defined $num;
      print "un[$base][$num]";
    } else {
      #   print " ";
    }
    print " ";
    if ($filename =~ /$RE{Emacs}{backup}{-numonly}{-keep}/) {
      my $base = $2; $base = 'undef' if ! defined $base;
      my $num = $3; $num = 'undef' if ! defined $num;
      print "num[$base][$num]";
    } else {
      print " ";
    }
    print " ";

    if ($filename =~ /$RE{Emacs}{autosave}/) {
      print "auto";
    } else {
      #  print "no  "
    }
    print " ";

    if ($filename =~ /$RE{Emacs}{lockfile}/) {
      print "lock";
    } else {
      # print "no  "
    }
    print "\n";
  }
  exit 0;
}

{
  my $str = 'xxx';
  $str =~ /(.+?)/;
  print "match: \"$1\"\n";
  exit 0;
}

