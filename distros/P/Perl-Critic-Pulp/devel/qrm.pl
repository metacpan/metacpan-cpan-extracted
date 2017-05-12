#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

use 5.005;
$str = "w\nx\ny";
$re = qr/^x$/m;
print "$re\n";
if ($str =~ /^x$/m) {print "matches\n";} else {print "no match\n";}
if ($str =~ $re)    {print "matches\n";} else {print "no match\n";}
exit 0;
