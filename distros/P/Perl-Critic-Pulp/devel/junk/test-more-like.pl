#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/perl
use strict;
use warnings;

{
  my $re = qr/a b/x;
  if ("XabY" =~ $re) {print "ab matches\n";} else {print "ab no match\n";}
  if ("XaBY" =~ /X${re}Y/) {print "ab matches\n";} else{print "ab no match\n";}
}

{
  my $re = qr/x/i;
  if ("XX" =~ /$re/) {print "/i matches\n";} else {print "/i no match\n";}
}

{
  my $re = qr/a.b/s;
  my $str = "a\nb";
  print "$re\n";
  if ($str =~ /a.b/s) { print "/s matches\n"; } else { print "/s no match\n";}
  if ($str =~ $re) {print "/s matches\n";} else {print "/s no match\n";}
  if ($str =~ /$re/) {print "/s matches\n";} else {print "/s no match\n";}
  if ($str =~ /$re/m) {print "/s matches\n";} else {print "/s no match\n";
  }
}

{
  my $str = "w\nx\ny";
  my $re = qr/^x$/m;
  print "$re\n";
  if ($str =~ /^x$/m) {print "/m matches\n";} else {print "/m no match\n";}
  if ($str =~ $re) {print "/m matches\n";} else {print "/m no match\n";}
  if ($str =~ /$re/) {print "/m matches\n";} else {print "/m no match\n";}
}

{
  my $str = "w\nx\ny";
  my $pat = '^x';
  my $re = qr/$pat/m;
  print "$re\n";
  if ($str =~ $re) {print "interp /m matches\n";} else {print "interp /m no match\n";}
  if ($str =~ /$re/) {print "interp /m matches\n";} else {print "interp /m no match\n";}
}

