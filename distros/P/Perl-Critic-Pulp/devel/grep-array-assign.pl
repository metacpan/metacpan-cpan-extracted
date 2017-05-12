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

my $verbose = 0;

my $hws = qr/\s*(#.*\n)*\s*/;

my $l = MyLocatePerl->new;
OUTER: while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  while (
         # = qw()
         # $str =~ /(=\s*qw$hws[([{])/og

         # plain word @array=[]
         $str =~ /(\@\w+\s*=\s*[[{])/sg

         # parens )=[ or )={
         #$str =~ /(\)\s*=\s*[[{])/sg

         # single element string like @ISA='Foo'
         # $str =~ /(\@\w+\s*=\s*[0-9'"])/sg
        ) {
    my $pos = pos($str)-length($1);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col:\n",
      MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;
