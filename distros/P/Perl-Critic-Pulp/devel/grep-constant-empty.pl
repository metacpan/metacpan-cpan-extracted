#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

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


# Look for
#     use constant foo => ();
#     use constant foo;


# cf t/pragma/constant.
#    use constant UNDEF2	=>	;	# the weird way
#    use constant 'UNDEF3'		;	# the 'short' way

use 5.005;
use strict;
use warnings;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant FOO => ();
use constant BAR => ;
use constant 'ABC';

my $verbose = 0;

my $l = MyLocatePerl->new;
my %seen;
OUTER: while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  while ($str =~ /(
                    \buse
                    \s+
                    constant
                    \s+
                    ([0-9.]+\s+)?
                    \w+
                    \s*
                    =>
                    (
                      \s*
                      \(\s*\)
                    |
                      \s*;
                    )
                  )
                 /sgx) {
    my $pos = pos($str)-1;
    my $whole = $1;
    next if $seen{$whole}++;

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col:\n",
      MyStuff::line_at_pos($str, $pos);
  }

  while ($str =~ /(
                    \buse
                    \s+
                    constant
                    \s+
                    ('|"|qw)
                  )
                 /sgx) {
    my $pos = pos($str)-1;
    my $whole = $1;
    next if $seen{$whole}++;

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col:\n",
      MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;
