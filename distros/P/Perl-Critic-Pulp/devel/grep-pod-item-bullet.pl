#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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


# various
# some DB<1> debugger prompts

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
use Smart::Comments;

my $verbose = 0;

{
  package MyParser;
  use base 'Pod::Simple';
  sub _handle_element_start {
    my ($self, $element, $attrs) = @_;
    ### $element
    ### $attrs
  }
  sub _handle_text {
    my ($self, $text) = @_;
    ### $text
  }
  my $self = MyParser->new;
  $self->parse_string_document("
=over

=item *

Foo

=back
");

#  exit 0;
}

my $l = MyLocatePerl->new (include_pod => 1);
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  while ($str =~ /^(=item[ \t]+\*[ \t]+.)/mg) {
    my $whole = $1;
    my $pos = pos($str) - length($whole);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    my $line_str = MyStuff::line_at_pos($str, $pos);

    print "$filename:$line:$col:\n  $line_str";
  }
}

exit 0;

=over

=item * Bullet

=back
