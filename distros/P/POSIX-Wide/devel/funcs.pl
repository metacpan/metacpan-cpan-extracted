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




{
  $! = 9;
  print $!,"\n";
  require POSIX;
  delete $ENV{'LANGUAGE'}; # ='fr';
  delete $ENV{'LC_ALL'};
  delete $ENV{'LC_MESSAGES'};
  delete $ENV{'LANG'};

  print POSIX::setlocale(POSIX::LC_ALL(),'fr_FR'),"\n";
  print POSIX::setlocale(POSIX::LC_MESSAGES(),'fr_FR'),"\n";
  print POSIX::setlocale(POSIX::LC_MESSAGES()),"\n";

#   foreach my $i (1 .. 100) {
#     $! = $i;
#     if ("$!" =~ /[^[:ascii:]]/) {
#       print "$i\n";
#     }
#   }

  print POSIX::strerror(4),"\n";
  $! = 4;
  my $ext = "$^E";
  print $!,"\n";
  print "$ext\n";
  print "ext utf8 ",(utf8::is_utf8($ext)+0),"\n";

#   require Locale::Messages;
#   print Locale::Messages::dgettext('libc',"Bad file descriptor"),"\n";
  exit 0;
}

{
  require POSIX;
  $ENV{'TZ'} = 'EST+10EDT';
  POSIX::tzset();
  print "scalar ", scalar(POSIX::tzname()), "\n";
  print "list   ", POSIX::tzname(), "\n";
  exit 0;
}

{
  require Encode;
  foreach (Encode->encodings(':all')) { print; print "\n"; }

  print "with :all\n";
  require Encode;
  foreach (Encode->encodings(':all')) { print; print "\n"; }

  print "alias: ", Encode::resolve_alias("646"), "\n";

  exit 0;
}
{
  require POSIX;
  print "perror defined: ",defined(&perror)?"yes":"no","\n";
  print "can('perror'): ",POSIX->can('perror')?"yes":"no","\n";
  $! = 3;
  POSIX::perror();
}

{
  print "strcspn defined: ",defined(&strcspn)?"yes":"no","\n";
  print "can('strcspn'): ",POSIX->can('strcspn')?"yes":"no","\n";
  POSIX::strcspn();
}

{
  print "TZNAME_MAX is ",POSIX::sysconf(POSIX::_SC_TZNAME_MAX()),"\n";
  exit 0;
}

exit 0;
