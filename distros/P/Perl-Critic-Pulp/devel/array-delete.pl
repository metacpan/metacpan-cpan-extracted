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

my $bool;
my @x;
print (exists($x[0]));
#print (exists($bool ? $x[0] : $x[1]));

# sub foo {};
# print(exists &foo, exists &bar);
# exit 0;

# my @x;
# delete $x[1];
# exit 0;


# use Perl::MinimumVersion;
# $object = Perl::MinimumVersion->new( \'delete $x[1];'  );
# print $object->minimum_version;

