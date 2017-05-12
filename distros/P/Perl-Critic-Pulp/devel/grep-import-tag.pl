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
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  while ($str =~ /\n[ \t\r\n]*use
                  [ \t\r\n]+
                  ([^ \t\r\n;]+)
                  [ \t\r\n]+
                  (qw[ \t\r\n]*+.[ \t\r\n]*+|['"])
                  ([^:!])
                  [^;]*
                  ['" \t\r\n][:!]
                 /sgx) {
    my $module = $1;
    my $non = $3;
    my $pos = $-[0] + 1;

    next if ($module eq 'base');
    next if ($module eq 'overload');
    next if ($module eq 'overload(');
    next if ($module eq 'lib');
    next if ($module eq 'inc::latest');
    next if ($module eq "'inc::latest'");
    next if ($module eq 'Carp::Clan');
    next if ($module eq 'Glib::Object::Subclass');
    next if ($module eq 'Test::Without::Module');
    next if ($module eq 'Sort::Key::Register');
    next if ($module eq 'POE');
    next if ($module eq 'constant');
    next if ($module eq 'constant::defer');
    next if ($module eq 'Memoize::ToConstant');
    next if ($module eq 'Prima');
    next if ($module eq 'Tk::Reindex');

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: $module non colon \"$non\"\n",
      MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;
