#! /usr/bin/perl
#
# Sample dictionary configuration for Net::Radius::Server
#
# Copyright © 2006, Luis E. Muñoz
#
# This file defines a dictionary provider method that returns a simple
# dictionary.
#
# $Id: def-dictionary.pl 74 2007-04-21 17:13:14Z lem $

use strict;
use warnings;

use Net::Radius::Dictionary;

# For performance, we will use a closure to return the same (parsed)
# dictionary on each call. Parsing a dictionary for each request is ok
# for very low rate or requests.

my @dicts = qw( dictionary );

my $d = Net::Radius::Dictionary->new(@dicts);

sub { $d || die "Unable to parse dictionaries (", join(',', @dicts), ")\n" };

