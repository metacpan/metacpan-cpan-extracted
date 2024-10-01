#!/usr/bin/perl

#
# Copyright (C) 2019 Joelle Maslak
# All Rights Reserved - See License
#

use v5.22;
use strict;
use warnings;

# To call this application:
#
# perl PerlWeeklyChallenge-Week6-Problem1.pl <numbers>
#
# This was inspired by the Perl Weekly Challenge -
#   http://perlweeklychallenge.org/
#
# Numbers should be space seperated.  This will take the input numbers
# and "summarize" them.  From the challenge description:
#
#   Create a script that takes a list of numbers from the command line
#   and print the same in the compact form. For example, if you pass
#   "1,2,3,4,9,10,14,15,16" then it should print the compact form like
#   "1-4,9,10,14-16".
#
# I modified that a bit, so it would actually print with that input
# something like "1-4,9-10,14-16", which is just as compact. I also
# asked for input on the command line with spaces instead of commas
# seperating the numbers, but changing to support commas would be
# trivial.
#
# This uses my Range::Merge library to do this functionality.  This
# library was designed primarily for creating non-overlapping ranges
# from CIDR blocks (think routing tables on the internet), and has a
# fancy algorithm for that, but I figured I could add a simple algorithm
# for this problem!
#

use Range::Merge qw(merge_discrete);

my ($ranges) = merge_discrete( [@ARGV] );
say join( ",", map( { ( $_->[0] != $_->[1] ) ? join( '-', @$_ ) : $_->[0] } @$ranges ) );

