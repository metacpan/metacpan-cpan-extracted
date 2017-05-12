#!/usr/bin/perl -w

# Copyright 2016 Kevin Ryde

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
}

my $self = MyParser->new;
# $self->parse_file('/usr/share/perl5/Lingua/Any/Numbers.pm');
$self->parse_file('/tmp/a.pl');

# $self->parse_string_document('
# 
# =pod
# 
# Blah blah =cut.
# 
# Xyzzy
# =cut
# 
# Blah
# 
# ');
