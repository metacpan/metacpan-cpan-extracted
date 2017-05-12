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
   while(($fsname,$path,$fstyp) = Quota::getmntent())
   {
      print "#$fsname#$path#$fstyp#\n";
   }
}
Quota::endmntent();

