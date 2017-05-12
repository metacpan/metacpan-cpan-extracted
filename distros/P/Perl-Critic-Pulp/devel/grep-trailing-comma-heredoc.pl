#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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

# cf


use 5.005;
use strict;
use warnings;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
# use Smart::Comments;

my $verbose = 0;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  # if ($str =~ /^__END__/m) {
  #   substr ($str, $-[0], length($str), '');
  # }

  # strip comments
  $str =~ s/#.*//mg;

  while ($str =~ /<<[ \t]*(
                     '([A-Za-z_]\w*)'
                    |"([A-Za-z_]\w*)"
                    |([A-Za-z_]\w*)
                    )[ \t]*\n/sgx) {
    my $whole = $&;
    my $key = $1 // $2 // $3;
    my $pos_end = pos($str);
    my $pos = $pos_end - length($whole) + 1;

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    my $l1 = MyStuff::line_at_pos($str, $pos);

    my $oldpos = pos($str);
    $str =~ /^$key[ \t]*$/mg;
    my $pos2 = pos($str);
    pos($str) = $oldpos;
    $pos2 // next;
    my $l2 = MyStuff::line_at_pos($str, $pos2+1);
    next unless $l2 =~ /^[ \t]*\)/;

    print "$filename:$line:$col:\n  $l1  $l2";
  }
}

exit 0;

__END__

print <<HERE
123
HERE
  ;

foo( <<HERE
123
HERE
   );

print <<HERE;
123
HERE
