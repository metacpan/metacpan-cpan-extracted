#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2012 Kevin Ryde

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


# Usage: perl grep-arg-unpack.pl
#
# Look for "sub { my ($foo); ... }" missing the @_ in the unpack.
# Usually some variant unpacking or local vars.

use 5.006;
use strict;
use warnings;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {

  while ($str =~ /(
                    sub\s+\w*\s*{\s*
                    my\s*\([^)]+\)\s*;
                  )
                 /gx) {
    my $line = $1;
    my $pos = pos($str) - length($1);

    my ($linenum, $colnum) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$linenum:$colnum:\n",
      "$line\n";
  }
}

__END__

use foo .5;
use Foo::Bar _1000_;
{ no Foo::Bar v.1; }
