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

use lib::abs '.', 'lib';
use MyLocatePerl;
use MyStuff;
use Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens;

# uncomment this to run the ### lines
#use Smart::Comments;

my $verbose = 0;

{
  package MyParser;
  use base 'Perl::Critic::Pulp::PodParser::ProhibitUnbalancedParens';
  sub violation_at_linenum_and_textpos {
    my ($self, $message, $linenum, $str, $pos) = @_;
    my $filename = $self->{'filename'};
    my ($pos_linenum, $column) = MyStuff::pos_to_line_and_column($str,$pos);
    $linenum += $pos_linenum - 1;
    print "$filename:$linenum:$column: $message\n";
  }
}
my $parser = MyParser->new;

my $l = MyLocatePerl->new (exclude_t => 1);
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  $parser->{'filename'} = $filename;
  $parser->parse_from_file ($filename);
}

exit 0;
