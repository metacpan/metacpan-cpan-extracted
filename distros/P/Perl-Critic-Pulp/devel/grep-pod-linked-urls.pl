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

use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new (include_pod => 1);
my $p = MyParser->new;
my $wantver = version->new('5.008');
my $count = 0;
my $filename;
while (($filename, my $str) = $l->next) {

  my $code = $str;
  $code =~ s/^__END__.*//m;
  my $goodver = 0;
  while ($code =~ /^[^#]*\buse\s+(\d[0-9.]*)/mg) {
    my $gotver = version->new ($1);
    if ($gotver >= $wantver) {
      $goodver = 1;
      last;
    }
  }
  $goodver or next;

  if ($verbose) { print "parse $filename\n"; }
  $p->parse_from_string ($str, $filename);
}
print "total $count\n";

exit 0;

package MyParser;
use base 'Perl::Critic::Pulp::PodParser';
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;

  while ($text =~ m{(?<!L<)\b(https?|ftp)://}g) {
    my $pos = $-[1];
    my ($line_offset, $col) = MyStuff::pos_to_line_and_column ($text, $pos);
    $linenum += $line_offset - 1;

    print "$filename:$linenum:$col: not L<> linked url\n",
      MyStuff::line_at_pos($text, $pos);
    $count++;
  }
}
