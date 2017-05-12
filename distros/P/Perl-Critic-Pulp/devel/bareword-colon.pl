#!/usr/bin/perl -w

# Copyright 2010, 2012 Kevin Ryde

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

use 5.010;
use strict;
use warnings;

sub noop { }

{ package blah; sub x { print "method x runs\n" } }
{
  # sub x { print "function x runs\n" }
  x blah => noop();
  exit 0;
}

# { package main::foo; sub x {} }
# { package main::foo::bar; sub y {} }
# 
# {
#   $, = ' ';
#   # print %main::;
#   my $stash = \%main::;
#   # print keys %$stash;
#   print $stash->{foo::}//'undef',"\n";
# 
#   $stash = \%main::foo::;
#   print keys %$stash,"\n";
#   print $stash->{bar::}//'undef',"\n";
#   exit 0;
# }
# 
# sub make {
#   return "make: @_";
# }
# 
# {
#   package Math;
#   sub Complex { return "foo"; }
# }
# {
#   my $c = make Math::Complex 1, 2;
#   print $c,"\n";
# }
# require Math::Complex;
# {
#   my $c = make Math::Complex:: 3,4;
#   print $c,"\n";
# }
# 
# print $Math::{'Complex::'},"\n";
# print $Math::{Complex::},"\n";
# 
# {
#   package Foo::Bar::Quux;
#   sub blah { return "blah"; }
# }
# print $Foo::{'Bar::Quux::'}||'undef',"\n";
# print $Foo::Bar::{'Quux::'},"\n";
# print $Foo::Bar::{'Quux'}||'undef',"\n";
