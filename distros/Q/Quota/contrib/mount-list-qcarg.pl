#!/usr/bin/perl
#
# Author: Tom Zoerner
#
# This program (mount-list-qcarg.pl) is in the public domain and can
# be used and redistributed without restrictions.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

use blib;
use warnings;
use strict;
use Quota;

# Note the reason for having a separate loop for getmntent() and the
# following loop using getgcarg() is that the latter internally also
# iterates using getmntent(), but mount table iterations cannot be
# nested due to using global state internally.

my @Mtab;
if(!Quota::setmntent()) {
  while(my @ent = Quota::getmntent())
  {
    push @Mtab, \@ent;
  }
}
Quota::endmntent();

print "OS: ". `uname -rs` ."\n";
print "Quota arg type: ". Quota::getqcargtype() ."\n\n";

foreach my $ent (@Mtab)
{
  my ($fsname,$path,$fstyp,$fsopt) = @$ent;

  my $qcarg = Quota::getqcarg($path);
  $qcarg = "*UNDEF*" unless defined $qcarg;
  my $dev = (stat($path))[0];

  print "#$fsname#$path#$fstyp#$fsopt#$qcarg#$dev\n";
}
