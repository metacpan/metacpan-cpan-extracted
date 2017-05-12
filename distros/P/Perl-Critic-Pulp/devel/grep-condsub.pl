#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use Regexp::Common 'comment';

use lib::abs '.';
use MyLocatePerl;
use MyStuff;
use Text::Tabs ();

my $verbose = 0;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  if ($str =~ /^__END__/m) {
    substr ($str, $-[0], length($str), '');
  }

  # strip comments
  $str =~ s/$RE{comment}{Perl}//og;

  while ($str =~ /^([ \t])+(sub [[:alnum:]]|\b(BEGIN|END|CHECK|INIT)\b)/mg) {
    my $pos = pos($str);

    my ($indent) = Text::Tabs::expand ($1);
    $indent = length ($indent);

    my $before = substr ($str, 0, $pos);
    $indent--;
    $before =~ /^ {0,$indent}(if|unless)\b/m
      or next;
    my $before_pos = $-[0];

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);

    print "$filename:$line:$col:\n",
      MyStuff::line_at_pos($str, $before_pos),
          MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;
