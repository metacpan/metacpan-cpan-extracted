#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
use FindBin;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;

my $verbose = 0;

my $L_re = qr/L<+([^>]|E<[^>]*>)*?>/;

sub grep_see_also {
  my ($filename, $str) = @_;
  ### $str

  $str =~ /^=head1 SEE ALSO.*?(^=head1|\z)/smp or return;
  my $see_also_pos = $-[0];
  my $see_also_str = ${^MATCH};
  ### $see_also_str

  my %seen;
  while ($see_also_str =~ /($L_re)/og) {
    my $pos = pos($see_also_str);
    my $L = $1;
    if ($seen{$L}++) {
      my ($line, $col) = MyStuff::pos_to_line_and_column
        ($str, $see_also_pos+$pos-length($L));
      print "$filename:$line:$col: $L\n",
        MyStuff::line_at_pos($str, $pos);
    }
  }
}

if (1) {
  require File::Slurp;
  my $filename = "$FindBin::Bin/$FindBin::Script";
  my $str = Perl6::Slurp::slurp($filename);
  grep_see_also ($filename, $str);
#  exit 0;
}

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }
  grep_see_also ($filename, $str);
}

exit 0;

=head1 SEE ALSO

L<Foo>,
L<Foo>
