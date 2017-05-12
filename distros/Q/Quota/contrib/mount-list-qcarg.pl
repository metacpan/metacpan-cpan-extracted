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
use Quota;

my($fsname,$path,$fstyp);

if(!Quota::setmntent()) {
   while(($fsname,$path,$fstyp,$opt) = Quota::getmntent())
   {
      push(@Mtab, "#$fsname#$path#$fstyp#$opt#");
   }
}
Quota::endmntent();

print "Quota arg type=". Quota::getqcargtype() ."\n\n";

foreach (@Mtab)
{
   $path = (split(/#/))[2];
   $qcarg = Quota::getqcarg($path);
   $qcarg = "*UNDEF*" unless defined $qcarg;
   $dev = (stat($path))[0];
   print "${_}$qcarg#$dev\n";
}
