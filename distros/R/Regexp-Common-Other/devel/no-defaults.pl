#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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
# BEGIN { push @INC, '/usr/share/perl5'; }

use Regexp::Common 'Emacs','no_defaults';
# use Regexp::Common 'Emacs';
# use Regexp::Common 'RE_Emacs_autosave';

# uncomment this to run the ### lines
use Smart::Comments;


{
  my $crop = $RE{ws}{crop};
  print "crop is ",(defined $crop ? $crop : '[undef]'),"\n";
  exit 0;
}
