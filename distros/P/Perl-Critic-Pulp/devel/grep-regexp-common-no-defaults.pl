#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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


# Look for use Regexp::Common without 'no_defaults'
#

use 5.008;
use strict;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;

# an internal in Regexp::Common
my @defaults = qw(balanced
                  CC
                  comment
                  delimited
                  lingua
                  list
                  net
                  number
                  profanity
                  SEN
                  URI
                  whitespace
                  zip);
my $defaults_re = do {
  my $str = join('|',@defaults);
  qr/\b($str)\b/o;
};

my $verbose = 0;
my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  $str =~ s/#.*//g;  # no comments
  while ($str =~ /\buse\s*Regexp::Common\b(.*?);/sg) {
    my $args = $1;
    my $pos = $-[0];
    my $bad;
    if ($args =~ $defaults_re && $args =~ /\bno_defaults\b/) {
      $bad = 'default pattern specified, so no_defaults unnecessary';
    } elsif ($args !~ $defaults_re && $args !~ /\bno_defaults\b/) {
      $bad = 'no default pattern specified, should no_defaults';
    }
    if ($bad) {
      my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
      print "$filename:$line:$col: $bad\n",
        "  ",MyStuff::line_at_pos($str, $pos),
        "\n";
    }
  }
}

exit 0;
