#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;


{
  my $char = '}';
  $char = quotemeta $char;
  my $search = qr/^(.*?(?<!\\)(?:\\\\)*$char)/;

  # 'qq{' .
  my $str = '\\' . chr(0x16A) . '}';
  if ($str =~ /$search/) {
    print "match: $1\n";
  } else {
    print "no match\n";
  }
  exit 0;
}

{
  require PPI::Document;
  my $str = 'qq{\\' . chr(0x16A) . '}';
  my $doc = PPI::Document->new (\$str);
  print ref($doc),"\n";
  exit 0;
}
