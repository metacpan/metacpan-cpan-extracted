#!/usr/bin/perl -w

# Copyright 2011, 2014 Kevin Ryde

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
use Scalar::Util;

# use blib "$ENV{HOME}/perl/scalar-list-utils/Scalar-List-Utils-1.23";

{
  my $u = 'x';
  utf8::upgrade($u);
  my $e = Scalar::Util::dualvar(0,$u);
  print $e
}
