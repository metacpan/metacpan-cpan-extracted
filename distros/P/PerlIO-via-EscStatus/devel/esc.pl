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


use strict;
use warnings;
use Encode;
use Regexp::Common 'ANSIescape';

use Data::Dumper;
$Data::Dumper::Useqq = 1;

print "\e_hello\e\\world\n";

# print the regexp, to show how diabolical it looks
my $re = $RE{ANSIescape}{-keep};
print "\n",Dumper(\"$re");
$re = $RE{ANSIescape}{-only7bit}{-keep};
print "\n",Dumper(\"$re");

my $str = "\x{9B}";
utf8::upgrade($str);
print "\n",Dumper(\$str);
my $utf8 = Encode::encode('utf-8',$str);
for my $i (0 .. length($utf8)-1) { printf "%02X ", ord(substr($utf8,$i)); }
print "\n";

$str = "\x{19B}";
utf8::upgrade($str);
print "\n",Dumper(\$str);
$utf8 = Encode::encode('utf-8',$str);
for my $i (0 .. length($utf8)-1) { printf "%02X ", ord(substr($utf8,$i)); }
print "\n";

print $utf8,"\n";

print "\x{9B}43myellow back\x{9B}0m\n";
