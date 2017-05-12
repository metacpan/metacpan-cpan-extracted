#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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

use 5.005;
use strict;
use warnings;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant __FOO => 123;

my $verbose = 0;

my $l = MyLocatePerl->new;
OUTER: while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  if ($str =~ /^[^#]*\buse warnings/) {
    # 5.6 for use warnings anyway, presume that what the code is targeting
    next;
  }

  while ($str =~ /\buse (5[.0-9]*)/g) {
    ### $1
    my $perlver = eval { version->new($1) };
    ### $perlver
    if (defined $perlver && $perlver >= 5.006) {
      ### skip, high enough
      next OUTER;
    }
  }

  while ($str =~ /\buse
                  \s+
                  constant
                  \s+
                  ([0-9.]+\s+)?
                  _/sgx) {
    my $pos = pos($str)-1;

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col:\n",
      MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;


{
  use Readonly;
  Readonly::Scalar my $FOO => 123;
  my $ref = \$FOO;
  $$ref = 456;

  use constant XYZZY => 123;
   $ref = \(XYZZY);
  $$ref = 456;
  exit 0;
}
