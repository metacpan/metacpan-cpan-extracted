#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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


# Usage: perl grep-duplicate-END.pl
#
# Search for duplicated __END__ tokens.


use 5.010;
use strict;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;


my $verbose = 0;
my $l = MyLocatePerl->new;
my $count;
{
  while (my ($filename, $content) = $l->next) {
    file ($filename, $content);
  }
  exit 0;
}

sub file {
  my ($filename, $str) = @_;

  if ($verbose) {
    print "$filename\n";
  }

  next if $str =~ /^use AutoLoader/;

  my @pos;
  while ($str =~ /^(__END__)/mg) {
    push @pos, pos($str) - length($1);
  }
  if (@pos > 1) {
    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos[1]);
    print "$filename:$line:$col: duplicate END\n";
  }
}

exit 0;

__END__

__END__
