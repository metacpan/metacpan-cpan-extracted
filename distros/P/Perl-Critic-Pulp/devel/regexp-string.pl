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

use 5.010;
use strict;
use warnings;

{
  sub matchstr {
    my ($str) = @_;
    $str =~ 'something';
  }
  sub matchre {
    my ($str) = @_;
    $str =~ /something/;
  }
  require B::Concise;
  # B::Concise::compile('-exec',\&App::MathImage::NumSeq::Sequence::PrimeQuadraticHonaker::pred)->();
  B::Concise::compile('-exec',\&matchre) ->();

  B::Concise::compile('-exec',\&matchstr) ->();
  exit 0;
}
